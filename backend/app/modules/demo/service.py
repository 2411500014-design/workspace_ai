"""A ready-made sample project, so a new student can see Purnara working in one tap.

It goes through the same code paths as a real project: documents are processed, a
brief is drafted and saved, a plan is generated and accepted, some work is done, and
a supervision note turns into a suggestion waiting for review. Nothing is faked in
the database; the sample is an ordinary project the student can edit or delete.
"""

from __future__ import annotations

from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.accounts.models import Profile
from app.modules.ai.chat import supervision_suggestion
from app.modules.ai.gateway import Gateway
from app.modules.ai.suggestions import apply_suggestion
from app.modules.ai.workflows import AIContext, extract_brief
from app.modules.documents import service as documents
from app.modules.modes.loader import get_mode
from app.modules.projects import service as projects
from app.modules.projects.models import Project
from app.modules.tasks import service as tasks
from app.modules.tasks.models import Task
from app.modules.tasks.plan_service import generate_plan

MONTHS = {
    "id": ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"],
    "en": ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
}


def _date(locale: str, day: date) -> str:
    return f"{day.day} {MONTHS[locale][day.month - 1]} {day.year}"


def _texts(locale: str, today: date) -> dict:
    proposal_due, seminar, defense = today + timedelta(days=30), today + timedelta(days=60), today + timedelta(days=140)
    if locale == "en":
        return {
            "title": "Sample: NPC decision-making for an RTS game",
            "description": "Compare MCTS and Utility AI for NPC decision-making in real-time strategy games.",
            "deadline": defense,
            "guideline_name": "thesis_guidelines.txt",
            "guideline": (
                "THESIS WRITING GUIDELINES\n"
                "Informatics Study Programme\n\n"
                "General rules\n"
                "1. The thesis must cite at least 20 references from the last 5 years.\n"
                "2. Citations must follow the IEEE style.\n"
                "3. The manuscript must be at least 40 pages, excluding appendices.\n"
                "4. Each chapter must be reviewed with the supervisor at least twice.\n\n"
                "Key dates\n"
                f"Proposal submission: {_date(locale, proposal_due)}\n"
                f"The proposal seminar takes place on {_date(locale, seminar)}\n"
                f"Final defense no later than {_date(locale, defense)}\n"
            ),
            "note": (
                "- Add 5 recent references to Chapter 2\n"
                "- Clarify the research questions in Chapter 1\n"
                "- Prepare a comparison table of MCTS and Utility AI\n"
                "- The supervisor prefers short paragraphs"
            ),
        }
    return {
        "title": "Contoh: Decision-making NPC untuk game RTS",
        "description": "Membandingkan MCTS dan Utility AI untuk pengambilan keputusan NPC di game strategi real-time.",
        "deadline": defense,
        "guideline_name": "panduan_skripsi.txt",
        "guideline": (
            "PANDUAN PENULISAN SKRIPSI\n"
            "Program Studi Informatika\n\n"
            "Ketentuan umum\n"
            "1. Skripsi wajib menggunakan minimal 20 referensi dari 5 tahun terakhir.\n"
            "2. Format sitasi harus mengikuti gaya IEEE.\n"
            "3. Naskah paling sedikit 40 halaman tidak termasuk lampiran.\n"
            "4. Setiap bab wajib dibahas dalam bimbingan minimal dua kali.\n\n"
            "Jadwal penting\n"
            f"Batas pengumpulan proposal: {_date(locale, proposal_due)}\n"
            f"Seminar proposal dilaksanakan pada {_date(locale, seminar)}\n"
            f"Sidang akhir paling lambat {_date(locale, defense)}\n"
        ),
        "note": (
            "- Tambahkan 5 referensi terbaru di Bab 2\n"
            "- Perjelas rumusan masalah di Bab 1\n"
            "- Siapkan tabel perbandingan MCTS dan Utility AI\n"
            "- Dosen lebih suka paragraf yang pendek"
        ),
    }


# Journals are usually in English whatever the student's language.
JOURNAL = (
    "Decision Making for NPCs in Real-Time Strategy Games\n"
    "Abstract\n"
    "This paper compares Behavior Trees, Utility AI and Monte Carlo Tree Search (MCTS) for non-player "
    "character decisions in real-time strategy games. doi: 10.5555/purnara.sample.2025\n"
    "Keywords: RTS, MCTS, Utility AI, game AI\n\n"
    "1. Introduction\n"
    "Real-time strategy games need fast decisions under uncertainty, with many units acting at once.\n\n"
    "2. Method\n"
    "We implement MCTS with a 50 ms budget per decision and compare it with a Utility AI baseline "
    "over 200 matches on three maps.\n"
    "MCTS explores possible futures through random playouts and keeps the most promising moves.\n\n"
    "3. Results\n"
    "MCTS won 68 percent of matches against the Utility AI baseline. Behavior Trees were the fastest "
    "but the least adaptive when the opponent changed strategy.\n\n"
    "4. Conclusion\n"
    "MCTS offers the best balance for tactical decisions, while Utility AI remains easier to tune.\n"
)


def create_sample_project(db: Session, user: Profile, gateway: Gateway, locale: str, today: date) -> Project:
    locale = "en" if locale == "en" else "id"
    text = _texts(locale, today)
    project = projects.create_project(
        db,
        user,
        {
            "mode": "academic",
            "template": "skripsi",
            "title": text["title"],
            "description": text["description"],
            "target": "",
            "deadline": text["deadline"],
            "hours_by_weekday": [2, 2, 2, 2, 2, 3, 0],
            "blocked_dates": [],
            "buffer_pct": 0.15,
        },
        today,
    )
    ctx = AIContext(db=db, user=user, gateway=gateway, mode=get_mode("academic"), locale=locale, project_id=project.id)

    # Documents: the lecturer's guideline and one journal paper, processed right away.
    for name, content in ((text["guideline_name"], text["guideline"]), ("mcts_rts_2025.txt", JOURNAL)):
        document = documents.upload(db, project, name, "text/plain", content.encode("utf-8"))
        documents.process_now(db, document, user, project, gateway)

    # Brief: drafted from the documents (AI when available, rules otherwise), then saved.
    mode = get_mode(project.mode)
    template = mode.template(project.template) if mode else None
    intake = {
        "title": project.title,
        "description": project.description,
        "target": project.target,
        "deadline": project.deadline.isoformat(),
        "weekly_hours": sum(project.capacity["hours_by_weekday"]),
        "template": project.template,
    }
    brief = extract_brief(ctx, intake, documents.ready_documents(db, project.id), template)
    projects.save_brief(db, project, brief.value, "ai" if brief.ai_used else "user")

    # Plan: generated and accepted, exactly as in onboarding.
    plan = generate_plan(db, ctx, project, today)
    apply_suggestion(db, project, plan, None, today)

    # Some work already done, so Today, the board and progress have something to show.
    ordered = sorted(
        db.scalars(select(Task).where(Task.project_id == project.id)),
        key=lambda t: int(t.key[1:]) if t.key[1:].isdigit() else 10_000,
    )
    if ordered:
        tasks.update_task(db, project, ordered[0], {"status": "done", "actual_hours": ordered[0].estimate_hours})
    if len(ordered) > 1:
        tasks.update_task(db, project, ordered[1], {"status": "in_progress"})

    # A supervision meeting whose revisions wait as a suggestion to review.
    note = projects.add_note(db, project, "supervision", text["note"], today - timedelta(days=1))
    supervision_suggestion(db, ctx, project, note, today)

    db.flush()
    return project
