"""Request bodies. Validation errors become the ``validation_failed`` code."""

from __future__ import annotations

from datetime import date
from typing import Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, Field, field_validator

Importance = Literal[0, 0.5, 1]


class MeUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=120)
    locale: Literal["id", "en"] | None = None
    timezone: str | None = None

    @field_validator("timezone")
    @classmethod
    def _valid_zone(cls, value: str | None) -> str | None:
        if value is None:
            return value
        try:
            ZoneInfo(value)
        except (ZoneInfoNotFoundError, ValueError) as exc:
            raise ValueError("unknown timezone") from exc
        return value


class ProjectCreate(BaseModel):
    mode: str = "academic"
    template: str
    title: str = Field(min_length=1, max_length=300)
    description: str = Field(default="", max_length=5000)
    target: str = Field(default="", max_length=2000)
    deadline: date
    hours_by_weekday: list[float] = Field(min_length=7, max_length=7)
    blocked_dates: list[date] = Field(default_factory=list, max_length=366)
    buffer_pct: float = Field(default=0.15, ge=0, le=0.5)


class ProjectUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=300)
    description: str | None = Field(default=None, max_length=5000)
    target: str | None = Field(default=None, max_length=2000)
    deadline: date | None = None
    hours_by_weekday: list[float] | None = Field(default=None, min_length=7, max_length=7)
    blocked_dates: list[date] | None = Field(default=None, max_length=366)
    buffer_pct: float | None = Field(default=None, ge=0, le=0.5)


class RequirementIn(BaseModel):
    code: str | None = None
    text: str = Field(max_length=1000)


class DateIn(BaseModel):
    label: str = Field(max_length=300)
    date: str | None = None


class QuestionIn(BaseModel):
    question: str = Field(max_length=500)
    answer: str = Field(default="", max_length=2000)


class BriefContent(BaseModel):
    goal: str = Field(default="", max_length=3000)
    deliverables: list[str] = Field(default_factory=list, max_length=50)
    requirements: list[RequirementIn] = Field(default_factory=list, max_length=100)
    important_dates: list[DateIn] = Field(default_factory=list, max_length=50)
    constraints: list[str] = Field(default_factory=list, max_length=50)
    open_questions: list[QuestionIn] = Field(default_factory=list, max_length=50)


class BriefSave(BaseModel):
    content: BriefContent
    source: Literal["ai", "user", "template"] = "user"


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=300)
    description: str = Field(default="", max_length=5000)
    estimate_hours: float = Field(ge=0.5, le=40)
    milestone_id: str | None = None
    parent_task_id: str | None = None
    depends_on: list[str] = Field(default_factory=list, max_length=50)
    optional: bool = False
    importance: Importance = 0


class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=300)
    description: str | None = Field(default=None, max_length=5000)
    definition_of_done: str | None = Field(default=None, max_length=2000)
    status: Literal["todo", "in_progress", "done"] | None = None
    estimate_hours: float | None = Field(default=None, ge=0.5, le=40)
    actual_hours: float | None = Field(default=None, ge=0, le=500)
    importance: Importance | None = None
    optional: bool | None = None
    milestone_id: str | None = None
    depends_on: list[str] | None = Field(default=None, max_length=50)
    postpone: bool = False


class ApplyBody(BaseModel):
    op_indices: list[int] | None = None


class NoteCreate(BaseModel):
    kind: Literal["general", "supervision"] = "general"
    content: str = Field(min_length=1, max_length=20000)
    meeting_date: date | None = None


class ChatBody(BaseModel):
    question: str = Field(min_length=1, max_length=4000)
    thread_id: str | None = None


class FeedbackBody(BaseModel):
    feedback: Literal["up", "down"] | None
