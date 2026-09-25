"""Application settings, read from the environment (and ``backend/.env`` if present)."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]
REPO_DIR = BACKEND_DIR.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=BACKEND_DIR / ".env", env_prefix="PURNARA_", extra="ignore")

    environment: Literal["local", "staging", "production", "test"] = "local"
    # SQLite for local development; PostgreSQL (Supabase) in staging and production.
    database_url: str = f"sqlite:///{(BACKEND_DIR / 'data' / 'purnara.db').as_posix()}"
    storage_dir: Path = BACKEND_DIR / "data" / "files"
    modes_dir: Path = REPO_DIR / "modes"
    # The built Flutter web app (`flutter build web` in app/). When present, the API
    # serves it too, so one process on port 8000 is the whole product.
    web_dir: Path = REPO_DIR / "app" / "build" / "web"
    run_migrations_on_start: bool = True

    # "local": a single local user, no login (development without any paid service).
    # "supabase": verify Supabase JWTs on every request.
    auth_mode: Literal["local", "supabase"] = "local"
    supabase_jwt_secret: str | None = None
    supabase_jwks_url: str | None = None
    supabase_jwt_audience: str = "authenticated"

    cors_origins: list[str] = Field(
        default_factory=lambda: [
            "http://localhost:5000",
            "http://127.0.0.1:5000",
            "http://localhost:8080",
            "http://127.0.0.1:8080",
        ]
    )
    # Flutter web debug runs on a random localhost port; allow any localhost origin locally.
    cors_origin_regex: str | None = r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"

    # AI. The key lives only on the server; without it every AI feature falls back to a
    # deterministic, clearly labelled non-AI version.
    anthropic_api_key: str | None = Field(default=None, validation_alias="ANTHROPIC_API_KEY")
    ai_model_strong: str = "claude-sonnet-5"
    ai_model_light: str = "claude-haiku-4-5"
    ai_timeout_seconds: float = 60.0
    # Monthly AI budget per user, in tokens (input + output).
    ai_monthly_token_quota: int = 400_000

    # Document limits (master plan §9).
    max_upload_mb: int = 20
    max_pages: int = 300

    @property
    def ai_enabled(self) -> bool:
        return bool(self.anthropic_api_key)

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")


@lru_cache
def get_settings() -> Settings:
    return Settings()
