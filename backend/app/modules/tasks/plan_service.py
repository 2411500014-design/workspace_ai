"""Plan generation and re-planning.

The LLM (or the template) proposes structure; the scheduler computes every date; the
user accepts or rejects the result as a suggestion (master plan §4, §8).
"""

from __future__ import annotations

from datetime import date

from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.modules.ai.models import AiSuggestion
from app.modules.ai.suggestions import create_suggestion
from app.modules.ai.workflows import AIContext, draft_plan, explain_replan
from app.modules.modes.loader import get_mode
from app.modules.planning import PlanTask, replan_options
from app.modules.planning.replan import boost_extra
from app.modules.projects.models import Project
from app.modules.projects.service import brief_with_requirements, task_count

from .scheduling import load_graph, plan_tasks, project_capacity, run_schedule, schedule_request, summarise


def generate_plan(db: Session, ctx: AIContext, project: Project, today: date) -> AiSuggestion:
    if task_count(db, project.id) > 0:
        raise AppError("plan_exists", 409)
    mode = get_mode(project.mode)
    template = mode.template(project.template) if mode else None
    if template is None:
        raise AppError("unknown_template", 422)
    brief = brief_with_requirements(db, project.id)
    capacity = project_capacity(project)
    weeks_left = max((project.deadline - today).days / 7, 1)
    outcome = draft_plan(ctx, brief, template, capacity.weekly_hours, weeks_left)
    draft = outcome.value

    ops: list[dict] = []
    for i, milestone in enumerate(draft["milestones"]):
        ops.append({"op": "add", "entity": "milestone", "key": milestone["key"], "fields": {"title": milestone["title"], "position": i}})
    source = "ai" if outcome.ai_used else "template"
    for i, task in enumerate(draft["tasks"]):
        ops.append(
            {
                "op": "add",
                "entity": "task",
                "key": task["key"],
                "fields": {
                    "title": task["title"],
                    "estimate_hours": task["estimate_hours"],
                    "milestone_key": task["milestone"],
                    "depends_on": task["depends_on"],
                    "optional": task["optional"],
                    "definition_of_done": task.get("definition_of_done", ""),
                    "requirement_refs": task.get("requirement_refs", []),
                    "source": source,
                    "position": i,
                },
            }
        )

    # Preview: what the scheduler would do with this structure today.
    preview_tasks = [
        PlanTask(key=t["key"], estimate_hours=float(t["estimate_hours"]), depends_on=tuple(t["depends_on"]), optional=t["optional"])
        for t in draft["tasks"]
    ]
    result = run_schedule(schedule_request(project, preview_tasks, today))
    uncovered = [r["code"] for r in brief.get("requirements", []) if not any(r["code"] in t.get("requirement_refs", []) for t in draft["tasks"])]
    return create_suggestion(
        db,
        project,
        "plan",
        ops,
        preview=summarise(result),
        ai_used=outcome.ai_used,
        meta={
            "assumptions": draft.get("assumptions", []),
            "questions": draft.get("questions", []),
            "ai_error": outcome.ai_error,
            "uncovered_requirements": uncovered,
        },
        supersede=True,
    )


def create_replan(db: Session, ctx: AIContext, project: Project, today: date) -> list[AiSuggestion]:
    if project.plan_accepted_at is None:
        raise AppError("no_plan", 409)
    graph = load_graph(db, project.id)
    by_id = graph.by_id
    req = schedule_request(project, plan_tasks(graph), today)
    options = replan_options(req)

    facts, suggestions_data = [], []
    for option in options:
        ops: list[dict] = []
        if option.kind == "add_capacity":
            extra = boost_extra(req, option.params["hours_per_week"], option.params["weeks"])
            ops.append({"op": "update", "entity": "project", "fields": {"extra_hours": {d.isoformat(): round(h, 4) for d, h in extra.items()}}})
        elif option.kind == "reduce_scope":
            for task_id in option.params["deferred"]:
                ops.append({"op": "update", "entity": "task", "id": task_id, "fields": {"deferred": True}})
        elif option.kind == "extend_deadline":
            ops.append({"op": "update", "entity": "project", "fields": {"deadline": option.params["new_deadline"]}})
        ops.append({"op": "reschedule", "entity": "project"})

        changes = []
        for task_id, plan in option.result.tasks.items():
            task = by_id.get(task_id)
            if task is None or plan.end == task.scheduled_end:
                continue
            changes.append(
                {
                    "task_id": task_id,
                    "key": task.key,
                    "title": task.title,
                    "old_end": task.scheduled_end.isoformat() if task.scheduled_end else None,
                    "new_end": plan.end.isoformat() if plan.end else None,
                }
            )
        changes.sort(key=lambda c: (c["new_end"] or "9999", c["key"]))
        preview = summarise(option.result, key_for=lambda k: by_id[k].key if k in by_id else k)
        preview["changes"] = changes[:25]
        preview["changed_count"] = len(changes)
        params = dict(option.params)
        if option.kind == "reduce_scope":
            params["deferred_titles"] = [by_id[k].title for k in option.params["deferred"] if k in by_id]
        facts.append(
            {
                "option": option.kind,
                "params": {k: v for k, v in params.items() if k != "deferred"},
                "feasibility": option.result.feasibility,
                "projected_finish": preview["projected_finish"],
                "deadline": (option.params.get("new_deadline") or project.deadline.isoformat()),
            }
        )
        suggestions_data.append((option.kind, ops, preview, params))

    explanation = explain_replan(ctx, facts)
    texts = explanation.value or [""] * len(suggestions_data)
    for old in db.query(AiSuggestion).filter(
        AiSuggestion.project_id == project.id, AiSuggestion.kind == "replan", AiSuggestion.status == "pending"
    ):
        old.status = "superseded"
    created = []
    for (kind, ops, preview, params), text in zip(suggestions_data, texts, strict=True):
        created.append(
            create_suggestion(
                db,
                project,
                "replan",
                ops,
                rationale=text,
                preview=preview,
                ai_used=explanation.ai_used,
                meta={"option": kind, "params": params, "ai_error": explanation.ai_error},
            )
        )
    return created
