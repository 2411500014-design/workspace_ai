"""Suggestions: every AI (or scheduler) proposal is a diff the user reviews.

Diff format (master plan §11)::

    {"ops": [
        {"op": "update", "entity": "task", "id": "t_42", "fields": {"deferred": true}},
        {"op": "add", "entity": "task", "key": "new1", "fields": {"title": "...", "estimate_hours": 4}}
     ],
     "rationale": "..."}

The user may accept all operations, a subset, or none. Applying records an activity
event, so the history of plan changes can always be traced.
"""

from __future__ import annotations

import re
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import utcnow
from app.core.errors import AppError, NotFound
from app.modules.insight.activity import log_event
from app.modules.projects.models import Project, ProjectMemory, Requirement
from app.modules.tasks.models import Milestone, Task, TaskDependency, TaskRequirement
from app.modules.tasks.scheduling import reschedule

from .models import AiSuggestion

TASK_FIELDS = {"title", "estimate_hours", "optional", "deferred", "importance", "definition_of_done", "description", "milestone_id"}
MAX_SUBTASK_DEPTH = 3


def create_suggestion(
    db: Session,
    project: Project,
    kind: str,
    ops: list[dict],
    *,
    rationale: str = "",
    preview: dict | None = None,
    ai_used: bool = False,
    meta: dict | None = None,
    supersede: bool = False,
) -> AiSuggestion:
    if supersede:
        for old in db.scalars(
            select(AiSuggestion).where(
                AiSuggestion.project_id == project.id, AiSuggestion.kind == kind, AiSuggestion.status == "pending"
            )
        ):
            old.status = "superseded"
            old.decided_at = utcnow()
    suggestion = AiSuggestion(
        project_id=project.id,
        kind=kind,
        diff={"ops": ops, "rationale": rationale, **(meta or {})},
        rationale=rationale,
        preview=preview or {},
        ai_used=ai_used,
    )
    db.add(suggestion)
    db.flush()
    log_event(db, project.id, "ai" if ai_used else "system", "suggestion_created", {"suggestion_id": suggestion.id, "kind": kind})
    return suggestion


def next_task_key(db: Session, project_id: str, taken: set[str] | None = None) -> str:
    numbers = [0]
    for key in db.scalars(select(Task.key).where(Task.project_id == project_id)):
        if m := re.fullmatch(r"T(\d+)", key):
            numbers.append(int(m.group(1)))
    for key in taken or ():
        if m := re.fullmatch(r"T(\d+)", key):
            numbers.append(int(m.group(1)))
    return f"T{max(numbers) + 1}"


def _depth(db: Session, task: Task | None) -> int:
    depth = 0
    while task is not None:
        depth += 1
        task = db.get(Task, task.parent_task_id) if task.parent_task_id else None
    return depth


class _Applier:
    def __init__(self, db: Session, project: Project, suggestion: AiSuggestion) -> None:
        self.db = db
        self.project = project
        self.suggestion = suggestion
        self.created_tasks: dict[str, Task] = {}
        self.created_milestones: dict[str, Milestone] = {}
        self.pending_deps: list[tuple[Task, list[str]]] = []
        self.pending_reqs: list[tuple[Task, list[str]]] = []
        self.structural = False
        self.needs_reschedule_only = False

    def task_by_ref(self, ref: str) -> Task | None:
        if ref in self.created_tasks:
            return self.created_tasks[ref]
        task = self.db.get(Task, ref)
        if task is not None and task.project_id == self.project.id:
            return task
        return self.db.scalars(select(Task).where(Task.project_id == self.project.id, Task.key == ref)).first()

    def milestone_by_ref(self, ref: str | None) -> Milestone | None:
        if not ref:
            return None
        if ref in self.created_milestones:
            return self.created_milestones[ref]
        milestone = self.db.get(Milestone, ref)
        if milestone is not None and milestone.project_id == self.project.id:
            return milestone
        return self.db.scalars(select(Milestone).where(Milestone.project_id == self.project.id, Milestone.key == ref)).first()

    def apply(self, op: dict) -> None:
        kind, entity = op.get("op"), op.get("entity")
        handler = getattr(self, f"_{kind}_{entity}", None)
        if handler is None:
            raise AppError("invalid_suggestion", 422, {"op": kind, "entity": entity})
        handler(op)

    # --- handlers --------------------------------------------------------------------

    def _add_milestone(self, op: dict) -> None:
        fields = op.get("fields", {})
        key = op.get("key") or f"M{len(self.created_milestones) + 1}"
        existing = self.db.scalars(select(Milestone).where(Milestone.project_id == self.project.id, Milestone.key == key)).first()
        if existing is not None:
            self.created_milestones[key] = existing
            return
        target = fields.get("target_date")
        milestone = Milestone(
            project_id=self.project.id,
            key=key,
            title=str(fields.get("title", key))[:300],
            position=int(fields.get("position", 0)),
            target_date=date.fromisoformat(target) if target else None,
        )
        self.db.add(milestone)
        self.db.flush()
        self.created_milestones[key] = milestone

    def _add_task(self, op: dict) -> None:
        fields = op.get("fields", {})
        taken = {t.key for t in self.created_tasks.values()}
        key = op.get("key")
        clash = key and self.db.scalars(select(Task.id).where(Task.project_id == self.project.id, Task.key == key)).first()
        if not key or clash or not re.fullmatch(r"T\d+", key):
            new_key = next_task_key(self.db, self.project.id, taken)
        else:
            new_key = key
        parent = self.task_by_ref(fields["parent_task_id"]) if fields.get("parent_task_id") else None
        if parent is not None and _depth(self.db, parent) >= MAX_SUBTASK_DEPTH:
            parent = None
        milestone = self.milestone_by_ref(fields.get("milestone_key") or fields.get("milestone_id"))
        if milestone is None and parent is not None and parent.milestone_id:
            milestone = self.db.get(Milestone, parent.milestone_id)
        estimate = float(fields.get("estimate_hours", 1.0))
        task = Task(
            project_id=self.project.id,
            milestone_id=milestone.id if milestone else None,
            parent_task_id=parent.id if parent else None,
            key=new_key,
            title=str(fields.get("title", new_key))[:300],
            description=str(fields.get("description", "")),
            definition_of_done=str(fields.get("definition_of_done", "")),
            estimate_hours=min(max(estimate, 0.5), 40.0),
            optional=bool(fields.get("optional", False)),
            importance=float(fields.get("importance", 0.0)),
            source=str(fields.get("source", "ai" if self.suggestion.ai_used else "template")),
            position=int(fields.get("position", len(self.created_tasks))),
        )
        self.db.add(task)
        self.db.flush()
        self.created_tasks[op.get("key") or new_key] = task
        self.pending_deps.append((task, list(fields.get("depends_on", []))))
        self.pending_reqs.append((task, list(fields.get("requirement_refs", []))))
        self.structural = True

    def _update_task(self, op: dict) -> None:
        task = self.task_by_ref(op.get("id", ""))
        if task is None:
            return  # deleted since the suggestion was made
        for name, value in op.get("fields", {}).items():
            if name in TASK_FIELDS:
                setattr(task, name, value)
        self.structural = True

    def _delete_task(self, op: dict) -> None:
        task = self.task_by_ref(op.get("id", ""))
        if task is not None:
            self.db.delete(task)
            self.structural = True

    def _update_project(self, op: dict) -> None:
        fields = op.get("fields", {})
        if "deadline" in fields:
            self.project.deadline = date.fromisoformat(fields["deadline"])
        if "extra_hours" in fields:
            capacity = dict(self.project.capacity or {})
            extra = dict(capacity.get("extra_hours") or {})
            for day, hours in fields["extra_hours"].items():
                extra[day] = round(float(extra.get(day, 0.0)) + float(hours), 4)
            capacity["extra_hours"] = extra
            self.project.capacity = capacity
        if "hours_by_weekday" in fields:
            capacity = dict(self.project.capacity or {})
            capacity["hours_by_weekday"] = [float(h) for h in fields["hours_by_weekday"]]
            self.project.capacity = capacity
        self.structural = True

    def _reschedule_project(self, op: dict) -> None:  # noqa: ARG002
        self.structural = True

    def _add_requirement(self, op: dict) -> None:
        text = str(op.get("fields", {}).get("text", "")).strip()
        if not text:
            return
        existing = list(self.db.scalars(select(Requirement).where(Requirement.project_id == self.project.id)))
        if any(r.text.lower() == text.lower() for r in existing):
            return
        numbers = [int(r.code[1:]) for r in existing if r.code[1:].isdigit()] or [0]
        self.db.add(
            Requirement(
                project_id=self.project.id,
                code=f"R{max(numbers) + 1}",
                text=text,
                source_document_id=op.get("fields", {}).get("source_document_id"),
            )
        )
        self.db.flush()

    def _add_memory(self, op: dict) -> None:
        fields = op.get("fields", {})
        content = str(fields.get("content", "")).strip()
        if content:
            self.db.add(
                ProjectMemory(
                    project_id=self.project.id,
                    kind=str(fields.get("kind", "feedback")),
                    content=content,
                    source=str(fields.get("source", "ai")),
                )
            )

    def finish(self) -> None:
        for task, refs in self.pending_deps:
            seen = set()
            for ref in refs:
                dep = self.task_by_ref(ref)
                if dep is None or dep.id == task.id or dep.id in seen:
                    continue  # the prerequisite was not accepted
                seen.add(dep.id)
                self.db.add(TaskDependency(task_id=task.id, depends_on_id=dep.id))
        codes = {r.code: r for r in self.db.scalars(select(Requirement).where(Requirement.project_id == self.project.id))}
        for task, refs in self.pending_reqs:
            for code in dict.fromkeys(refs):
                if code in codes:
                    self.db.add(TaskRequirement(task_id=task.id, requirement_id=codes[code].id))
        self.db.flush()


def apply_suggestion(
    db: Session, project: Project, suggestion: AiSuggestion, op_indices: list[int] | None, today: date
) -> AiSuggestion:
    if suggestion.status != "pending":
        raise AppError("suggestion_already_decided", 409, {"status": suggestion.status})
    ops = suggestion.diff.get("ops", [])
    selected = list(range(len(ops))) if op_indices is None else sorted(set(op_indices))
    if any(i < 0 or i >= len(ops) for i in selected):
        raise AppError("invalid_selection", 422)
    if not selected:
        raise AppError("empty_selection", 422)

    applier = _Applier(db, project, suggestion)
    # Milestones first so tasks can reference them regardless of op order.
    for i in sorted(selected, key=lambda i: 0 if ops[i].get("entity") == "milestone" else 1):
        applier.apply(ops[i])
    applier.finish()

    if applier.structural:
        reschedule(db, project, today)
        if suggestion.kind == "plan":
            project.plan_accepted_at = utcnow()
    suggestion.status = "applied" if len(selected) == len(ops) else "partially_applied"
    suggestion.decided_at = utcnow()
    if suggestion.kind == "replan":
        # The other options were computed against the old schedule; they are now stale.
        for sibling in db.scalars(
            select(AiSuggestion).where(
                AiSuggestion.project_id == project.id,
                AiSuggestion.kind == "replan",
                AiSuggestion.status == "pending",
                AiSuggestion.id != suggestion.id,
            )
        ):
            sibling.status = "superseded"
            sibling.decided_at = utcnow()
    log_event(
        db,
        project.id,
        "user",
        "suggestion_applied",
        {"suggestion_id": suggestion.id, "kind": suggestion.kind, "applied_ops": selected, "total_ops": len(ops)},
    )
    db.flush()
    return suggestion


def reject_suggestion(db: Session, suggestion: AiSuggestion) -> AiSuggestion:
    if suggestion.status != "pending":
        raise AppError("suggestion_already_decided", 409, {"status": suggestion.status})
    suggestion.status = "rejected"
    suggestion.decided_at = utcnow()
    log_event(db, suggestion.project_id, "user", "suggestion_rejected", {"suggestion_id": suggestion.id, "kind": suggestion.kind})
    return suggestion


def get_suggestion(db: Session, suggestion_id: str, project_ids: set[str]) -> AiSuggestion:
    suggestion = db.get(AiSuggestion, suggestion_id)
    if suggestion is None or suggestion.project_id not in project_ids:
        raise NotFound("suggestion")
    return suggestion
