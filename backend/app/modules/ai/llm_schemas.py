"""Output schemas for structured outputs.

Kept free of validation constraints: structured outputs support only part of JSON
Schema, so ranges and cross-references are checked in code after parsing (master plan
§7, "Structured output dan tool calling").
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel


class LlmRequirement(BaseModel):
    code: str
    text: str


class LlmDate(BaseModel):
    label: str
    date: str | None


class BriefDraft(BaseModel):
    goal: str
    deliverables: list[str]
    requirements: list[LlmRequirement]
    important_dates: list[LlmDate]
    constraints: list[str]
    open_questions: list[str]


class LlmMilestone(BaseModel):
    key: str
    title: str


class LlmTask(BaseModel):
    key: str
    milestone: str
    title: str
    estimate_hours: float
    depends_on: list[str]
    optional: bool
    definition_of_done: str
    requirement_refs: list[str]


class PlanDraft(BaseModel):
    """The Plan Generator contract (master plan §8): structure only, never dates."""

    milestones: list[LlmMilestone]
    tasks: list[LlmTask]
    assumptions: list[str]
    questions: list[str]


class LlmSubtask(BaseModel):
    title: str
    estimate_hours: float


class BreakdownDraft(BaseModel):
    subtasks: list[LlmSubtask]
    first_step: str


class LlmRevisionTask(BaseModel):
    title: str
    estimate_hours: float


class LlmMemory(BaseModel):
    kind: Literal["decision", "feedback", "constraint"]
    content: str


class SupervisionDraft(BaseModel):
    memories: list[LlmMemory]
    revision_tasks: list[LlmRevisionTask]


class DocInsight(BaseModel):
    kind: Literal["proposal", "instruction", "journal", "supervision", "draft", "other"]
    title: str
    summary: str
    authors: list[str]
    year: int | None
    doi: str | None
