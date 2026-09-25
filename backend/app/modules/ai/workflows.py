"""AI workflows (master plan §7) with deterministic fallbacks.

Every workflow returns a :class:`Outcome` that says whether AI was used. When AI is not
configured, over quota or failing, the fallback runs instead and ``ai_error`` carries
the reason so the app can say so plainly instead of pretending.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any

from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.modules.accounts.models import Profile
from app.modules.documents import heuristics
from app.modules.documents.search import SearchDoc, best_snippet, bm25_search, is_relevant
from app.modules.modes.loader import Mode, Template, localized, localized_list
from app.modules.planning import topological_order

from . import prompts
from .gateway import PROMPT_VERSION, Gateway, TaskType
from .llm_schemas import BreakdownDraft, BriefDraft, DocInsight, PlanDraft, SupervisionDraft

MAX_DOC_CHARS = 60_000
MIN_ESTIMATE = 0.5
MAX_ESTIMATE = 40.0


@dataclass
class AIContext:
    db: Session
    user: Profile
    gateway: Gateway
    mode: Mode | None
    locale: str
    project_id: str | None = None


@dataclass
class Outcome[T]:
    value: T
    ai_used: bool
    ai_error: str | None = None
    model: str | None = None
    input_tokens: int = 0
    output_tokens: int = 0
    prompt_version: str = PROMPT_VERSION


def _try_ai(ctx: AIContext, fn) -> tuple[Any, str | None]:
    """Run an AI call; on a configuration or upstream error return ``(None, code)``."""
    if not ctx.gateway.enabled:
        return None, "ai_unavailable"
    try:
        return fn(), None
    except AppError as exc:
        if exc.code.startswith("ai_"):
            return None, exc.code
        raise
    except (ValidationError, json.JSONDecodeError):
        # The response did not match the schema; use the non-AI path instead of failing.
        return None, "ai_invalid_output"


def _l(locale: str, id_text: str, en_text: str) -> str:
    return en_text if locale == "en" else id_text


# --- Brief -----------------------------------------------------------------------------


def _documents_block(documents: list[dict]) -> str:
    parts, used = [], 0
    for doc in documents:
        text = doc["text"]
        room = MAX_DOC_CHARS - used
        if room <= 0:
            break
        clipped = text[:room]
        used += len(clipped)
        note = "" if len(clipped) == len(text) else "\n[... document continues; only the beginning is shown]"
        parts.append(f'<document title="{doc["title"]}" kind="{doc["kind"]}">\n{clipped}{note}\n</document>')
    return "\n\n".join(parts)


def extract_brief(ctx: AIContext, intake: dict, documents: list[dict], template: Template | None) -> Outcome[dict]:
    def call():
        content = (
            f"Intake form:\n{json.dumps(intake, ensure_ascii=False, indent=2)}\n\n"
            f"Documents:\n{_documents_block(documents) or '(none uploaded)'}"
        )
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.BRIEF,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.BRIEF),
            messages=[{"role": "user", "content": content}],
            output_format=BriefDraft,
        )

    result, error = _try_ai(ctx, call)
    if result is not None and result.parsed is not None:
        draft: BriefDraft = result.parsed
        brief = normalise_brief(
            {
                "goal": draft.goal,
                "deliverables": draft.deliverables,
                "requirements": [{"text": r.text} for r in draft.requirements],
                "important_dates": [{"label": d.label, "date": d.date} for d in draft.important_dates],
                "constraints": draft.constraints,
                "open_questions": [{"question": q, "answer": ""} for q in draft.open_questions],
            }
        )
        return Outcome(brief, True, None, result.model, result.input_tokens, result.output_tokens)
    return Outcome(fallback_brief(intake, documents, template, ctx.locale), False, error)


def fallback_brief(intake: dict, documents: list[dict], template: Template | None, locale: str) -> dict:
    """A brief from the intake form plus pattern matching over the documents."""
    rule_docs = [d for d in documents if d["kind"] in ("instruction", "proposal")] or documents
    requirements: list[str] = []
    dates: list[dict] = []
    for doc in rule_docs:
        requirements += heuristics.requirement_candidates(doc["text"])
        dates += heuristics.date_candidates(doc["text"])
    goal = intake.get("description") or ""
    if not goal:
        for doc in documents:
            if doc["kind"] == "proposal":
                goal = next(
                    (s for s in heuristics.sentences(doc["text"]) if re.search(r"\b(tujuan|bertujuan|aims?)\b", s, re.I)),
                    "",
                )
                if goal:
                    break
    hours = intake.get("weekly_hours")
    constraints = []
    if hours:
        constraints.append(_l(locale, f"{hours:g} jam per minggu", f"{hours:g} hours per week"))
    deliverables = localized_list(template.deliverables, locale) if template else []
    questions = localized_list(template.open_questions, locale) if template else []
    return normalise_brief(
        {
            "goal": goal or intake.get("title", ""),
            "deliverables": deliverables,
            "requirements": [{"text": r} for r in requirements],
            "important_dates": dates,
            "constraints": constraints,
            "open_questions": [{"question": q, "answer": ""} for q in questions],
        }
    )


def normalise_brief(brief: dict) -> dict:
    """Consistent shape; requirement codes renumbered R1, R2, ... in order."""
    seen: set[str] = set()
    requirements = []
    for item in brief.get("requirements", []):
        text = (item.get("text") if isinstance(item, dict) else str(item)).strip()
        if text and text.lower() not in seen:
            seen.add(text.lower())
            requirements.append({"code": f"R{len(requirements) + 1}", "text": text})
    dates = []
    for item in brief.get("important_dates", []):
        label = str(item.get("label", "")).strip()
        value = item.get("date")
        if label:
            dates.append({"label": label, "date": value if _is_iso_date(value) else None})
    questions = []
    for item in brief.get("open_questions", []):
        if isinstance(item, str):
            item = {"question": item, "answer": ""}
        if str(item.get("question", "")).strip():
            questions.append({"question": item["question"].strip(), "answer": str(item.get("answer", "")).strip()})
    return {
        "goal": str(brief.get("goal", "")).strip(),
        "deliverables": [s.strip() for s in brief.get("deliverables", []) if str(s).strip()],
        "requirements": requirements,
        "important_dates": dates,
        "constraints": [s.strip() for s in brief.get("constraints", []) if str(s).strip()],
        "open_questions": questions,
    }


def _is_iso_date(value: Any) -> bool:
    return isinstance(value, str) and bool(re.fullmatch(r"\d{4}-\d{2}-\d{2}", value))


def brief_as_text(brief: dict) -> str:
    lines = [f"Goal: {brief.get('goal', '')}"]
    if brief.get("deliverables"):
        lines.append("Deliverables: " + "; ".join(brief["deliverables"]))
    for req in brief.get("requirements", []):
        lines.append(f"Requirement {req['code']}: {req['text']}")
    for d in brief.get("important_dates", []):
        lines.append(f"Date: {d['label']} ({d.get('date') or 'no exact date'})")
    for c in brief.get("constraints", []):
        lines.append(f"Constraint: {c}")
    for q in brief.get("open_questions", []):
        if q.get("answer"):
            lines.append(f"Q: {q['question']} A: {q['answer']}")
    return "\n".join(lines)


# --- Plan ------------------------------------------------------------------------------


def validate_plan(draft: dict, requirement_codes: set[str]) -> list[str]:
    """Check a plan draft; unknown requirement refs are dropped silently (soft)."""
    errors: list[str] = []
    milestone_keys = [m["key"] for m in draft["milestones"]]
    if len(set(milestone_keys)) != len(milestone_keys):
        errors.append("milestone keys must be unique")
    task_keys = [t["key"] for t in draft["tasks"]]
    if len(set(task_keys)) != len(task_keys):
        errors.append("task keys must be unique")
    if not draft["tasks"]:
        errors.append("the plan has no tasks")
    for task in draft["tasks"]:
        if task["milestone"] not in milestone_keys:
            errors.append(f"task {task['key']} points to unknown milestone {task['milestone']}")
        if not MIN_ESTIMATE <= float(task["estimate_hours"]) <= MAX_ESTIMATE:
            errors.append(f"task {task['key']} estimate must be between 0.5 and 40 hours")
        for dep in task["depends_on"]:
            if dep not in task_keys:
                errors.append(f"task {task['key']} depends on unknown task {dep}")
        task["requirement_refs"] = [r for r in task.get("requirement_refs", []) if r in requirement_codes]
    if not errors:
        try:
            topological_order(task_keys, {t["key"]: t["depends_on"] for t in draft["tasks"]})
        except ValueError as exc:
            errors.append(str(exc))
    return errors


def _plan_to_dict(plan: PlanDraft) -> dict:
    return {
        "milestones": [{"key": m.key, "title": m.title} for m in plan.milestones],
        "tasks": [
            {
                "key": t.key,
                "milestone": t.milestone,
                "title": t.title,
                "estimate_hours": float(t.estimate_hours),
                "depends_on": list(t.depends_on),
                "optional": bool(t.optional),
                "definition_of_done": t.definition_of_done,
                "requirement_refs": list(t.requirement_refs),
            }
            for t in plan.tasks
        ],
        "assumptions": list(plan.assumptions),
        "questions": list(plan.questions),
    }


def draft_plan(
    ctx: AIContext, brief: dict, template: Template, weekly_hours: float, weeks_left: float
) -> Outcome[dict]:
    codes = {r["code"] for r in brief.get("requirements", [])}
    template_text = template_outline(template, ctx.locale)

    def call_once(messages):
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.PLAN,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.PLAN),
            messages=messages,
            output_format=PlanDraft,
        )

    def call():
        messages = [
            {
                "role": "user",
                "content": (
                    f"Brief:\n{brief_as_text(brief)}\n\n"
                    f"Mode template ({localized(template.name, 'en')}):\n{template_text}\n\n"
                    f"Capacity: about {weekly_hours:g} hours per week for about {weeks_left:.0f} weeks "
                    f"(roughly {weekly_hours * weeks_left:.0f} hours in total)."
                ),
            }
        ]
        first = call_once(messages)
        draft = _plan_to_dict(first.parsed) if first.parsed is not None else None
        errors = validate_plan(draft, codes) if draft else ["the response could not be parsed"]
        if not errors:
            return first, draft
        # One retry with the error messages, then the template (master plan §7).
        messages += [
            {"role": "assistant", "content": first.text or json.dumps(draft or {})},
            {"role": "user", "content": "The plan has these problems:\n- " + "\n- ".join(errors) + "\nReturn a corrected plan."},
        ]
        second = call_once(messages)
        draft = _plan_to_dict(second.parsed) if second.parsed is not None else None
        if draft and not validate_plan(draft, codes):
            second.input_tokens += first.input_tokens
            second.output_tokens += first.output_tokens
            return second, draft
        return None

    result, error = _try_ai(ctx, call)
    if result:
        response, draft = result
        return Outcome(draft, True, None, response.model, response.input_tokens, response.output_tokens)
    return Outcome(template_plan(template, ctx.locale, brief), False, error or "ai_invalid_plan")


def template_outline(template: Template, locale: str) -> str:
    lines = []
    for milestone in template.milestones:
        lines.append(f"{milestone.key}: {localized(milestone.title, locale)}")
        for task in milestone.tasks:
            deps = f" (after {', '.join(task.after)})" if task.after else ""
            optional = " [optional]" if task.optional else ""
            lines.append(f"  {task.key}: {localized(task.title, locale)}, {task.hours:g}h{deps}{optional}")
    return "\n".join(lines)


def template_plan(template: Template, locale: str, brief: dict) -> dict:
    """The mode template as a plan, with the brief's requirements linked to matching tasks.

    A requirement that matches no template task gets its own check task, so the
    requirement checklist never has an uncovered requirement.
    """
    milestones = [{"key": m.key, "title": localized(m.title, locale)} for m in template.milestones]
    tasks = []
    for milestone in template.milestones:
        for t in milestone.tasks:
            tasks.append(
                {
                    "key": t.key,
                    "milestone": milestone.key,
                    "title": localized(t.title, locale),
                    "estimate_hours": t.hours,
                    "depends_on": list(t.after),
                    "optional": t.optional,
                    "definition_of_done": localized(t.done, locale) if t.done else "",
                    "requirement_refs": [],
                }
            )
    search_docs = [SearchDoc(t["key"], t["title"]) for t in tasks if not t["optional"]]
    # Check tasks go before the last milestone (usually the defense), after the writing work.
    check_milestone = template.milestones[-2] if len(template.milestones) > 1 else template.milestones[-1]
    anchor = check_milestone.tasks[-1].key if check_milestone.tasks else None
    next_number = len(tasks) + 1
    for req in brief.get("requirements", []):
        hits = bm25_search(req["text"], search_docs, top_k=1)
        if hits and is_relevant(hits[0]):
            next(t for t in tasks if t["key"] == hits[0].id)["requirement_refs"].append(req["code"])
            continue
        key = f"T{next_number}"
        next_number += 1
        tasks.append(
            {
                "key": key,
                "milestone": check_milestone.key,
                "title": _l(locale, f"Pastikan syarat terpenuhi: {req['text']}", f"Make sure this is met: {req['text']}")[:300],
                "estimate_hours": 1.0,
                "depends_on": [anchor] if anchor else [],
                "optional": False,
                "definition_of_done": "",
                "requirement_refs": [req["code"]],
            }
        )
    return {"milestones": milestones, "tasks": tasks, "assumptions": [], "questions": []}


# --- Chat ------------------------------------------------------------------------------


@dataclass
class Passage:
    chunk_id: str
    document_id: str
    document_title: str
    page_start: int
    page_end: int
    heading_path: str
    text: str
    relevant: bool


@dataclass
class ChatAnswer:
    kind: str  # ai | general | extractive | not_found
    content: str
    citations: list[dict] = field(default_factory=list)


def _source_label(p: Passage) -> str:
    pages = f"p. {p.page_start}" if p.page_start == p.page_end else f"p. {p.page_start}-{p.page_end}"
    return f"{p.document_title}, {pages}"


def _paragraphs(text: str) -> list[str]:
    parts = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    return parts or [text.strip() or " "]


def answer_question(
    ctx: AIContext, question: str, passages: list[Passage], project_context: str, history: list[tuple[str, str]]
) -> Outcome[ChatAnswer]:
    relevant = [p for p in passages if p.relevant]

    def call():
        content: list[dict] = []
        for p in relevant:
            content.append(
                {
                    "type": "search_result",
                    "source": _source_label(p),
                    "title": p.document_title + (f" - {p.heading_path}" if p.heading_path else ""),
                    "content": [{"type": "text", "text": para} for para in _paragraphs(p.text)],
                    "citations": {"enabled": True},
                }
            )
        note = "" if relevant else "(No passage in the project documents matched this question.)\n"
        content.append({"type": "text", "text": note + question})
        messages = [{"role": role, "content": text} for role, text in history[-6:] if text]
        messages.append({"role": "user", "content": content})
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.CHAT,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.CHAT, project_context),
            messages=messages,
        )

    result, error = _try_ai(ctx, call)
    if result is not None:
        return Outcome(_map_citations(result.content, relevant), True, None, result.model, result.input_tokens, result.output_tokens)
    if relevant:
        citations = [
            {
                "number": i + 1,
                "document_id": p.document_id,
                "title": p.document_title,
                "page_start": p.page_start,
                "page_end": p.page_end,
                "heading_path": p.heading_path,
                "cited_text": best_snippet(p.text, question),
            }
            for i, p in enumerate(relevant[:3])
        ]
        return Outcome(ChatAnswer("extractive", "", citations), False, error)
    return Outcome(ChatAnswer("not_found", ""), False, error)


def _map_citations(content: list, relevant: list[Passage]) -> ChatAnswer:
    """Turn Claude's cited text blocks into answer text with numbered source markers."""
    sources: dict[tuple, int] = {}
    citations: list[dict] = []
    parts: list[str] = []
    for block in content:
        if getattr(block, "type", None) != "text":
            continue
        parts.append(block.text)
        markers = []
        for cite in getattr(block, "citations", None) or []:
            if getattr(cite, "type", None) != "search_result_location":
                continue
            index = cite.search_result_index
            if not 0 <= index < len(relevant):
                continue
            passage = relevant[index]
            key = (passage.chunk_id, cite.start_block_index, cite.end_block_index)
            if key not in sources:
                sources[key] = len(citations) + 1
                citations.append(
                    {
                        "number": sources[key],
                        "document_id": passage.document_id,
                        "title": passage.document_title,
                        "page_start": passage.page_start,
                        "page_end": passage.page_end,
                        "heading_path": passage.heading_path,
                        "cited_text": cite.cited_text[:700],
                    }
                )
            if sources[key] not in markers:
                markers.append(sources[key])
        if markers:
            parts.append("".join(f" [{n}]" for n in markers))
    text = "".join(parts).strip()
    return ChatAnswer("ai" if citations else "general", text, citations)


# --- Task helper ------------------------------------------------------------------------


def _round_half(hours: float) -> float:
    return max(MIN_ESTIMATE, round(hours * 2) / 2)


def breakdown_task(ctx: AIContext, title: str, estimate: float, description: str, context: str) -> Outcome[dict]:
    def call():
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.TASK_HELPER,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.TASK_HELPER),
            messages=[
                {
                    "role": "user",
                    "content": f"Task: {title}\nEstimate: {estimate:g} hours\nDetails: {description or '-'}\n\nProject:\n{context}",
                }
            ],
            output_format=BreakdownDraft,
        )

    result, error = _try_ai(ctx, call)
    if result is not None and result.parsed is not None:
        draft: BreakdownDraft = result.parsed
        subtasks = [
            {"title": s.title.strip()[:300], "estimate_hours": min(_round_half(s.estimate_hours), 16.0)}
            for s in draft.subtasks
            if s.title.strip()
        ]
        if subtasks:
            return Outcome(
                {"subtasks": subtasks, "first_step": draft.first_step.strip()},
                True,
                None,
                result.model,
                result.input_tokens,
                result.output_tokens,
            )
        error = "ai_invalid_output"
    return Outcome(fallback_breakdown(title, estimate, ctx.locale), False, error)


def fallback_breakdown(title: str, estimate: float, locale: str) -> dict:
    parts = [
        (0.1, "Tentukan hasil akhir yang dicari", "Define the result you need"),
        (0.25, "Kumpulkan bahan dan referensi yang dibutuhkan", "Gather the material and references you need"),
        (0.45, "Kerjakan bagian inti", "Do the core of the work"),
        (0.2, "Periksa dan rapikan hasilnya", "Review and tidy the result"),
    ]
    subtasks = [
        {"title": f"{_l(locale, id_t, en_t)}: {title}"[:300], "estimate_hours": _round_half(estimate * share)}
        for share, id_t, en_t in parts
    ]
    return {"subtasks": subtasks, "first_step": first_step_text(title, locale)}


def first_step_text(title: str, locale: str) -> str:
    return _l(
        locale,
        f'Pasang timer 25 menit. Tulis tiga poin tentang apa yang harus dihasilkan "{title}", lalu kerjakan poin yang paling kecil.',
        f'Set a 25-minute timer. Write three bullet points about what "{title}" must produce, then start on the smallest one.',
    )


# --- Supervision log --------------------------------------------------------------------

_REVISION = re.compile(
    r"\b(tambah|tambahkan|perbaiki|revisi|ganti|hapus|lengkapi|perjelas|ubah|sesuaikan|cek|periksa|"
    r"add|fix|revise|replace|remove|complete|clarify|change|update|check)\w*\b",
    re.IGNORECASE,
)


def supervision_proposals(ctx: AIContext, note: str, context: str) -> Outcome[dict]:
    def call():
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.SUPERVISION,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.SUPERVISION, context),
            messages=[{"role": "user", "content": f"<supervision_notes>\n{note}\n</supervision_notes>"}],
            output_format=SupervisionDraft,
        )

    result, error = _try_ai(ctx, call)
    if result is not None and result.parsed is not None:
        draft: SupervisionDraft = result.parsed
        return Outcome(
            {
                "memories": [{"kind": m.kind, "content": m.content.strip()} for m in draft.memories if m.content.strip()],
                "revision_tasks": [
                    {"title": r.title.strip()[:300], "estimate_hours": min(_round_half(r.estimate_hours), 16.0)}
                    for r in draft.revision_tasks
                    if r.title.strip()
                ],
            },
            True,
            None,
            result.model,
            result.input_tokens,
            result.output_tokens,
        )
    return Outcome(fallback_supervision(note), False, error)


def fallback_supervision(note: str) -> dict:
    items: list[str] = []
    for raw in note.splitlines():
        line = re.sub(r"^\s*(?:[-*•]|\d+[.)])\s*", "", raw).strip()
        if line:
            items.append(line)
    if len(items) <= 1:
        items = heuristics.sentences(note)
    revisions, memories = [], []
    for item in items:
        if _REVISION.search(item):
            revisions.append({"title": item[:300], "estimate_hours": 2.0})
        else:
            memories.append({"kind": "feedback", "content": item})
    return {"memories": memories, "revision_tasks": revisions}


# --- Re-plan and weekly review explanations ----------------------------------------------


def explain_replan(ctx: AIContext, options: list[dict]) -> Outcome[list[str] | None]:
    def call():
        facts = "\n".join(f"{i + 1}. {json.dumps(o, ensure_ascii=False)}" for i, o in enumerate(options))
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.REPLAN,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.REPLAN),
            messages=[{"role": "user", "content": f"Options:\n{facts}"}],
        )

    result, error = _try_ai(ctx, call)
    if result is None:
        return Outcome(None, False, error)
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", result.text) if p.strip()]
    cleaned = [re.sub(r"^\s*\d+[.)]\s*", "", p) for p in paragraphs]
    if len(cleaned) != len(options):
        return Outcome(None, False, "ai_invalid_output")
    return Outcome(cleaned, True, None, result.model, result.input_tokens, result.output_tokens)


def weekly_review_text(ctx: AIContext, facts: dict) -> Outcome[str | None]:
    def call():
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.WEEKLY,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.WEEKLY),
            messages=[{"role": "user", "content": json.dumps(facts, ensure_ascii=False, default=str)}],
        )

    result, error = _try_ai(ctx, call)
    if result is None:
        return Outcome(None, False, error)
    return Outcome(result.text.strip(), True, None, result.model, result.input_tokens, result.output_tokens)


# --- Document insight -------------------------------------------------------------------


def document_insight(ctx: AIContext, filename: str, text: str, chunk_texts: list[str]) -> Outcome[dict]:
    def call():
        return ctx.gateway.run(
            ctx.db,
            user=ctx.user,
            project_id=ctx.project_id,
            task_type=TaskType.SUMMARY,
            system=prompts.system_blocks(ctx.mode, ctx.locale, prompts.DOC_INSIGHT),
            messages=[{"role": "user", "content": f'<document filename="{filename}">\n{text[:MAX_DOC_CHARS]}\n</document>'}],
            output_format=DocInsight,
        )

    result, error = _try_ai(ctx, call)
    if result is not None and result.parsed is not None:
        d: DocInsight = result.parsed
        meta = {k: v for k, v in {"authors": d.authors, "year": d.year, "doi": d.doi}.items() if v}
        return Outcome(
            {"kind": d.kind, "title": d.title.strip() or filename, "summary": d.summary.strip(), "metadata": meta},
            True,
            None,
            result.model,
            result.input_tokens,
            result.output_tokens,
        )
    return Outcome(
        {
            "kind": heuristics.classify(filename, text),
            "title": heuristics.guess_title(filename, text),
            "summary": heuristics.extractive_summary(chunk_texts),
            "metadata": heuristics.metadata(text),
        },
        False,
        error,
    )
