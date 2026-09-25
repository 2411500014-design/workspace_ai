"""Purnara API: FastAPI modular monolith (master plan §10).

Run locally from ``backend/``::

    uv run uvicorn app.main:app --reload
"""

from __future__ import annotations

from contextlib import asynccontextmanager

from alembic import command
from alembic.config import Config
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1 import me, projects, tasks
from app.core.config import BACKEND_DIR, get_settings
from app.core.errors import install_error_handlers
from app.modules.modes.loader import load_modes

VERSION = "0.1.0"


class WebFiles(StaticFiles):
    """The built web app. Browsers revalidate every file, so a new build shows on reload."""

    async def get_response(self, path, scope):
        response = await super().get_response(path, scope)
        response.headers.setdefault("Cache-Control", "no-cache")
        return response


def run_migrations(database_url: str) -> None:
    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("script_location", str(BACKEND_DIR / "migrations"))
    config.set_main_option("sqlalchemy.url", database_url)
    config.attributes["configure_logger"] = False
    command.upgrade(config, "head")


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    if settings.run_migrations_on_start:
        run_migrations(settings.database_url)
    load_modes()  # fail fast on a broken mode preset
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="Purnara API", version=VERSION, lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_origin_regex=settings.cors_origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    install_error_handlers(app)
    for module in (me, projects, tasks):
        app.include_router(module.router, prefix="/v1")

    @app.get("/v1/health", tags=["system"])
    def health() -> dict:
        return {
            "status": "ok",
            "version": VERSION,
            "ai_enabled": settings.ai_enabled,
            "auth_mode": settings.auth_mode,
            "environment": settings.environment,
        }

    # Mounted last so it never shadows an API route.
    if (settings.web_dir / "index.html").is_file():
        app.mount("/", WebFiles(directory=settings.web_dir, html=True), name="web")

    return app


app = create_app()
