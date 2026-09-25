from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Boolean, Date, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.core.db import Base, new_id, utcnow


class Project(Base):
    __tablename__ = "projects"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    workspace_id: Mapped[str] = mapped_column(ForeignKey("workspaces.id", ondelete="CASCADE"), index=True)
    mode: Mapped[str] = mapped_column(String(20), default="academic")
    template: Mapped[str] = mapped_column(String(40), default="skripsi")
    title: Mapped[str] = mapped_column(String(300))
    description: Mapped[str] = mapped_column(Text, default="")
    target: Mapped[str] = mapped_column(Text, default="")
    deadline: Mapped[date] = mapped_column(Date)
    # {"hours_by_weekday": [7 floats, Monday first], "extra_hours": {"YYYY-MM-DD": hours}}
    capacity: Mapped[dict] = mapped_column(default=dict)
    blocked_dates: Mapped[list] = mapped_column(default=list)  # ISO dates
    buffer_pct: Mapped[float] = mapped_column(Float, default=0.15)
    health: Mapped[str | None] = mapped_column(String(12))  # on_track | at_risk | off_track
    feasibility: Mapped[str | None] = mapped_column(String(12))  # feasible | tight | infeasible
    plan_accepted_at: Mapped[datetime | None] = mapped_column()
    needs_reschedule: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)
    # Deleted projects stay in the trash for 30 days.
    deleted_at: Mapped[datetime | None] = mapped_column()


class ProjectBrief(Base):
    """The brief is the single source of truth; every edit is a new version."""

    __tablename__ = "project_briefs"
    __table_args__ = (UniqueConstraint("project_id", "version"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    version: Mapped[int] = mapped_column(Integer)
    content: Mapped[dict] = mapped_column(default=dict)
    source: Mapped[str] = mapped_column(String(10))  # ai | user | template
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class Requirement(Base):
    __tablename__ = "requirements"
    __table_args__ = (UniqueConstraint("project_id", "code"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    code: Mapped[str] = mapped_column(String(10))  # R1, R2, ...
    text: Mapped[str] = mapped_column(Text)
    source_document_id: Mapped[str | None] = mapped_column(ForeignKey("documents.id", ondelete="SET NULL"))
    status: Mapped[str] = mapped_column(String(10), default="open")  # open | met
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class Note(Base):
    __tablename__ = "notes"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(12), default="general")  # general | supervision
    content: Mapped[str] = mapped_column(Text)
    meeting_date: Mapped[date | None] = mapped_column(Date)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class ProjectMemory(Base):
    __tablename__ = "project_memories"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(12))  # decision | feedback | constraint
    content: Mapped[str] = mapped_column(Text)
    source: Mapped[str] = mapped_column(String(12), default="user")  # ai | user | supervision
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
