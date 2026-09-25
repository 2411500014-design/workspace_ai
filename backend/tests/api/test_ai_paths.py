"""AI paths with a fake gateway: no network, no cost, same plumbing as production."""

from types import SimpleNamespace

import jwt

from app.core.errors import AppError
from app.modules.ai.gateway import TaskType
from app.modules.ai.llm_schemas import BriefDraft, LlmDate, LlmMilestone, LlmRequirement, LlmTask, PlanDraft
from tests.fixtures import JOURNAL_PAGES, make_pdf

from .conftest import FakeGateway, new_project


def _plan(tasks):
    return PlanDraft(
        milestones=[LlmMilestone(key="M1", title="Literatur"), LlmMilestone(key="M2", title="Penulisan")],
        tasks=[LlmTask(**t) for t in tasks],
        assumptions=["Prototipe dibuat dengan Unity"],
        questions=["Engine game apa yang dipakai?"],
    )


GOOD_TASKS = [
    dict(key="T1", milestone="M1", title="Kumpulkan jurnal", estimate_hours=6, depends_on=[], optional=False,
         definition_of_done="25 PDF terindeks", requirement_refs=["R1"]),
    dict(key="T2", milestone="M2", title="Tulis Bab 2", estimate_hours=12, depends_on=["T1"], optional=False,
         definition_of_done="Draf Bab 2", requirement_refs=["R9"]),
]


def test_ai_brief_and_valid_plan(make_client):
    gateway = FakeGateway()
    client = make_client(gateway)
    pid = new_project(client)["id"]

    gateway.queue_result(
        TaskType.BRIEF,
        parsed=BriefDraft(
            goal="Menguji model decision-making NPC",
            deliverables=["Proposal", "Bab 1-5"],
            requirements=[LlmRequirement(code="X7", text="Minimal 20 referensi 5 tahun terakhir")],
            important_dates=[LlmDate(label="Seminar proposal", date="2026-11-20"), LlmDate(label="Sidang", date="Maret")],
            constraints=["10 jam per minggu"],
            open_questions=["Metode pembanding apa?"],
        ),
    )
    draft = client.post(f"/v1/projects/{pid}/brief/extract").json()
    assert draft["ai_used"] is True
    content = draft["content"]
    assert content["requirements"] == [{"code": "R1", "text": "Minimal 20 referensi 5 tahun terakhir"}]
    assert content["important_dates"][1]["date"] is None  # "Maret" is not an ISO date
    client.put(f"/v1/projects/{pid}/brief", json={"content": content})

    gateway.queue_result(TaskType.PLAN, parsed=_plan(GOOD_TASKS), text="{}")
    suggestion = client.post(f"/v1/projects/{pid}/plan/generate").json()
    assert suggestion["ai_used"] is True
    assert suggestion["meta"]["questions"] == ["Engine game apa yang dipakai?"]
    task_ops = [op for op in suggestion["ops"] if op["entity"] == "task"]
    # Unknown requirement refs (R9) are dropped instead of failing the plan.
    assert task_ops[1]["fields"]["requirement_refs"] == []
    assert gateway.calls[-1]["output_format"] is PlanDraft

    client.post(f"/v1/suggestions/{suggestion['id']}/apply", json={})
    plan = client.get(f"/v1/projects/{pid}/plan").json()
    assert [t["source"] for t in plan["tasks"]] == ["ai", "ai"]
    usage = client.get("/v1/me").json()["quota"]
    assert usage["used"] == 2400


def test_invalid_ai_plan_is_retried_once_then_replaced_by_the_template(make_client):
    gateway = FakeGateway()
    client = make_client(gateway)
    pid = new_project(client)["id"]
    cyclic = [dict(GOOD_TASKS[0], depends_on=["T2"]), GOOD_TASKS[1]]
    too_big = [dict(GOOD_TASKS[0], estimate_hours=90), GOOD_TASKS[1]]
    gateway.queue_result(TaskType.PLAN, parsed=_plan(cyclic), text="{}")
    gateway.queue_result(TaskType.PLAN, parsed=_plan(too_big), text="{}")

    suggestion = client.post(f"/v1/projects/{pid}/plan/generate").json()
    assert suggestion["ai_used"] is False
    assert suggestion["meta"]["ai_error"] == "ai_invalid_plan"
    assert len([op for op in suggestion["ops"] if op["entity"] == "task"]) == 21
    retry_message = gateway.calls[1]["messages"][-1]["content"]
    assert "cycle" in retry_message


def test_chat_citations_point_to_the_right_pages(make_client):
    gateway = FakeGateway()
    client = make_client(gateway)
    pid = new_project(client)["id"]
    # Document summaries use the light model; fail them so the heuristic summary is used.
    gateway.queue_result(TaskType.SUMMARY, error=AppError("ai_rate_limited", 503))
    client.post(f"/v1/projects/{pid}/documents", files={"file": ("mcts.pdf", make_pdf(JOURNAL_PAGES), "application/pdf")})

    cite = SimpleNamespace(
        type="search_result_location",
        search_result_index=0,
        start_block_index=0,
        end_block_index=1,
        cited_text="MCTS won 68 percent of matches against the Utility AI baseline.",
        source="mcts, p. 1-3",
        title="mcts",
    )
    content = [
        SimpleNamespace(type="text", text="Menurut jurnal, MCTS menang 68% melawan Utility AI.", citations=[cite]),
        SimpleNamespace(type="text", text=" Ini menunjukkan MCTS unggul untuk keputusan taktis.", citations=None),
    ]
    gateway.queue_result(TaskType.CHAT, content=content)
    answer = client.post(f"/v1/projects/{pid}/chat", json={"question": "Berapa persen kemenangan MCTS?"}).json()["answer"]
    assert answer["kind"] == "ai"
    assert answer["content"].startswith("Menurut jurnal, MCTS menang 68% melawan Utility AI. [1]")
    assert answer["citations"][0]["number"] == 1
    assert answer["citations"][0]["page_start"] == 1

    request = gateway.calls[-1]
    blocks = request["messages"][-1]["content"]
    assert blocks[0]["type"] == "search_result" and blocks[0]["citations"] == {"enabled": True}
    assert blocks[-1]["type"] == "text"
    assert request["system"][0]["cache_control"] == {"type": "ephemeral"}


def test_quota_exhaustion_falls_back_without_failing(make_client):
    gateway = FakeGateway()
    gateway.settings = gateway.settings.model_copy(update={"ai_monthly_token_quota": 1000})
    client = make_client(gateway)
    pid = new_project(client)["id"]
    # The first call (1200 tokens) spends this month's quota of 1000.
    gateway.queue_result(TaskType.PLAN, parsed=_plan(GOOD_TASKS), text="{}")
    plan = client.post(f"/v1/projects/{pid}/plan/generate").json()
    assert plan["ai_used"] is True
    client.post(f"/v1/suggestions/{plan['id']}/apply", json={})
    quota = client.get("/v1/me").json()["quota"]
    assert quota["used"] == 1200 and quota["limit"] == 1000

    # Every later AI feature falls back and says why, instead of failing.
    task = client.get(f"/v1/projects/{pid}/plan").json()["tasks"][0]
    help_ = client.post(f"/v1/tasks/{task['id']}/start-help").json()
    assert help_["ai_used"] is False
    assert help_["ai_error"] == "ai_quota_exhausted"
    assert help_["first_step"]


def test_supabase_tokens_isolate_users(make_client):
    secret = "test-secret-with-at-least-32-characters!"
    client = make_client(env={"PURNARA_AUTH_MODE": "supabase", "PURNARA_SUPABASE_JWT_SECRET": secret})

    def token(sub, email):
        return jwt.encode({"sub": sub, "email": email, "aud": "authenticated"}, secret, algorithm="HS256")

    alice = {"Authorization": f"Bearer {token('11111111-1111-4111-8111-111111111111', 'alice@test.id')}"}
    bob = {"Authorization": f"Bearer {token('22222222-2222-4222-8222-222222222222', 'bob@test.id')}"}

    assert client.get("/v1/projects").status_code == 401
    assert client.get("/v1/projects", headers={"Authorization": "Bearer nope"}).json()["error"]["code"] == "unauthenticated"
    project = client.post(
        "/v1/projects",
        headers=alice,
        json={"template": "makalah", "title": "Punya Alice", "deadline": "2027-01-01", "hours_by_weekday": [2] * 7},
    ).json()
    assert client.get("/v1/me", headers=alice).json()["email"] == "alice@test.id"
    assert client.get(f"/v1/projects/{project['id']}", headers=bob).status_code == 404
    assert client.get("/v1/projects", headers=bob).json() == []
    assert len(client.get("/v1/projects", headers=alice).json()) == 1
