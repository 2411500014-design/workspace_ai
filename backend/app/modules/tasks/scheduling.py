"""Bridge between stored tasks and the pure Planning Engine.

Baseline dates only change when the user accepts a plan or re-plan suggestion; they are
not recomputed on every status change, otherwise progress could never fall behind the
plan and the health score would be meaningless.

Subtasks: only leaf tasks are scheduled. A parent's dates span its children, and a
dependency on a parent means a dependency on all of its leaf tasks.
"""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.modules.planning import Capacity, CycleError, PlanTask, ScheduleRequest, ScheduleResult, schedule
from app.modules.projects.models import Project

from .models import Milestone, Task, TaskDependency

DEFAULT_HOURS = [2.0, 2.0, 2.0, 2.0, 2.0, 0.0, 0.0]


def project_capacity(project: Project) -> Capacity:
    cap = project.capacity or {}
    hours = cap.get("hours_by_weekday") or DEFAULT_HOURS
    extra = {date.fromisoformat(k): float(v) for k, v in (cap.get("extra_hours") or {}).items()}
    blocked = frozenset(date.fromisoformat(d) for d in (project.blocked_dates or []))
    return Capacity(tuple(float(h) for h in hours), blocked, extra)


@dataclass
class TaskGraph:
    tasks: list[Task]
    deps: dict[str, list[str]]
    children: dict[str, list[str]]

    @property
    def by_id(self) -> dict[str, Task]:
        return {t.id: t for t in self.tasks}

    def leaves(self) -> list[Task]:
        return [t for t in self.tasks if not self.children.get(t.id)]


def _task_sort_key(task: Task, milestone_pos: dict[str, int]) -> tuple:
    number = int(task.key[1:]) if task.key[1:].isdigit() else 10_000
    return (milestone_pos.get(task.milestone_id or "", 10_000), task.position, number, task.key)


def load_graph(db: Session, project_id: str) -> TaskGraph:
    milestone_pos = {m.id: m.position for m in db.scalars(select(Milestone).where(Milestone.project_id == project_id))}
    tasks = sorted(
        db.scalars(select(Task).where(Task.project_id == project_id)),
        key=lambda t: _task_sort_key(t, milestone_pos),
    )
    ids = {t.id for t in tasks}
    deps: dict[str, list[str]] = defaultdict(list)
    for dep in db.scalars(select(TaskDependency).join(Task, Task.id == TaskDependency.task_id).where(Task.project_id == project_id)):
        if dep.task_id in ids and dep.depends_on_id in ids:
            deps[dep.task_id].append(dep.depends_on_id)
    children: dict[str, list[str]] = defaultdict(list)
    for t in tasks:
        if t.parent_task_id:
            children[t.parent_task_id].append(t.id)
    return TaskGraph(tasks, dict(deps), dict(children))


def remaining_hours(task: Task) -> float:
    if task.status == "in_progress" and task.actual_hours:
        return max(task.estimate_hours - task.actual_hours, 0.5)
    return task.estimate_hours


def plan_tasks(graph: TaskGraph) -> list[PlanTask]:
    by_id = graph.by_id

    def leaf_descendants(task_id: str) -> list[str]:
        kids = graph.children.get(task_id)
        if not kids:
            return [task_id]
        return [leaf for kid in kids for leaf in leaf_descendants(kid)]

    def inherited(task: Task) -> list[str]:
        found = list(graph.deps.get(task.id, []))
        parent = by_id.get(task.parent_task_id) if task.parent_task_id else None
        while parent is not None:
            found += graph.deps.get(parent.id, [])
            parent = by_id.get(parent.parent_task_id) if parent.parent_task_id else None
        return found

    result = []
    for task in graph.leaves():
        dep_leaves: list[str] = []
        for dep in inherited(task):
            for leaf in leaf_descendants(dep):
                if leaf != task.id and leaf not in dep_leaves:
                    dep_leaves.append(leaf)
        result.append(
            PlanTask(
                key=task.id,
                estimate_hours=remaining_hours(task),
                depends_on=tuple(dep_leaves),
                done=task.status == "done",
                optional=task.optional,
                importance=task.importance,
                deferred=task.deferred,
            )
        )
    return result


def schedule_request(project: Project, tasks: list[PlanTask], today: date) -> ScheduleRequest:
    return ScheduleRequest(tuple(tasks), today, project.deadline, project_capacity(project), project.buffer_pct)


def run_schedule(req: ScheduleRequest) -> ScheduleResult:
    try:
        return schedule(req)
    except CycleError as exc:
        raise AppError("dependency_cycle", 422, {"tasks": list(exc.keys)}) from exc


def reschedule(db: Session, project: Project, today: date) -> ScheduleResult:
    """Recompute and store the baseline schedule for every task in the project."""
    graph = load_graph(db, project.id)
    result = run_schedule(schedule_request(project, plan_tasks(graph), today))
    by_id = graph.by_id
    for task in graph.leaves():
        plan = result.tasks.get(task.id)
        if plan is not None:
            task.scheduled_start = plan.start
            task.scheduled_end = plan.end
            task.latest_finish = plan.latest_finish
            task.priority_score = plan.priority
            task.is_critical = plan.is_critical
        elif task.deferred:
            task.scheduled_start = task.scheduled_end = task.latest_finish = None
            task.priority_score = 0.0
            task.is_critical = False
        # Finished tasks keep the dates they were planned for.
    _roll_up_parents(graph, by_id)
    project.feasibility = result.feasibility
    project.needs_reschedule = False
    db.flush()
    return result


def _roll_up_parents(graph: TaskGraph, by_id: dict[str, Task]) -> None:
    def roll(task_id: str) -> Task:
        task = by_id[task_id]
        kids = [roll(k) for k in graph.children.get(task_id, [])]
        if kids:
            starts = [k.scheduled_start for k in kids if k.scheduled_start]
            ends = [k.scheduled_end for k in kids if k.scheduled_end]
            task.scheduled_start = min(starts) if starts else None
            task.scheduled_end = max(ends) if ends else None
            lates = [k.latest_finish for k in kids if k.latest_finish]
            task.latest_finish = min(lates) if lates else None
            task.is_critical = any(k.is_critical for k in kids)
            task.priority_score = max((k.priority_score for k in kids), default=0.0)
        return task

    for task in graph.tasks:
        if not task.parent_task_id:
            roll(task.id)


def summarise(result: ScheduleResult, key_for=lambda k: k) -> dict:
    """A JSON-friendly preview of a schedule, used by suggestions."""
    return {
        "feasibility": result.feasibility,
        "total_hours": result.total_hours,
        "available_hours": result.available_hours,
        "shortfall_hours": result.shortfall_hours,
        "projected_finish": result.projected_finish.isoformat() if result.projected_finish else None,
        "buffer_deadline": result.buffer_deadline.isoformat(),
        "critical_path": [key_for(k) for k in result.critical_path],
        "tasks": {
            key_for(k): {
                "start": p.start.isoformat() if p.start else None,
                "end": p.end.isoformat() if p.end else None,
                "critical": p.is_critical,
                "priority": p.priority,
            }
            for k, p in result.tasks.items()
        },
    }
