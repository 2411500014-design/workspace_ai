from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Date, Float, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.core.db import Base, new_id, utcnow


class ProgressSnapshot(Base):
    __tablename__ = "progress_snapshots"
    __table_args__ = (UniqueConstraint("project_id", "day"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    day: Mapped[date] = mapped_column(Date)
    planned_pct: Mapped[float] = mapped_column(Float)
    actual_pct: Mapped[float] = mapped_column(Float)
    spi: Mapped[float | None] = mapped_column(Float)
    health: Mapped[str] = mapped_column(String(12))


class ActivityEvent(Base):
    __tablename__ = "activity_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    actor: Mapped[str] = mapped_column(String(8))  # user | ai | system
    type: Mapped[str] = mapped_column(String(40))
    payload: Mapped[dict] = mapped_column(default=dict)
    created_at: Mapped[datetime] = mapped_column(default=utcnow, index=True)


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(ForeignKey("profiles.id", ondelete="CASCADE"), index=True)
    project_id: Mapped[str | None] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"))
    type: Mapped[str] = mapped_column(String(30))  # deadline | health_drop | weekly_review | digest
    channel: Mapped[str] = mapped_column(String(10), default="in_app")  # in_app | email | push
    payload: Mapped[dict] = mapped_column(default=dict)
    scheduled_at: Mapped[datetime] = mapped_column(default=utcnow)
    sent_at: Mapped[datetime | None] = mapped_column()
    read_at: Mapped[datetime | None] = mapped_column()
