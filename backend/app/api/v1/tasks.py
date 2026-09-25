"""Tasks, suggestions, documents and chat."""

from __future__ import annotations

from datetime import date

from fastapi import APIRouter, BackgroundTasks, Depends, File, UploadFile
from sqlalchemy.orm import Session

from app.api import serializers as ser
from app.api.deps import CurrentUser, Db, ai_context, allowed_projects, get_ai_gateway, get_today
from app.core.errors import NotFound
from app.modules.accounts.models import Profile
from app.modules.ai import chat
from app.modules.ai.gateway import Gateway
from app.modules.ai.models import AiMessage
from app.modules.ai.suggestions import apply_suggestion, get_suggestion, reject_suggestion
from app.modules.documents import service as documents
from app.modules.projects import service as projects
from app.modules.tasks import service as tasks

from .schemas import ApplyBody, ChatBody, FeedbackBody, TaskCreate, TaskUpdate

router = APIRouter(tags=["work"])


def _task_payload(db: Session, task, today: date) -> dict:
    return ser.task(task, tasks.dependencies(db, task.project_id), tasks.requirement_links(db, task.project_id), today)


# --- Tasks ----------------------------------------------------------------------------------


@router.post("/projects/{project_id}/tasks", status_code=201)
def create_task(project_id: str, body: TaskCreate, db: Session = Db, user: Profile = CurrentUser, today: date = Depends(get_today)) -> dict:
    project = projects.get_project(db, user, project_id)
    return _task_payload(db, tasks.create_task(db, project, body.model_dump()), today)


@router.get("/tasks/{task_id}")
def get_task(
    task_id: str, db: Session = Db, allowed: set[str] = Depends(allowed_projects), today: date = Depends(get_today)
) -> dict:
    return _task_payload(db, tasks.get_task(db, task_id, allowed), today)


@router.patch("/tasks/{task_id}")
def update_task(
    task_id: str, body: TaskUpdate, db: Session = Db, user: Profile = CurrentUser,
    allowed: set[str] = Depends(allowed_projects), today: date = Depends(get_today),
) -> dict:
    task = tasks.get_task(db, task_id, allowed)
    project = projects.get_project(db, user, task.project_id)
    tasks.update_task(db, project, task, body.model_dump(exclude_unset=True))
    return _task_payload(db, task, today)


@router.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: str, db: Session = Db, user: Profile = CurrentUser, allowed: set[str] = Depends(allowed_projects)) -> None:
    task = tasks.get_task(db, task_id, allowed)
    tasks.delete_task(db, projects.get_project(db, user, task.project_id), task)


@router.post("/tasks/{task_id}/breakdown", status_code=201)
def breakdown(
    task_id: str, db: Session = Db, user: Profile = CurrentUser, allowed: set[str] = Depends(allowed_projects),
    today: date = Depends(get_today), gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    task = tasks.get_task(db, task_id, allowed)
    project = projects.get_project(db, user, task.project_id)
    return ser.suggestion(db, chat.task_breakdown(db, ai_context(db, user, gateway, project), project, task, today))


@router.post("/tasks/{task_id}/start-help")
def start_help(
    task_id: str, db: Session = Db, user: Profile = CurrentUser, allowed: set[str] = Depends(allowed_projects),
    today: date = Depends(get_today), gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    task = tasks.get_task(db, task_id, allowed)
    project = projects.get_project(db, user, task.project_id)
    return chat.start_help(db, ai_context(db, user, gateway, project), project, task, today)


# --- Suggestions ------------------------------------------------------------------------------


@router.get("/suggestions/{suggestion_id}")
def read_suggestion(suggestion_id: str, db: Session = Db, allowed: set[str] = Depends(allowed_projects)) -> dict:
    return ser.suggestion(db, get_suggestion(db, suggestion_id, allowed))


@router.post("/suggestions/{suggestion_id}/apply")
def apply(
    suggestion_id: str, body: ApplyBody, db: Session = Db, user: Profile = CurrentUser,
    allowed: set[str] = Depends(allowed_projects), today: date = Depends(get_today),
) -> dict:
    suggestion = get_suggestion(db, suggestion_id, allowed)
    project = projects.get_project(db, user, suggestion.project_id)
    return ser.suggestion(db, apply_suggestion(db, project, suggestion, body.op_indices, today))


@router.post("/suggestions/{suggestion_id}/reject")
def reject(suggestion_id: str, db: Session = Db, allowed: set[str] = Depends(allowed_projects)) -> dict:
    return ser.suggestion(db, reject_suggestion(db, get_suggestion(db, suggestion_id, allowed)))


# --- Documents ----------------------------------------------------------------------------------


@router.get("/projects/{project_id}/documents")
def list_documents(project_id: str, db: Session = Db, user: Profile = CurrentUser) -> list[dict]:
    project = projects.get_project(db, user, project_id)
    counts = documents.chunk_counts(db, project.id)
    return [ser.document(d, counts.get(d.id, 0)) for d in documents.list_documents(db, project.id)]


@router.post("/projects/{project_id}/documents", status_code=202)
async def upload_document(
    project_id: str, background: BackgroundTasks, file: UploadFile = File(...), db: Session = Db,
    user: Profile = CurrentUser, gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    project = projects.get_project(db, user, project_id)
    data = await file.read()
    document = documents.upload(db, project, file.filename or "document", file.content_type, data)
    db.commit()  # the background job reads the row in its own session
    background.add_task(documents.process_document, document.id, user.id, gateway)
    return ser.document(document)


@router.get("/documents/{document_id}")
def get_document(document_id: str, db: Session = Db, allowed: set[str] = Depends(allowed_projects)) -> dict:
    document = documents.get_document(db, document_id, allowed)
    return ser.document(document, documents.chunk_counts(db, document.project_id).get(document.id, 0))


@router.post("/documents/{document_id}/retry", status_code=202)
def retry_document(
    document_id: str, background: BackgroundTasks, db: Session = Db, user: Profile = CurrentUser,
    allowed: set[str] = Depends(allowed_projects), gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    document = documents.mark_for_retry(db, documents.get_document(db, document_id, allowed))
    db.commit()
    background.add_task(documents.process_document, document.id, user.id, gateway)
    return ser.document(document)


@router.delete("/documents/{document_id}", status_code=204)
def delete_document(document_id: str, db: Session = Db, allowed: set[str] = Depends(allowed_projects)) -> None:
    documents.delete_document(db, documents.get_document(db, document_id, allowed))


# --- Chat -----------------------------------------------------------------------------------------


@router.get("/projects/{project_id}/threads")
def list_threads(project_id: str, db: Session = Db, user: Profile = CurrentUser) -> list[dict]:
    from sqlalchemy import select

    from app.modules.ai.models import AiThread

    project = projects.get_project(db, user, project_id)
    rows = db.scalars(select(AiThread).where(AiThread.project_id == project.id, AiThread.user_id == user.id).order_by(AiThread.created_at.desc()))
    return [ser.thread(t) for t in rows]


@router.get("/threads/{thread_id}/messages")
def list_messages(thread_id: str, db: Session = Db, allowed: set[str] = Depends(allowed_projects)) -> list[dict]:
    thread = chat.get_thread(db, thread_id, allowed)
    return [ser.message(m) for m in chat.thread_messages(db, thread.id)]


@router.post("/projects/{project_id}/chat")
def ask(
    project_id: str, body: ChatBody, db: Session = Db, user: Profile = CurrentUser,
    allowed: set[str] = Depends(allowed_projects), today: date = Depends(get_today),
    gateway: Gateway = Depends(get_ai_gateway),
) -> dict:
    project = projects.get_project(db, user, project_id)
    thread = chat.get_thread(db, body.thread_id, allowed) if body.thread_id else None
    if thread is not None and thread.project_id != project.id:
        raise NotFound("thread")
    thread, question, answer, ai_error = chat.ask(db, ai_context(db, user, gateway, project), project, body.question, thread, today)
    return {"thread": ser.thread(thread), "question": ser.message(question), "answer": ser.message(answer), "ai_error": ai_error}


@router.patch("/messages/{message_id}")
def message_feedback(message_id: str, body: FeedbackBody, db: Session = Db, allowed: set[str] = Depends(allowed_projects)) -> dict:
    message = db.get(AiMessage, message_id)
    if message is None or message.role != "assistant":
        raise NotFound("message")
    chat.get_thread(db, message.thread_id, allowed)
    message.feedback = body.feedback
    return ser.message(message)
