"""Tasks and milestones: reading the plan and manual edits."""

from __future__ import annotations

from datetime import date

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.db import utcnow
from app.core.errors import AppError, NotFound
from app.modules.insight.activity import log_event
from app.modules.planning import CycleError, topological_order
from app.modules.projects.models import Project

from .models import Milestone, Task, TaskDependency, TaskRequirement
from .scheduling import load_graph

STATUSES = ("todo", "in_progress", "done")


def milestones(db: Session, project_id: str) -> list[Milestone]:
    return list(db.scalars(select(Milestone).where(Milestone.project_id == project_id).order_by(Milestone.position)))


def dependencies(db: Session, project_id: str) -> dict[str, list[str]]:
    rows = db.scalars(
        select(TaskDependency).join(Task, Task.id == TaskDependency.task_id).where(Task.project_id == project_id)
    )
    deps: dict[str, list[str]] = {}
    for row in rows:
        deps.setdefault(row.task_id, []).append(row.depends_on_id)
    return deps


def requirement_links(db: Session, project_id: str) -> dict[str, list[str]]:
    rows = db.scalars(
        select(TaskRequirement).join(Task, Task.id == TaskRequirement.task_id).where(Task.project_id == project_id)
    )
    links: dict[str, list[str]] = {}
    for row in rows:
        links.setdefault(row.task_id, []).append(row.requirement_id)
    return links


def get_task(db: Session, task_id: str, allowed_projects: set[str]) -> Task:
    task = db.get(Task, task_id)
    if task is None or task.project_id not in allowed_projects:
        raise NotFound("task")
    return task


def _check_acyclic(db: Session, project_id: str, task_id: str, new_deps: list[str]) -> None:
    graph = load_graph(db, project_id)
    deps = {k: list(v) for k, v in graph.deps.items()}
    deps[task_id] = new_deps
    try:
        topological_order([t.id for t in graph.tasks], deps)
    except CycleError as exc:
        raise AppError("dependency_cycle", 422, {"tasks": list(exc.keys)}) from exc
    except ValueError as exc:
        raise AppError("unknown_dependency", 422) from exc


def _set_dependencies(db: Session, task: Task, depends_on: list[str]) -> None:
    depends_on = list(dict.fromkeys(d for d in depends_on if d != task.id))
    valid = set(db.scalars(select(Task.id).where(Task.project_id == task.project_id, Task.id.in_(depends_on))))
    if len(valid) != len(depends_on):
        raise AppError("unknown_dependency", 422)
    _check_acyclic(db, task.project_id, task.id, depends_on)
    db.execute(delete(TaskDependency).where(TaskDependency.task_id == task.id))
    for dep in depends_on:
        db.add(TaskDependency(task_id=task.id, depends_on_id=dep))


def create_task(db: Session, project: Project, data: dict) -> Task:
    from app.modules.ai.suggestions import MAX_SUBTASK_DEPTH, _depth, next_task_key

    milestone_id = data.get("milestone_id")
    if milestone_id and db.get(Milestone, milestone_id) is None:
        raise AppError("unknown_milestone", 422)
    parent = db.get(Task, data["parent_task_id"]) if data.get("parent_task_id") else None
    if data.get("parent_task_id") and (parent is None or parent.project_id != project.id):
        raise AppError("unknown_parent", 422)
    if parent is not None and _depth(db, parent) >= MAX_SUBTASK_DEPTH:
        raise AppError("subtask_too_deep", 422)
    task = Task(
        project_id=project.id,
        milestone_id=milestone_id or (parent.milestone_id if parent else None),
        parent_task_id=parent.id if parent else None,
        key=next_task_key(db, project.id),
        title=data["title"].strip()[:300],
        description=(data.get("description") or "").strip(),
        estimate_hours=data["estimate_hours"],
        optional=data.get("optional", False),
        importance=data.get("importance", 0.0),
        source="user",
        position=10_000,
    )
    db.add(task)
    db.flush()
    if data.get("depends_on"):
        _set_dependencies(db, task, data["depends_on"])
    if project.plan_accepted_at is not None:
        project.needs_reschedule = True
    log_event(db, project.id, "user", "task_created", {"task_id": task.id})
    db.flush()
    return task


def _sync_parent(db: Session, task: Task) -> None:
    """A parent is done exactly when all of its subtasks are done."""
    if not task.parent_task_id:
        return
    parent = db.get(Task, task.parent_task_id)
    if parent is None:
        return
    siblings = list(db.scalars(select(Task).where(Task.parent_task_id == parent.id)))
    if siblings and all(s.status == "done" for s in siblings):
        if parent.status != "done":
            parent.status = "done"
            parent.completed_at = utcnow()
    elif parent.status == "done":
        parent.status = "in_progress"
        parent.completed_at = None
    _sync_parent(db, parent)


def update_task(db: Session, project: Project, task: Task, data: dict) -> Task:
    for name in ("title", "description", "definition_of_done"):
        if data.get(name) is not None:
            setattr(task, name, data[name].strip()[:300] if name == "title" else data[name].strip())
    if data.get("status") is not None and data["status"] != task.status:
        if data["status"] not in STATUSES:
            raise AppError("invalid_status", 422)
        previous = task.status
        task.status = data["status"]
        task.completed_at = utcnow() if task.status == "done" else None
        _sync_parent(db, task)
        log_event(db, project.id, "user", "task_completed" if task.status == "done" else "task_updated",
                  {"task_id": task.id, "from": previous, "to": task.status})
    if data.get("actual_hours") is not None:
        task.actual_hours = data["actual_hours"]
    if data.get("importance") is not None:
        task.importance = data["importance"]
    if data.get("optional") is not None:
        task.optional = data["optional"]
    if data.get("estimate_hours") is not None and data["estimate_hours"] != task.estimate_hours:
        task.estimate_hours = data["estimate_hours"]
        project.needs_reschedule = project.plan_accepted_at is not None
    if "milestone_id" in data and data["milestone_id"] != task.milestone_id:
        if data["milestone_id"] and db.get(Milestone, data["milestone_id"]) is None:
            raise AppError("unknown_milestone", 422)
        task.milestone_id = data["milestone_id"]
    if data.get("depends_on") is not None:
        _set_dependencies(db, task, data["depends_on"])
        project.needs_reschedule = project.plan_accepted_at is not None
    if data.get("postpone"):
        task.postpone_count += 1
        project.needs_reschedule = project.plan_accepted_at is not None
        log_event(db, project.id, "user", "task_postponed", {"task_id": task.id, "count": task.postpone_count})
    db.flush()
    return task


def delete_task(db: Session, project: Project, task: Task) -> None:
    parent_id = task.parent_task_id
    db.delete(task)
    db.flush()
    if parent_id and (parent := db.get(Task, parent_id)) is not None:
        remaining = db.scalars(select(Task).where(Task.parent_task_id == parent.id)).first()
        if remaining is not None:
            _sync_parent(db, remaining)
    if project.plan_accepted_at is not None:
        project.needs_reschedule = True
    log_event(db, project.id, "user", "task_deleted", {"task_id": task.id})


def is_late(task: Task, today: date) -> bool:
    return task.status != "done" and not task.deferred and task.scheduled_end is not None and task.scheduled_end < today
