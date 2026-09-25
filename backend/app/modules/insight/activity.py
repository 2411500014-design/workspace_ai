from __future__ import annotations

from sqlalchemy.orm import Session

from .models import ActivityEvent


def log_event(db: Session, project_id: str, actor: str, type_: str, payload: dict | None = None) -> None:
    db.add(ActivityEvent(project_id=project_id, actor=actor, type=type_, payload=payload or {}))
