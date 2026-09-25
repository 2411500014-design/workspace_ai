from __future__ import annotations

from datetime import date
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

import app.modules.ai.gateway as gateway_module
from app.api.deps import get_ai_gateway
from app.core.clock import FixedClock, get_clock
from app.core.config import Settings, get_settings
from app.core.db import reset_engine
from app.modules.ai.gateway import AIResult, Gateway, TaskType

TODAY = date(2026, 10, 5)  # a Monday


class FakeGateway(Gateway):
    """Stands in for Claude: returns queued results per task type and records usage."""

    def __init__(self) -> None:
        super().__init__(Settings(anthropic_api_key="test-key", ai_monthly_token_quota=400_000))
        self.queue: dict[TaskType, list] = {}
        self.calls: list[dict] = []

    def queue_result(self, task_type: TaskType, *, parsed=None, text: str = "", content=None, error=None) -> None:
        item = error or AIResult(
            text=text,
            parsed=parsed,
            content=content if content is not None else [SimpleNamespace(type="text", text=text, citations=None)],
            model=self.model_for(task_type),
            input_tokens=1000,
            output_tokens=200,
        )
        self.queue.setdefault(task_type, []).append(item)

    @property
    def enabled(self) -> bool:
        return True

    def run(self, db, *, user, project_id, task_type, system, messages, output_format=None):
        self.check_quota(db, user)
        self.calls.append({"task_type": task_type, "system": system, "messages": messages, "output_format": output_format})
        pending = self.queue.get(task_type) or []
        if not pending:
            raise AssertionError(f"unexpected AI call: {task_type}")
        item = pending.pop(0)
        if isinstance(item, Exception):
            raise item
        usage = SimpleNamespace(input_tokens=item.input_tokens, output_tokens=item.output_tokens)
        self._record(db, user, project_id, task_type, item.model, usage, 5)
        return item


@pytest.fixture
def make_client(tmp_path, monkeypatch):
    clients = []

    def factory(gateway: Gateway | None = None, env: dict | None = None) -> TestClient:
        monkeypatch.setenv("PURNARA_DATABASE_URL", f"sqlite:///{(tmp_path / 'test.db').as_posix()}")
        monkeypatch.setenv("PURNARA_STORAGE_DIR", str(tmp_path / "files"))
        monkeypatch.setenv("PURNARA_ENVIRONMENT", "test")
        monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
        for key, value in (env or {}).items():
            monkeypatch.setenv(key, value)
        get_settings.cache_clear()
        reset_engine()
        gateway_module._gateway = None
        from app.main import create_app

        app = create_app()
        clock = FixedClock(TODAY)
        app.dependency_overrides[get_clock] = lambda: clock
        if gateway is not None:
            app.dependency_overrides[get_ai_gateway] = lambda: gateway
        client = TestClient(app)
        client.__enter__()
        client.clock = clock  # type: ignore[attr-defined]
        clients.append(client)
        return client

    yield factory
    for client in clients:
        client.__exit__(None, None, None)
    reset_engine()
    get_settings.cache_clear()


@pytest.fixture
def client(make_client) -> TestClient:
    return make_client()


def new_project(client: TestClient, **overrides) -> dict:
    body = {
        "template": "skripsi",
        "title": "Decision-making NPC untuk game RTS",
        "description": "Merancang dan menguji model decision-making NPC pada game RTS sederhana.",
        "deadline": "2027-03-01",
        "hours_by_weekday": [2, 2, 2, 2, 2, 3, 0],
    }
    body.update(overrides)
    response = client.post("/v1/projects", json=body)
    assert response.status_code == 201, response.text
    return response.json()
