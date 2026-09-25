"""Projects and everything scoped to one project."""

from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api import serializers as ser
from app.api.deps import CurrentUser, Db, ai_context, get_ai_gateway, get_today
from app.modules.accounts.models import Profile
from app.modules.ai.chat import supervision_suggestion
from app.modules.ai.gateway import Gateway
from app.modules.ai.models import AiSuggestion
from app.modules.ai.workflows import extract_brief
from app.modules.documents.models import Document, DocumentChunk
from app.modules.insight.service import project_health, weekly_review
from app.modules.modes.loader import get_mode, load_modes
from app.modules.projects import service as projects
from app.modules.tasks import service as tasks_service
from app.modules.tasks.plan_service import create_replan, generate_plan

from .schemas import BriefSave, NoteCreate, ProjectCreate, ProjectUpdate

router = APIRouter(tags=["projects"])


@router.get("/modes")
def list_modes() -> list[dict]:
    """Mode presets with both languages; the app picks the language to show."""
    result = []
    for mode in load_modes().values():
        result.append(
            {
                "id": mode.id,
                "name": mode.name,
                "terms": mode.terms,
                "templates": [
                    {
                        "id": t.id,
                        "name": t.name,
                        "description": t.description,
                        "task_count": len(t.all_tasks()),
                        "total_hours": sum(task.hours for task in t.all_tasks() if not task.optional),
                    }
                    for t in mode.templates
                ],
            }
        )
    return result


@router.get("/projects")
def list_projects(db: Session = Db, user: Profile = CurrentUser) -> list[dict]:
    return [ser.project(p, projects.task_count(db, p.id)) for p in projects.list_projects(db, user)]


@router.post("/projects", status_code=201)
def create_project(body: ProjectCreate, db: Session = Db, user: Profile = CurrentUser, today: date = Depends(get_today)) -> dict:
    project = projects.create_project(db, user, body.model_dump(), today)
    return ser.project(project)


@router.get("/projects/{project_id}")
def get_project(project_id: str, db: Session = Db, user: Profile = CurrentUser) -> dict:
    project = projects.get_project(db, user, project_id)
    return ser.project(project, projects.task_count(db, project.id))


@router.patch("/projects/{project_id}")
def update_project(project_id: str, body: ProjectUpdate, db: Session = Db, user: Profile = CurrentUser, today: date = Depends(get_today)) -> dict:
    project = projects.get_project(db, user, project_id)
    projects.update_project(db, project, body.model_dump(exclude_unset=True), today)
    return ser.project(project, projects.task_count(db, project.id))


@router.delete("/projects/{project_id}", status_code=204)
def delete_project(project_id: str, db: Session = Db, user: Profile = CurrentUser) -> None:
    projects.delete_project(db, projects.get_project(db, user, project_id))


# --- Brief --------------------------------------------------------------------------------


@router.get("/projects/{project_id}/brief")
def get_brief(project_id: str, db: Session = Db, user: Profile = CurrentUser) -> dict:
    project = projects.get_project(db, user, project_id)
    return ser.brief(projects.latest_brief(db, project.id), projects.brief_with_requirements(db, project.id))


@router.post("/projects/{project_id}/brief/extract")
def extract_project_brief(
    project_id: str, db: Session = Db, user: Profile = CurrentUser, gateway: Gateway = Depends(get_ai_gateway)
) -> dict:
    """Draft a brief from the intake form and documents. Nothing is saved until PUT."""
    project = projects.get_project(db, user, project_id)
    mode = get_mode(project.mode)
    template = mode.template(project.template) if mode else None
    documents = []
    for doc in db.scalars(select(Document).where(Document.project_id == project.id, Document.status == "ready")):
        text = "\n".join(
            db.scalars(select(DocumentChunk.text).where(DocumentChunk.document_id == doc.id).order_by(DocumentChunk.position))
        )
        documents.append({"title": doc.title, "kind": doc.kind, "text": text})
    intake = {
        "title": project.title,
        "description": project.description,
        "target": project.target,
        "deadline": project.deadline.isoformat(),
        "weekly_hours": sum((project.capacity or {}).get("hours_by_weekday", [])),
        "template": project.template,
    }
    outcome = extract_brief(ai_context(db, user, gateway, project), intake, documents, template)
    return {"content": outcome.value, "ai_used": outcome.ai_used, "ai_error": outcome.ai_error, "documents_used": len(documents)}


@router.put("/projects/{project_id}/brief")
def save_brief(project_id: str, body: BriefSave, db: Session = Db, user: Profile = CurrentUser) -> dict:
    project = projects.get_project(db, user, project_id)
    saved = projects.save_brief(db, project, body.content.model_dump(), body.source)
    return ser.brief(saved, projects.brief_with_requirements(db, project.id))


@router.get("/projects/{project_id}/requirements")
def requirement_checklist(project_id: str, db: Session = Db, user: Profile = CurrentUser) -> list[dict]:
    project = projects.get_project(db, user, project_id)
    return projects.requirement_checklist(db, project.id)


# --- Plan ---------------------------------------------------------------------------------


@router.get("/projects/{project_id}/plan")
def get_plan(project_id: str, db: Session = Db, user: Profile = CurrentUser, today: date = Depends(get_today)) -> dict:
    project = projects.get_project(db, user, project_id)
    deps = tasks_service.dependencies(db, project.id)
    reqs = tasks_service.requirement_links(db, project.id)
    rows = db.scalars(select(tasks_service.Task).where(tasks_service.Task.project_id == project.id))
    return {
        "project": ser.project(project),
        "milestones": [ser.milestone(m) for m in tasks_service.milestones(db, project.id)],
        "tasks": sorted(
            (ser.task(t, deps, reqs, today) for t in rows),
            key=lambda t: (int(t["key"][1:]) if t["key"][1:].isdigit() else 10_000, t["key"]),
        ),
    }


@router.post("/projects/{project_id}/plan/generate", status_code=201)
def generate(
    project_id: str,
    db: Session = Db,
    user: Profile = CurrentUser,
    today: date = Depends(get_today),
    gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    project = projects.get_project(db, user, project_id)
    suggestion = generate_plan(db, ai_context(db, user, gateway, project), project, today)
    return ser.suggestion(db, suggestion)


@router.post("/projects/{project_id}/replan", status_code=201)
def replan(
    project_id: str,
    db: Session = Db,
    user: Profile = CurrentUser,
    today: date = Depends(get_today),
    gateway: Gateway = Depends(get_ai_gateway),
) -> list[dict]:
    project = projects.get_project(db, user, project_id)
    return [ser.suggestion(db, s) for s in create_replan(db, ai_context(db, user, gateway, project), project, today)]


@router.get("/projects/{project_id}/suggestions")
def list_suggestions(project_id: str, status: str | None = "pending", db: Session = Db, user: Profile = CurrentUser) -> list[dict]:
    project = projects.get_project(db, user, project_id)
    query = select(AiSuggestion).where(AiSuggestion.project_id == project.id)
    if status:
        query = query.where(AiSuggestion.status == status)
    return [ser.suggestion(db, s) for s in db.scalars(query.order_by(AiSuggestion.created_at.desc()))]


# --- Health and review ---------------------------------------------------------------------


@router.get("/projects/{project_id}/health")
def health(project_id: str, db: Session = Db, user: Profile = CurrentUser, today: date = Depends(get_today)) -> dict:
    project = projects.get_project(db, user, project_id)
    return project_health(db, user, project, today)


@router.get("/projects/{project_id}/weekly-review")
def get_weekly_review(
    project_id: str,
    db: Session = Db,
    user: Profile = CurrentUser,
    today: date = Depends(get_today),
    gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    project = projects.get_project(db, user, project_id)
    project_health(db, user, project, today)
    return weekly_review(db, ai_context(db, user, gateway, project), project, today)


# --- Notes and the supervision log ----------------------------------------------------------


@router.get("/projects/{project_id}/notes")
def list_notes(project_id: str, kind: str | None = None, db: Session = Db, user: Profile = CurrentUser) -> list[dict]:
    project = projects.get_project(db, user, project_id)
    return [ser.note(n) for n in projects.list_notes(db, project.id, kind)]


@router.post("/projects/{project_id}/notes", status_code=201)
def add_note(
    project_id: str,
    body: NoteCreate,
    db: Session = Db,
    user: Profile = CurrentUser,
    today: date = Depends(get_today),
    gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    project = projects.get_project(db, user, project_id)
    note = projects.add_note(db, project, body.kind, body.content, body.meeting_date)
    suggestion = None
    if body.kind == "supervision":
        suggestion = supervision_suggestion(db, ai_context(db, user, gateway, project), project, note, today)
    return {"note": ser.note(note), "suggestion": ser.suggestion(db, suggestion) if suggestion else None}
