"""Turn ORM rows into JSON-friendly dicts (snake_case, ISO dates)."""

from __future__ import annotations

from datetime import date, datetime

from sqlalchemy.orm import Session

from app.modules.accounts.models import Profile
from app.modules.ai.models import AiMessage, AiSuggestion, AiThread
from app.modules.documents.models import Document
from app.modules.insight.models import Notification
from app.modules.projects.models import Note, Project, ProjectBrief
from app.modules.tasks.models import Milestone, Task


def iso(value: date | datetime | None) -> str | None:
    return value.isoformat() if value else None


def profile(user: Profile, ai_enabled: bool, quota: dict, auth_mode: str) -> dict:
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "locale": user.locale,
        "timezone": user.timezone,
        "ai_enabled": ai_enabled,
        "quota": quota,
        "auth_mode": auth_mode,
    }


def project(p: Project, task_count: int = 0) -> dict:
    capacity = p.capacity or {}
    return {
        "id": p.id,
        "mode": p.mode,
        "template": p.template,
        "title": p.title,
        "description": p.description,
        "target": p.target,
        "deadline": iso(p.deadline),
        "hours_by_weekday": capacity.get("hours_by_weekday", []),
        "extra_hours": capacity.get("extra_hours", {}),
        "blocked_dates": p.blocked_dates or [],
        "buffer_pct": p.buffer_pct,
        "health": p.health,
        "feasibility": p.feasibility,
        "has_plan": p.plan_accepted_at is not None,
        "plan_accepted_at": iso(p.plan_accepted_at),
        "needs_reschedule": p.needs_reschedule,
        "task_count": task_count,
        "created_at": iso(p.created_at),
    }


def brief(b: ProjectBrief | None, content: dict) -> dict:
    return {
        "version": b.version if b else 0,
        "source": b.source if b else None,
        "created_at": iso(b.created_at) if b else None,
        "content": content,
    }


def milestone(m: Milestone) -> dict:
    return {"id": m.id, "key": m.key, "title": m.title, "position": m.position, "target_date": iso(m.target_date), "status": m.status}


def task(t: Task, deps: dict[str, list[str]], reqs: dict[str, list[str]], today: date) -> dict:
    late = t.status != "done" and not t.deferred and t.scheduled_end is not None and t.scheduled_end < today
    return {
        "id": t.id,
        "project_id": t.project_id,
        "key": t.key,
        "milestone_id": t.milestone_id,
        "parent_task_id": t.parent_task_id,
        "title": t.title,
        "description": t.description,
        "definition_of_done": t.definition_of_done,
        "status": t.status,
        "estimate_hours": t.estimate_hours,
        "actual_hours": t.actual_hours,
        "priority_score": t.priority_score,
        "is_critical": t.is_critical,
        "optional": t.optional,
        "deferred": t.deferred,
        "importance": t.importance,
        "scheduled_start": iso(t.scheduled_start),
        "scheduled_end": iso(t.scheduled_end),
        "latest_finish": iso(t.latest_finish),
        "postpone_count": t.postpone_count,
        "source": t.source,
        "depends_on": deps.get(t.id, []),
        "requirement_ids": reqs.get(t.id, []),
        "late_days": (today - t.scheduled_end).days if late else 0,
        "completed_at": iso(t.completed_at),
    }


def suggestion(db: Session, s: AiSuggestion) -> dict:
    """Operations get a human label so the diff card can show what changes."""
    ops = []
    for op in s.diff.get("ops", []):
        item = dict(op)
        if op.get("entity") == "task" and op.get("id"):
            target = db.get(Task, op["id"])
            item["label"] = target.title if target else None
            item["task_key"] = target.key if target else None
        ops.append(item)
    meta = {k: v for k, v in s.diff.items() if k not in ("ops", "rationale")}
    return {
        "id": s.id,
        "project_id": s.project_id,
        "kind": s.kind,
        "status": s.status,
        "ai_used": s.ai_used,
        "rationale": s.rationale,
        "ops": ops,
        "preview": s.preview,
        "meta": meta,
        "created_at": iso(s.created_at),
        "decided_at": iso(s.decided_at),
    }


def document(d: Document, chunks: int = 0) -> dict:
    return {
        "id": d.id,
        "project_id": d.project_id,
        "kind": d.kind,
        "title": d.title,
        "filename": d.filename,
        "mime": d.mime,
        "size_bytes": d.size_bytes,
        "pages": d.pages,
        "status": d.status,
        "error_code": d.error_code,
        "summary": d.summary,
        "summary_ai": d.summary_ai,
        "metadata": d.doc_metadata,
        "chunk_count": chunks,
        "created_at": iso(d.created_at),
    }


def note(n: Note) -> dict:
    return {"id": n.id, "kind": n.kind, "content": n.content, "meeting_date": iso(n.meeting_date), "created_at": iso(n.created_at)}


def thread(t: AiThread) -> dict:
    return {"id": t.id, "project_id": t.project_id, "title": t.title, "created_at": iso(t.created_at)}


def message(m: AiMessage) -> dict:
    return {
        "id": m.id,
        "thread_id": m.thread_id,
        "role": m.role,
        "content": m.content,
        "kind": m.kind,
        "citations": m.citations,
        "feedback": m.feedback,
        "model": m.model,
        "created_at": iso(m.created_at),
    }


def notification(n: Notification) -> dict:
    return {
        "id": n.id,
        "project_id": n.project_id,
        "type": n.type,
        "payload": n.payload,
        "created_at": iso(n.scheduled_at),
        "read": n.read_at is not None,
    }
