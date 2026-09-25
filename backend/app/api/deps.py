"""Shared FastAPI dependencies."""

from __future__ import annotations

from datetime import date

from fastapi import Depends
from sqlalchemy.orm import Session

from app.core.auth import get_current_user
from app.core.clock import Clock, get_clock
from app.core.db import get_db
from app.modules.accounts.models import Profile
from app.modules.ai.gateway import Gateway, get_gateway
from app.modules.ai.workflows import AIContext
from app.modules.modes.loader import get_mode
from app.modules.projects.models import Project
from app.modules.projects.service import project_ids

__all__ = ["CurrentUser", "Db", "ai_context", "allowed_projects", "get_ai_gateway", "get_today"]


def get_ai_gateway() -> Gateway:
    return get_gateway()


def get_today(user: Profile = Depends(get_current_user), clock: Clock = Depends(get_clock)) -> date:
    return clock.today(user.timezone)


def allowed_projects(db: Session = Depends(get_db), user: Profile = Depends(get_current_user)) -> set[str]:
    return project_ids(db, user)


def ai_context(db: Session, user: Profile, gateway: Gateway, project: Project | None = None) -> AIContext:
    return AIContext(
        db=db,
        user=user,
        gateway=gateway,
        mode=get_mode(project.mode) if project else get_mode("academic"),
        locale=user.locale,
        project_id=project.id if project else None,
    )


Db = Depends(get_db)
CurrentUser = Depends(get_current_user)
