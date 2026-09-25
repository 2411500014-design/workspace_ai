"""Model Gateway (master plan §7): one entry point for every AI call.

- A routing table maps each task type to a model tier and token limit.
- The monthly quota is checked before the call; usage and estimated cost are recorded
  in ``usage_ledger`` after it.
- Retries: the SDK retries 429/5xx/connection errors with exponential backoff.
- The API key only ever lives on the server. Without it, :attr:`Gateway.enabled` is
  false and callers use their non-AI fallback.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from datetime import UTC, datetime
from enum import StrEnum
from typing import Any, Literal

import anthropic
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import AppError
from app.modules.accounts.models import Profile

from .models import UsageLedger

PROMPT_VERSION = "v1"


class TaskType(StrEnum):
    BRIEF = "brief_extract"
    CLASSIFY = "doc_classify"
    SUMMARY = "doc_summary"
    PLAN = "plan_generate"
    CHAT = "chat"
    TASK_HELPER = "task_helper"
    SUPERVISION = "supervision_log"
    REPLAN = "replan_explain"
    WEEKLY = "weekly_review"


@dataclass(frozen=True)
class Route:
    tier: Literal["strong", "light"]
    max_tokens: int
    effort: str | None = None


# Light tier: Claude Haiku 4.5; strong tier: Claude Sonnet 5 (master plan §7). The final
# choice per workflow is made from evals (§14).
ROUTES: dict[TaskType, Route] = {
    TaskType.BRIEF: Route("strong", 8000),
    TaskType.PLAN: Route("strong", 16000),
    TaskType.CHAT: Route("strong", 4000, effort="medium"),
    TaskType.SUPERVISION: Route("strong", 4000),
    TaskType.REPLAN: Route("strong", 3000, effort="medium"),
    TaskType.TASK_HELPER: Route("light", 2000),
    TaskType.WEEKLY: Route("light", 1500),
    TaskType.CLASSIFY: Route("light", 800),
    TaskType.SUMMARY: Route("light", 1500),
}

# USD per million tokens (input, output), first-party API rates.
PRICES = {"claude-sonnet-5": (2.0, 10.0), "claude-haiku-4-5": (1.0, 5.0)}


class AIUnavailable(AppError):
    def __init__(self) -> None:
        super().__init__("ai_unavailable", 503)


@dataclass
class AIResult:
    text: str
    parsed: Any
    content: list = field(default_factory=list)
    model: str = ""
    input_tokens: int = 0
    output_tokens: int = 0
    stop_reason: str | None = None


def _month_start(now: datetime) -> datetime:
    return datetime(now.year, now.month, 1, tzinfo=UTC)


def _next_month(now: datetime) -> datetime:
    return datetime(now.year + (now.month == 12), now.month % 12 + 1, 1, tzinfo=UTC)


class Gateway:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()
        self._client: anthropic.Anthropic | None = None

    @property
    def enabled(self) -> bool:
        return self.settings.ai_enabled

    @property
    def client(self) -> anthropic.Anthropic:
        if self._client is None:
            self._client = anthropic.Anthropic(
                api_key=self.settings.anthropic_api_key,
                timeout=self.settings.ai_timeout_seconds,
                max_retries=2,
            )
        return self._client

    def model_for(self, task_type: TaskType) -> str:
        route = ROUTES[task_type]
        return self.settings.ai_model_strong if route.tier == "strong" else self.settings.ai_model_light

    # --- quota -------------------------------------------------------------------------

    def quota(self, db: Session, user: Profile) -> dict:
        now = datetime.now(UTC)
        used = db.scalar(
            select(func.coalesce(func.sum(UsageLedger.input_tokens + UsageLedger.output_tokens), 0)).where(
                UsageLedger.user_id == user.id, UsageLedger.created_at >= _month_start(now)
            )
        )
        return {
            "used": int(used or 0),
            "limit": self.settings.ai_monthly_token_quota,
            "resets_at": _next_month(now).date().isoformat(),
        }

    def check_quota(self, db: Session, user: Profile) -> None:
        status = self.quota(db, user)
        if status["used"] >= status["limit"]:
            raise AppError("ai_quota_exhausted", 429, {"resets_at": status["resets_at"]})

    # --- calls -------------------------------------------------------------------------

    def run(
        self,
        db: Session,
        *,
        user: Profile,
        project_id: str | None,
        task_type: TaskType,
        system: list[dict],
        messages: list[dict],
        output_format: type[BaseModel] | None = None,
    ) -> AIResult:
        if not self.enabled:
            raise AIUnavailable()
        self.check_quota(db, user)
        route = ROUTES[task_type]
        model = self.model_for(task_type)
        kwargs: dict[str, Any] = {"model": model, "max_tokens": route.max_tokens, "system": system, "messages": messages}
        if route.effort and route.tier == "strong" and output_format is None:
            kwargs["output_config"] = {"effort": route.effort}

        started = time.monotonic()
        try:
            if output_format is not None:
                response = self.client.messages.parse(**kwargs, output_format=output_format)
            else:
                response = self.client.messages.create(**kwargs)
        except (anthropic.AuthenticationError, anthropic.PermissionDeniedError) as exc:
            raise AppError("ai_misconfigured", 503) from exc
        except anthropic.RateLimitError as exc:
            raise AppError("ai_rate_limited", 503) from exc
        except anthropic.BadRequestError as exc:
            raise AppError("ai_bad_request", 502) from exc
        except anthropic.APIStatusError as exc:
            raise AppError("ai_upstream_error", 502, {"status": exc.status_code}) from exc
        except anthropic.APIConnectionError as exc:  # includes timeouts
            raise AppError("ai_unreachable", 503) from exc
        latency_ms = int((time.monotonic() - started) * 1000)

        usage = response.usage
        self._record(db, user, project_id, task_type, model, usage, latency_ms)
        if response.stop_reason == "refusal":
            raise AppError("ai_refused", 422)
        text = "".join(block.text for block in response.content if block.type == "text")
        return AIResult(
            text=text,
            parsed=getattr(response, "parsed_output", None) if output_format is not None else None,
            content=list(response.content),
            model=model,
            input_tokens=usage.input_tokens,
            output_tokens=usage.output_tokens,
            stop_reason=response.stop_reason,
        )

    def _record(self, db, user, project_id, task_type, model, usage, latency_ms) -> None:
        cache_read = getattr(usage, "cache_read_input_tokens", 0) or 0
        cache_write = getattr(usage, "cache_creation_input_tokens", 0) or 0
        price_in, price_out = PRICES.get(model, (0.0, 0.0))
        cost = (
            usage.input_tokens * price_in
            + cache_read * price_in * 0.1
            + cache_write * price_in * 1.25
            + usage.output_tokens * price_out
        ) / 1_000_000
        db.add(
            UsageLedger(
                user_id=user.id,
                project_id=project_id,
                task_type=str(task_type),
                model=model,
                input_tokens=usage.input_tokens,
                output_tokens=usage.output_tokens,
                cache_read_tokens=cache_read,
                cache_write_tokens=cache_write,
                latency_ms=latency_ms,
                cost_usd=round(cost, 6),
            )
        )
        db.flush()


_gateway: Gateway | None = None


def get_gateway() -> Gateway:
    global _gateway
    if _gateway is None:
        _gateway = Gateway()
    return _gateway
