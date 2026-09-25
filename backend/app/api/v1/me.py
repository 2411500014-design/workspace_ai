"""The current user: profile, today's focus, notifications, data export, account deletion."""

from __future__ import annotations

from datetime import date
from pathlib import Path

from fastapi import APIRouter, Depends
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.api import serializers as ser
from app.api.deps import CurrentUser, Db, get_ai_gateway, get_today
from app.core.config import get_settings
from app.core.db import utcnow
from app.core.errors import NotFound
from app.modules.accounts.models import Profile, Workspace
from app.modules.ai.gateway import Gateway
from app.modules.ai.models import AiMessage, AiSuggestion, AiThread
from app.modules.documents.models import Document
from app.modules.insight.models import ActivityEvent, Notification
from app.modules.insight.service import notifications, today_view
from app.modules.projects.models import Note, Project, ProjectBrief, ProjectMemory, Requirement
from app.modules.projects.service import list_projects
from app.modules.tasks.models import Milestone, Task, TaskDependency

from .schemas import MeUpdate

router = APIRouter(tags=["me"])


@router.get("/me")
def get_me(db: Session = Db, user: Profile = CurrentUser, gateway: Gateway = Depends(get_ai_gateway)) -> dict:
    return ser.profile(user, gateway.enabled, gateway.quota(db, user), get_settings().auth_mode)


@router.patch("/me")
def update_me(body: MeUpdate, db: Session = Db, user: Profile = CurrentUser, gateway: Gateway = Depends(get_ai_gateway)) -> dict:
    for name, value in body.model_dump(exclude_none=True).items():
        setattr(user, name, value.strip() if isinstance(value, str) and name == "name" else value)
    db.flush()
    return ser.profile(user, gateway.enabled, gateway.quota(db, user), get_settings().auth_mode)


@router.get("/me/today")
def get_today_view(db: Session = Db, user: Profile = CurrentUser, today: date = Depends(get_today)) -> dict:
    return today_view(db, user, list_projects(db, user), today)


@router.get("/notifications")
def list_notifications(db: Session = Db, user: Profile = CurrentUser) -> list[dict]:
    return [ser.notification(n) for n in notifications(db, user)]


@router.post("/notifications/{notification_id}/read")
def read_notification(notification_id: str, db: Session = Db, user: Profile = CurrentUser) -> dict:
    item = db.get(Notification, notification_id)
    if item is None or item.user_id != user.id:
        raise NotFound("notification")
    item.read_at = item.read_at or utcnow()
    return ser.notification(item)


@router.get("/me/export")
def export_data(db: Session = Db, user: Profile = CurrentUser) -> dict:
    """Everything stored about the user, as JSON (UU PDP data subject rights)."""
    projects = list_projects(db, user)
    ids = [p.id for p in projects]

    def rows(model, *where):
        return [
            {c.key: _plain(getattr(r, c.key)) for c in model.__mapper__.column_attrs}
            for r in db.scalars(select(model).where(*where))
        ]

    task_ids = list(db.scalars(select(Task.id).where(Task.project_id.in_(ids))))
    thread_ids = list(db.scalars(select(AiThread.id).where(AiThread.project_id.in_(ids))))
    return {
        "exported_at": utcnow().isoformat(),
        "profile": {"id": user.id, "name": user.name, "email": user.email, "locale": user.locale, "timezone": user.timezone},
        "projects": [ser.project(p) for p in projects],
        "briefs": rows(ProjectBrief, ProjectBrief.project_id.in_(ids)),
        "requirements": rows(Requirement, Requirement.project_id.in_(ids)),
        "milestones": rows(Milestone, Milestone.project_id.in_(ids)),
        "tasks": rows(Task, Task.project_id.in_(ids)),
        "task_dependencies": rows(TaskDependency, TaskDependency.task_id.in_(task_ids)),
        "documents": rows(Document, Document.project_id.in_(ids)),
        "notes": rows(Note, Note.project_id.in_(ids)),
        "memories": rows(ProjectMemory, ProjectMemory.project_id.in_(ids)),
        "threads": rows(AiThread, AiThread.project_id.in_(ids)),
        "messages": rows(AiMessage, AiMessage.thread_id.in_(thread_ids)),
        "suggestions": rows(AiSuggestion, AiSuggestion.project_id.in_(ids)),
        "activity": rows(ActivityEvent, ActivityEvent.project_id.in_(ids)),
    }


def _plain(value):
    if isinstance(value, date):
        return value.isoformat()
    return value


@router.delete("/me", status_code=204)
def delete_account(db: Session = Db, user: Profile = CurrentUser) -> None:
    """Permanently delete the account with every project, file and index entry.

    Includes projects in the trash; the database cascades from the workspace down.
    """
    owned = select(Project.id).join(Workspace, Workspace.id == Project.workspace_id).where(Workspace.owner_id == user.id)
    for document in db.scalars(select(Document).where(Document.project_id.in_(owned))):
        Path(document.storage_path).unlink(missing_ok=True)
    db.execute(delete(Workspace).where(Workspace.owner_id == user.id))
    db.execute(delete(Profile).where(Profile.id == user.id))
    db.flush()
