"""Project Chat, the task helper and the supervision log (master plan §7)."""

from __future__ import annotations

from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.errors import NotFound
from app.modules.documents.service import search_passages
from app.modules.projects.models import Note, Project
from app.modules.projects.service import active_memories, brief_with_requirements
from app.modules.tasks.models import Milestone, Task

from .models import AiMessage, AiSuggestion, AiThread
from .suggestions import create_suggestion
from .workflows import AIContext, answer_question, breakdown_task, brief_as_text, supervision_proposals

HISTORY_MESSAGES = 6


def project_context_text(db: Session, project: Project, today: date) -> str:
    """Brief, plan snapshot and memory, in that order (master plan §7, Context Engine)."""
    lines = [f"Project: {project.title} (deadline {project.deadline.isoformat()}, today {today.isoformat()})"]
    brief = brief_with_requirements(db, project.id)
    if brief:
        lines += ["", "Brief:", brief_as_text(brief)]
    milestones = list(db.scalars(select(Milestone).where(Milestone.project_id == project.id).order_by(Milestone.position)))
    tasks = list(db.scalars(select(Task).where(Task.project_id == project.id)))
    if milestones:
        lines += ["", f"Plan (health: {project.health or 'unknown'}, feasibility: {project.feasibility or 'unknown'}):"]
        for m in milestones:
            mine = [t for t in tasks if t.milestone_id == m.id and not t.parent_task_id]
            done = sum(1 for t in mine if t.status == "done")
            lines.append(f"- {m.title}: {done}/{len(mine)} tasks done")
        active = sorted((t for t in tasks if t.status != "done" and not t.deferred), key=lambda t: -t.priority_score)[:10]
        if active:
            lines.append("Next tasks:")
            for t in active:
                when = f", planned {t.scheduled_start} to {t.scheduled_end}" if t.scheduled_start else ""
                lines.append(f"  - {t.key} {t.title} ({t.status}{when})")
    memories = active_memories(db, project.id)
    if memories:
        lines += ["", "Project memory:"] + [f"- [{m.kind}] {m.content}" for m in memories]
    return "\n".join(lines)


def get_thread(db: Session, thread_id: str, allowed_projects: set[str]) -> AiThread:
    thread = db.get(AiThread, thread_id)
    if thread is None or thread.project_id not in allowed_projects:
        raise NotFound("thread")
    return thread


def thread_messages(db: Session, thread_id: str) -> list[AiMessage]:
    return list(db.scalars(select(AiMessage).where(AiMessage.thread_id == thread_id).order_by(AiMessage.created_at)))


def ask(db: Session, ctx: AIContext, project: Project, question: str, thread: AiThread | None, today: date):
    if thread is None:
        thread = AiThread(project_id=project.id, user_id=ctx.user.id, title=question.strip()[:80])
        db.add(thread)
        db.flush()
    history = [(m.role, m.content) for m in thread_messages(db, thread.id) if m.content][-HISTORY_MESSAGES:]
    user_message = AiMessage(thread_id=thread.id, role="user", content=question.strip(), kind="user")
    db.add(user_message)
    db.flush()
    passages = search_passages(db, project.id, question)
    outcome = answer_question(ctx, question, passages, project_context_text(db, project, today), history)
    answer = outcome.value
    assistant = AiMessage(
        thread_id=thread.id,
        role="assistant",
        content=answer.content,
        kind=answer.kind,
        citations=answer.citations,
        model=outcome.model,
        prompt_version=outcome.prompt_version if outcome.ai_used else None,
        input_tokens=outcome.input_tokens,
        output_tokens=outcome.output_tokens,
    )
    db.add(assistant)
    db.flush()
    return thread, user_message, assistant, outcome.ai_error


def task_breakdown(db: Session, ctx: AIContext, project: Project, task: Task, today: date) -> AiSuggestion:
    outcome = breakdown_task(ctx, task.title, task.estimate_hours, task.description, project_context_text(db, project, today))
    ops = [
        {
            "op": "add",
            "entity": "task",
            "fields": {"title": s["title"], "estimate_hours": s["estimate_hours"], "parent_task_id": task.id, "position": i},
        }
        for i, s in enumerate(outcome.value["subtasks"])
    ]
    return create_suggestion(
        db,
        project,
        "task_change",
        ops,
        rationale=outcome.value["first_step"],
        ai_used=outcome.ai_used,
        meta={"origin": "breakdown", "task_id": task.id, "task_title": task.title, "ai_error": outcome.ai_error},
    )


def start_help(db: Session, ctx: AIContext, project: Project, task: Task, today: date) -> dict:
    outcome = breakdown_task(ctx, task.title, task.estimate_hours, task.description, project_context_text(db, project, today))
    return {
        "first_step": outcome.value["first_step"],
        "subtasks": outcome.value["subtasks"],
        "ai_used": outcome.ai_used,
        "ai_error": outcome.ai_error,
    }


def supervision_suggestion(db: Session, ctx: AIContext, project: Project, note: Note, today: date) -> AiSuggestion | None:
    outcome = supervision_proposals(ctx, note.content, project_context_text(db, project, today))
    current = None
    for milestone in db.scalars(select(Milestone).where(Milestone.project_id == project.id).order_by(Milestone.position)):
        if db.scalars(select(Task.id).where(Task.milestone_id == milestone.id, Task.status != "done")).first():
            current = milestone
            break
    ops: list[dict] = [
        {"op": "add", "entity": "memory", "fields": {"kind": m["kind"], "content": m["content"], "source": "supervision"}}
        for m in outcome.value["memories"]
    ]
    for i, revision in enumerate(outcome.value["revision_tasks"]):
        fields = {"title": revision["title"], "estimate_hours": revision["estimate_hours"], "source": "supervision", "position": 5000 + i}
        if current is not None:
            fields["milestone_id"] = current.id
        ops.append({"op": "add", "entity": "task", "fields": fields})
    if not ops:
        return None
    return create_suggestion(
        db,
        project,
        "task_change",
        ops,
        ai_used=outcome.ai_used,
        meta={"origin": "supervision", "note_id": note.id, "meeting_date": note.meeting_date.isoformat() if note.meeting_date else None, "ai_error": outcome.ai_error},
    )
