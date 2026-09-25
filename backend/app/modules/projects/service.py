"""Projects, briefs, requirements, notes and project memory."""

from __future__ import annotations

from datetime import date

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.auth import ensure_workspace, workspace_ids
from app.core.db import utcnow
from app.core.errors import AppError, NotFound
from app.modules.accounts.models import Profile
from app.modules.modes.loader import get_mode
from app.modules.tasks.models import Task, TaskRequirement

from .models import Note, Project, ProjectBrief, ProjectMemory, Requirement

SCHEDULE_FIELDS = {"deadline", "capacity", "blocked_dates", "buffer_pct"}


def list_projects(db: Session, user: Profile) -> list[Project]:
    return list(
        db.scalars(
            select(Project)
            .where(Project.workspace_id.in_(workspace_ids(db, user)), Project.deleted_at.is_(None))
            .order_by(Project.created_at)
        )
    )


def get_project(db: Session, user: Profile, project_id: str) -> Project:
    """The single access check for projects (master plan §13)."""
    project = db.get(Project, project_id)
    if project is None or project.deleted_at is not None or project.workspace_id not in workspace_ids(db, user):
        raise NotFound("project")
    return project


def project_ids(db: Session, user: Profile) -> set[str]:
    return {p.id for p in list_projects(db, user)}


def _validate_capacity(hours: list[float]) -> list[float]:
    if len(hours) != 7 or any(h < 0 or h > 16 for h in hours):
        raise AppError("invalid_capacity", 422)
    if sum(hours) <= 0:
        raise AppError("invalid_capacity", 422)
    return [float(h) for h in hours]


def create_project(db: Session, user: Profile, data: dict, today: date) -> Project:
    mode = get_mode(data.get("mode", "academic"))
    if mode is None or mode.template(data.get("template", "")) is None:
        raise AppError("unknown_template", 422)
    if data["deadline"] <= today:
        raise AppError("deadline_in_past", 422)
    workspace = ensure_workspace(db, user)
    project = Project(
        workspace_id=workspace.id,
        mode=mode.id,
        template=data["template"],
        title=data["title"].strip()[:300],
        description=(data.get("description") or "").strip(),
        target=(data.get("target") or "").strip(),
        deadline=data["deadline"],
        capacity={"hours_by_weekday": _validate_capacity(data["hours_by_weekday"]), "extra_hours": {}},
        blocked_dates=sorted({d.isoformat() for d in data.get("blocked_dates", [])}),
        buffer_pct=data.get("buffer_pct", 0.15),
    )
    db.add(project)
    db.flush()
    return project


def update_project(db: Session, project: Project, data: dict, today: date) -> Project:
    changed_schedule = False
    for name in ("title", "description", "target"):
        if name in data and data[name] is not None:
            setattr(project, name, data[name].strip())
    if data.get("deadline") is not None and data["deadline"] != project.deadline:
        if data["deadline"] <= today:
            raise AppError("deadline_in_past", 422)
        project.deadline = data["deadline"]
        changed_schedule = True
    if data.get("hours_by_weekday") is not None:
        capacity = dict(project.capacity or {})
        capacity["hours_by_weekday"] = _validate_capacity(data["hours_by_weekday"])
        project.capacity = capacity
        changed_schedule = True
    if data.get("blocked_dates") is not None:
        project.blocked_dates = sorted({d.isoformat() for d in data["blocked_dates"]})
        changed_schedule = True
    if data.get("buffer_pct") is not None:
        project.buffer_pct = data["buffer_pct"]
        changed_schedule = True
    if changed_schedule and project.plan_accepted_at is not None:
        # Dates change only through an accepted suggestion; flag it so the app offers one.
        project.needs_reschedule = True
    db.flush()
    return project


def delete_project(db: Session, project: Project) -> None:
    """Soft delete: the project stays in the trash for 30 days."""
    project.deleted_at = utcnow()


# --- Brief ------------------------------------------------------------------------------


def latest_brief(db: Session, project_id: str) -> ProjectBrief | None:
    return db.scalars(
        select(ProjectBrief).where(ProjectBrief.project_id == project_id).order_by(ProjectBrief.version.desc())
    ).first()


def requirements(db: Session, project_id: str) -> list[Requirement]:
    rows = db.scalars(select(Requirement).where(Requirement.project_id == project_id))
    return sorted(rows, key=lambda r: int(r.code[1:]) if r.code[1:].isdigit() else 10_000)


def brief_with_requirements(db: Session, project_id: str) -> dict:
    """The brief content with requirements taken from the table (their source of truth)."""
    brief = latest_brief(db, project_id)
    content = dict(brief.content) if brief else {}
    content["requirements"] = [{"code": r.code, "text": r.text} for r in requirements(db, project_id)]
    return content


def save_brief(db: Session, project: Project, content: dict, source: str) -> ProjectBrief:
    """Save a new brief version and bring the requirements table in line with it."""
    current = latest_brief(db, project.id)
    version = (current.version + 1) if current else 1
    existing = {r.code: r for r in requirements(db, project.id)}
    by_text = {r.text.strip().lower(): r for r in existing.values()}
    numbers = [int(c[1:]) for c in existing if c[1:].isdigit()] or [0]
    keep: set[str] = set()
    ordered: list[dict] = []
    for item in content.get("requirements", []):
        text = str(item.get("text", "")).strip()
        if not text:
            continue
        code = item.get("code")
        row = existing.get(code) if code else None
        row = row or by_text.get(text.lower())
        if row is None:
            numbers.append(max(numbers) + 1)
            row = Requirement(project_id=project.id, code=f"R{max(numbers)}", text=text)
            db.add(row)
            existing[row.code] = row
        else:
            row.text = text
        keep.add(row.code)
        ordered.append({"code": row.code, "text": text})
    for code, row in existing.items():
        if code not in keep:
            db.delete(row)
    stored = dict(content)
    stored["requirements"] = ordered
    brief = ProjectBrief(project_id=project.id, version=version, content=stored, source=source)
    db.add(brief)
    _retire_covered_brief_updates(db, project.id, [item["text"] for item in ordered])
    db.flush()
    return brief


def _retire_covered_brief_updates(db: Session, project_id: str, texts: list[str]) -> None:
    """A saved brief that already holds every proposed requirement answers the proposal."""
    from app.modules.ai.models import AiSuggestion
    from app.modules.documents.heuristics import same_requirement

    pending = db.scalars(
        select(AiSuggestion).where(
            AiSuggestion.project_id == project_id, AiSuggestion.kind == "brief_update", AiSuggestion.status == "pending"
        )
    )
    for suggestion in pending:
        proposed = [str(op.get("fields", {}).get("text", "")) for op in suggestion.diff.get("ops", [])]
        if all(any(same_requirement(p, t) for t in texts) for p in proposed):
            suggestion.status = "superseded"
            suggestion.decided_at = utcnow()


def requirement_checklist(db: Session, project_id: str) -> list[dict]:
    """Requirements with their linked tasks. A requirement without a task is flagged red."""
    rows = requirements(db, project_id)
    links = db.execute(
        select(TaskRequirement.requirement_id, Task)
        .join(Task, Task.id == TaskRequirement.task_id)
        .where(Task.project_id == project_id)
    ).all()
    tasks_for: dict[str, list[Task]] = {}
    for requirement_id, task in links:
        tasks_for.setdefault(requirement_id, []).append(task)
    result = []
    for r in rows:
        tasks = [t for t in tasks_for.get(r.id, []) if not t.deferred]
        result.append(
            {
                "id": r.id,
                "code": r.code,
                "text": r.text,
                "covered": bool(tasks),
                "met": bool(tasks) and all(t.status == "done" for t in tasks),
                "tasks": [{"id": t.id, "key": t.key, "title": t.title, "status": t.status} for t in tasks],
            }
        )
    return result


# --- Notes and memory ------------------------------------------------------------------


def list_notes(db: Session, project_id: str, kind: str | None = None) -> list[Note]:
    query = select(Note).where(Note.project_id == project_id)
    if kind:
        query = query.where(Note.kind == kind)
    return list(db.scalars(query.order_by(Note.created_at.desc())))


def add_note(db: Session, project: Project, kind: str, content: str, meeting_date: date | None) -> Note:
    note = Note(project_id=project.id, kind=kind, content=content.strip(), meeting_date=meeting_date)
    db.add(note)
    db.flush()
    return note


def active_memories(db: Session, project_id: str, limit: int = 12) -> list[ProjectMemory]:
    return list(
        db.scalars(
            select(ProjectMemory)
            .where(ProjectMemory.project_id == project_id, ProjectMemory.active.is_(True))
            .order_by(ProjectMemory.created_at.desc())
            .limit(limit)
        )
    )


def task_count(db: Session, project_id: str) -> int:
    return db.scalar(select(func.count()).select_from(Task).where(Task.project_id == project_id)) or 0
