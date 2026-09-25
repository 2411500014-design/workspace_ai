"""Insight & Notification Engine: health, today's focus, weekly review, reminders."""

from __future__ import annotations

from datetime import date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import utcnow
from app.modules.accounts.models import Profile
from app.modules.ai.models import AiSuggestion
from app.modules.ai.workflows import AIContext, weekly_review_text
from app.modules.planning import TaskProgress, compute_health
from app.modules.projects.models import Project
from app.modules.tasks.models import Milestone, Task
from app.modules.tasks.scheduling import project_capacity

from .models import Notification, ProgressSnapshot

STATUS_RANK = {"on_track": 0, "at_risk": 1, "off_track": 2}
DEADLINE_REMINDER_DAYS = (7, 3, 1)
FOCUS_LIMIT = 3


def _leaf_tasks(db: Session, project_id: str) -> list[Task]:
    tasks = list(db.scalars(select(Task).where(Task.project_id == project_id)))
    parents = {t.parent_task_id for t in tasks if t.parent_task_id}
    return [t for t in tasks if t.id not in parents]


def project_health(db: Session, user: Profile, project: Project, today: date) -> dict:
    tasks = [t for t in _leaf_tasks(db, project.id) if not t.deferred]
    if project.plan_accepted_at is None or not tasks:
        return {"has_plan": False, "status": None, "history": []}
    health = compute_health(
        [TaskProgress(t.id, t.estimate_hours, t.status == "done", t.scheduled_end, t.is_critical) for t in tasks],
        today,
        feasible=project.feasibility != "infeasible",
    )
    previous = project.health
    project.health = health.status
    snapshot = db.scalars(
        select(ProgressSnapshot).where(ProgressSnapshot.project_id == project.id, ProgressSnapshot.day == today)
    ).first()
    if snapshot is None:
        snapshot = ProgressSnapshot(project_id=project.id, day=today, planned_pct=0, actual_pct=0, health=health.status)
        db.add(snapshot)
    snapshot.planned_pct = health.planned_pct
    snapshot.actual_pct = health.actual_pct
    snapshot.spi = health.spi
    snapshot.health = health.status
    if previous and STATUS_RANK[health.status] > STATUS_RANK.get(previous, 0):
        _notify_once(db, user, project, "health_drop", today, {"from": previous, "to": health.status})
    db.flush()
    history = db.scalars(
        select(ProgressSnapshot)
        .where(ProgressSnapshot.project_id == project.id, ProgressSnapshot.day >= today - timedelta(days=60))
        .order_by(ProgressSnapshot.day)
    )
    done_hours = sum(t.estimate_hours for t in tasks if t.status == "done")
    total_hours = sum(t.estimate_hours for t in tasks)
    return {
        "has_plan": True,
        "status": health.status,
        "spi": health.spi,
        "spi_stable": health.spi_stable,
        "planned_pct": health.planned_pct,
        "actual_pct": health.actual_pct,
        "critical_late_days": health.critical_late_days,
        "reasons": list(health.reasons),
        "feasibility": project.feasibility,
        "needs_reschedule": project.needs_reschedule,
        "done_hours": round(done_hours, 2),
        "total_hours": round(total_hours, 2),
        "late_tasks": sum(1 for t in tasks if t.status != "done" and t.scheduled_end and t.scheduled_end < today),
        "history": [
            {"day": s.day.isoformat(), "planned_pct": s.planned_pct, "actual_pct": s.actual_pct, "spi": s.spi, "health": s.health}
            for s in history
        ],
    }


def _notify_once(db: Session, user: Profile, project: Project, type_: str, today: date, payload: dict) -> None:
    """At most one notification of a type per project per day (master plan §12)."""
    start = datetime(today.year, today.month, today.day)
    exists = db.scalars(
        select(Notification).where(
            Notification.user_id == user.id,
            Notification.project_id == project.id,
            Notification.type == type_,
            Notification.scheduled_at >= start,
        )
    ).first()
    if exists is None:
        db.add(Notification(user_id=user.id, project_id=project.id, type=type_, payload={**payload, "day": today.isoformat()}))


def task_brief(task: Task, project: Project, milestone_titles: dict[str, str], today: date) -> dict:
    late_days = (today - task.scheduled_end).days if task.scheduled_end and task.scheduled_end < today and task.status != "done" else 0
    return {
        "id": task.id,
        "key": task.key,
        "title": task.title,
        "status": task.status,
        "project_id": project.id,
        "project_title": project.title,
        "milestone_title": milestone_titles.get(task.milestone_id or "", ""),
        "scheduled_start": task.scheduled_start.isoformat() if task.scheduled_start else None,
        "scheduled_end": task.scheduled_end.isoformat() if task.scheduled_end else None,
        "estimate_hours": task.estimate_hours,
        "priority_score": task.priority_score,
        "is_critical": task.is_critical,
        "late_days": late_days,
        "postpone_count": task.postpone_count,
    }


def _milestone_titles(db: Session, project_ids: list[str]) -> dict[str, str]:
    if not project_ids:
        return {}
    return {m.id: m.title for m in db.scalars(select(Milestone).where(Milestone.project_id.in_(project_ids)))}


def today_view(db: Session, user: Profile, projects: list[Project], today: date) -> dict:
    titles = _milestone_titles(db, [p.id for p in projects])
    focus_candidates, upcoming, summaries = [], [], []
    for project in projects:
        tasks = [t for t in _leaf_tasks(db, project.id) if t.status != "done" and not t.deferred]
        for task in tasks:
            brief = task_brief(task, project, titles, today)
            if task.scheduled_start and task.scheduled_start <= today:
                focus_candidates.append(brief)
            elif task.scheduled_start and task.scheduled_start <= today + timedelta(days=7):
                upcoming.append(brief)
        days_left = (project.deadline - today).days
        if days_left in DEADLINE_REMINDER_DAYS:
            _notify_once(db, user, project, "deadline", today, {"days_left": days_left})
        next_milestone = None
        for milestone in db.scalars(select(Milestone).where(Milestone.project_id == project.id).order_by(Milestone.position)):
            open_tasks = [t for t in tasks if t.milestone_id == milestone.id]
            if open_tasks:
                ends = [t.scheduled_end for t in open_tasks if t.scheduled_end]
                next_milestone = {"id": milestone.id, "title": milestone.title, "planned_end": max(ends).isoformat() if ends else None}
                break
        pending = db.scalars(select(AiSuggestion.id).where(AiSuggestion.project_id == project.id, AiSuggestion.status == "pending")).all()
        # Health is recomputed here too, so a freshly accepted plan never shows as "no plan yet".
        health = project_health(db, user, project, today)["status"] if project.plan_accepted_at else None
        summaries.append(
            {
                "id": project.id,
                "title": project.title,
                "health": health,
                "feasibility": project.feasibility,
                "deadline": project.deadline.isoformat(),
                "days_left": days_left,
                "has_plan": project.plan_accepted_at is not None,
                "needs_reschedule": project.needs_reschedule,
                "pending_suggestions": len(pending),
                "next_milestone": next_milestone,
                "hours_today": project_capacity(project).hours_on(today),
            }
        )
    # Late tasks first, then the scheduler's priority (master plan §12: at most three main tasks).
    focus_candidates.sort(key=lambda b: (0 if b["late_days"] > 0 else 1, -b["priority_score"], b["key"]))
    upcoming.sort(key=lambda b: (b["scheduled_start"] or "", -b["priority_score"]))
    db.flush()
    return {
        "date": today.isoformat(),
        "focus": focus_candidates[:FOCUS_LIMIT],
        "more_today": focus_candidates[FOCUS_LIMIT:],
        "upcoming": upcoming[:5],
        "projects": summaries,
    }


def weekly_review(db: Session, ctx: AIContext, project: Project, today: date) -> dict:
    week_ago = today - timedelta(days=7)
    titles = _milestone_titles(db, [project.id])
    tasks = [t for t in _leaf_tasks(db, project.id) if not t.deferred]
    week_start = datetime.combine(week_ago, datetime.min.time()).replace(tzinfo=utcnow().tzinfo)
    done = [t for t in tasks if t.status == "done" and t.completed_at and t.completed_at >= week_start]
    slipped = [t for t in tasks if t.status != "done" and t.scheduled_end and week_ago <= t.scheduled_end < today]
    focus_next = sorted(
        (t for t in tasks if t.status != "done" and t.scheduled_start and t.scheduled_start <= today + timedelta(days=7)),
        key=lambda t: -t.priority_score,
    )[:5]
    snapshot_then = db.scalars(
        select(ProgressSnapshot).where(ProgressSnapshot.project_id == project.id, ProgressSnapshot.day <= week_ago).order_by(ProgressSnapshot.day.desc())
    ).first()
    facts = {
        "project": project.title,
        "finished": [t.title for t in done],
        "finished_hours": round(sum(t.estimate_hours for t in done), 1),
        "slipped": [t.title for t in slipped],
        "health_now": project.health,
        "health_week_ago": snapshot_then.health if snapshot_then else None,
        "focus_next_week": [t.title for t in focus_next],
    }
    text = weekly_review_text(ctx, facts)
    return {
        "period_start": week_ago.isoformat(),
        "period_end": today.isoformat(),
        "done": [task_brief(t, project, titles, today) for t in done],
        "done_hours": facts["finished_hours"],
        "slipped": [task_brief(t, project, titles, today) for t in slipped],
        "postponed": sum(1 for t in tasks if t.postpone_count > 0 and t.status != "done"),
        "health_now": project.health,
        "health_week_ago": facts["health_week_ago"],
        "focus_next": [task_brief(t, project, titles, today) for t in focus_next],
        "recommend_replan": project.health in ("at_risk", "off_track") or project.needs_reschedule,
        "summary": text.value,
        "ai_used": text.ai_used,
        "ai_error": text.ai_error,
    }


def notifications(db: Session, user: Profile, limit: int = 30) -> list[Notification]:
    return list(
        db.scalars(
            select(Notification).where(Notification.user_id == user.id).order_by(Notification.scheduled_at.desc()).limit(limit)
        )
    )
