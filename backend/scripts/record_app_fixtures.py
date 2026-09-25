"""Records real API answers for the sample project, for the Flutter tests.

The app's widget tests replay these answers instead of hand-written JSON, so every
screen is exercised with exactly what this backend sends (no AI, fixed date).
Run from ``backend/`` after changing a response shape::

    uv run python scripts/record_app_fixtures.py

It writes ``app/test/fixtures/sample_id.json`` and ``sample_en.json``.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from datetime import date
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[1]
OUT_DIR = BACKEND_DIR.parent / "app" / "test" / "fixtures"
TODAY = date(2026, 10, 5)  # the same Monday as the backend tests


def record(locale: str, work_dir: Path) -> dict:
    os.environ["PURNARA_DATABASE_URL"] = f"sqlite:///{(work_dir / f'{locale}.db').as_posix()}"
    os.environ["PURNARA_STORAGE_DIR"] = str(work_dir / f"files-{locale}")
    os.environ["PURNARA_ENVIRONMENT"] = "test"
    os.environ.pop("ANTHROPIC_API_KEY", None)

    from fastapi.testclient import TestClient

    import app.modules.ai.gateway as gateway_module
    from app.core.clock import FixedClock, get_clock
    from app.core.config import get_settings
    from app.core.db import reset_engine
    from app.main import create_app

    get_settings.cache_clear()
    reset_engine()
    gateway_module._gateway = None
    app = create_app()
    app.dependency_overrides[get_clock] = lambda: FixedClock(TODAY)

    answers: dict[str, object] = {}
    with TestClient(app) as client:

        def call(method: str, path: str, body: dict | None = None, query: str = "") -> object:
            response = client.request(method, f"/v1{path}{query}", json=body)
            assert response.status_code < 400, (method, path, response.status_code, response.text)
            data = response.json() if response.content else None
            answers[f"{method} {path}{query}"] = data
            return data

        client.patch("/v1/me", json={"locale": locale})
        project = call("POST", "/projects/sample", {"locale": locale})
        pid = project["id"]
        # One exchange with the assistant, so the chat screen has a conversation to show.
        question = "Apa syarat jumlah referensi?" if locale == "id" else "How many references are required?"
        call("POST", f"/projects/{pid}/chat", {"question": question})

        for path in ("/health", "/me", "/me/today", "/notifications", "/modes", "/projects"):
            call("GET", path)
        for part in ("brief", "requirements", "plan", "health", "weekly-review", "suggestions", "documents", "threads"):
            call("GET", f"/projects/{pid}/{part}")
        call("GET", f"/projects/{pid}/notes", query="?kind=supervision")
        for suggestion in answers[f"GET /projects/{pid}/suggestions"]:
            call("GET", f"/suggestions/{suggestion['id']}")
        for thread in answers[f"GET /projects/{pid}/threads"]:
            call("GET", f"/threads/{thread['id']}/messages")
        plan = answers[f"GET /projects/{pid}/plan"]
        for task in plan["tasks"]:
            call("GET", f"/tasks/{task['id']}")
        # Last: these create suggestions of their own.
        call("POST", f"/tasks/{plan['tasks'][1]['id']}/start-help")
        call("POST", f"/projects/{pid}/replan")

        # The setup wizard for a new project, step by step, without documents.
        title = "Sistem rekomendasi skripsi" if locale == "id" else "Thesis recommender system"
        wizard = call(
            "POST",
            "/projects",
            {"template": "skripsi", "title": title, "description": "", "target": "", "deadline": "2027-03-01", "hours_by_weekday": [2, 2, 2, 2, 2, 0, 0]},
        )
        wid = wizard["id"]
        call("GET", f"/projects/{wid}/documents")
        call("GET", f"/projects/{wid}/brief")
        draft = call("POST", f"/projects/{wid}/brief/extract")
        call("PUT", f"/projects/{wid}/brief", {"content": draft["content"], "source": "user"})
        call("PATCH", f"/projects/{wid}", {"hours_by_weekday": [2, 2, 2, 2, 2, 0, 0], "blocked_dates": [], "buffer_pct": 0.15})
        generated = call("POST", f"/projects/{wid}/plan/generate")
        call("GET", f"/suggestions/{generated['id']}")
        call("POST", f"/suggestions/{generated['id']}/apply", {"op_indices": None})

    reset_engine()
    get_settings.cache_clear()
    # Addresses of this computer do not belong in the repository.
    answers["GET /health"] = {**answers["GET /health"], "lan_urls": ["http://192.168.1.20:8000"], "lan_listening": True, "web_app": True}
    return {"today": TODAY.isoformat(), "locale": locale, "project_id": pid, "wizard_project_id": wid, "answers": answers}


def main() -> None:
    sys.path.insert(0, str(BACKEND_DIR))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        for locale in ("id", "en"):
            fixture = record(locale, Path(work))
            path = OUT_DIR / f"sample_{locale}.json"
            path.write_text(json.dumps(fixture, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")
            print(f"{path.relative_to(BACKEND_DIR.parent)}: {len(fixture['answers'])} answers")


if __name__ == "__main__":
    main()
