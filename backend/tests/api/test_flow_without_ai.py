"""The whole adaptive cycle with no AI key: intake, brief, plan, work, fall behind, re-plan."""

from datetime import timedelta

from tests.fixtures import INSTRUCTION_TEXT, JOURNAL_PAGES, make_pdf

from .conftest import TODAY, new_project


def upload(client, project_id, name, data, mime="application/pdf"):
    response = client.post(f"/v1/projects/{project_id}/documents", files={"file": (name, data, mime)})
    assert response.status_code == 202, response.text
    return response.json()


def test_system_health_and_profile(client):
    health = client.get("/v1/health").json()
    assert health["status"] == "ok"
    assert health["ai_enabled"] is False
    me = client.get("/v1/me").json()
    assert me["locale"] == "id"
    assert me["ai_enabled"] is False
    assert me["quota"]["used"] == 0
    updated = client.patch("/v1/me", json={"locale": "en", "name": "Raka"}).json()
    assert updated["locale"] == "en" and updated["name"] == "Raka"


def test_modes_are_bilingual(client):
    modes = client.get("/v1/modes").json()
    academic = next(m for m in modes if m["id"] == "academic")
    skripsi = next(t for t in academic["templates"] if t["id"] == "skripsi")
    assert skripsi["name"] == {"id": "Skripsi", "en": "Undergraduate thesis"}
    assert skripsi["total_hours"] == 168  # 180 hours minus the optional journal article


def test_full_cycle(client):
    project = new_project(client)
    pid = project["id"]
    assert project["has_plan"] is False

    # --- documents -------------------------------------------------------------------
    doc = upload(client, pid, "panduan_skripsi.pdf", make_pdf(INSTRUCTION_TEXT.split("\n\n")))
    assert doc["status"] == "processing"
    doc = client.get(f"/v1/documents/{doc['id']}").json()
    assert doc["status"] == "ready", doc
    assert doc["kind"] == "instruction"
    assert doc["chunk_count"] >= 1
    assert doc["summary_ai"] is False
    journal = upload(client, pid, "mcts_rts.pdf", make_pdf(JOURNAL_PAGES))
    journal = client.get(f"/v1/documents/{journal['id']}").json()
    assert journal["kind"] == "journal"
    assert journal["metadata"]["doi"] == "10.1234/rts.2024.001"

    duplicate = client.post(
        f"/v1/projects/{pid}/documents", files={"file": ("again.pdf", make_pdf(JOURNAL_PAGES), "application/pdf")}
    )
    assert duplicate.status_code == 409
    assert duplicate.json()["error"]["code"] == "duplicate_document"

    # The instruction document proposes brief requirements instead of writing them directly.
    pending = client.get(f"/v1/projects/{pid}/suggestions").json()
    brief_update = next(s for s in pending if s["kind"] == "brief_update")
    assert any("20 referensi" in op["fields"]["text"] for op in brief_update["ops"])

    # --- brief (heuristic draft, then saved by the user) ---------------------------------
    draft = client.post(f"/v1/projects/{pid}/brief/extract").json()
    assert draft["ai_used"] is False and draft["ai_error"] == "ai_unavailable"
    content = draft["content"]
    assert any("IEEE" in r["text"] for r in content["requirements"])
    assert "2026-11-20" in {d["date"] for d in content["important_dates"]}
    assert content["open_questions"], "template questions are offered"
    content["open_questions"][0]["answer"] = "MCTS dibandingkan dengan Utility AI"
    saved = client.put(f"/v1/projects/{pid}/brief", json={"content": content, "source": "user"}).json()
    assert saved["version"] == 1
    codes = [r["code"] for r in saved["content"]["requirements"]]
    assert codes[:2] == ["R1", "R2"]
    # The saved brief already holds the document's requirements, so that proposal is answered.
    assert client.get(f"/v1/suggestions/{brief_update['id']}").json()["status"] == "superseded"

    # --- plan: template structure, dates from the scheduler ----------------------------------
    suggestion = client.post(f"/v1/projects/{pid}/plan/generate").json()
    assert suggestion["kind"] == "plan" and suggestion["ai_used"] is False
    assert suggestion["meta"]["ai_error"] == "ai_unavailable"
    assert suggestion["preview"]["feasibility"] == "feasible"
    assert suggestion["meta"]["uncovered_requirements"] == []
    task_ops = [op for op in suggestion["ops"] if op["entity"] == "task"]
    assert len(task_ops) >= 21

    again = client.post(f"/v1/projects/{pid}/plan/generate")
    assert again.status_code == 201  # replaces the pending draft
    assert client.get(f"/v1/suggestions/{suggestion['id']}").json()["status"] == "superseded"
    suggestion = again.json()

    applied = client.post(f"/v1/suggestions/{suggestion['id']}/apply", json={}).json()
    assert applied["status"] == "applied"
    assert client.post(f"/v1/suggestions/{suggestion['id']}/apply", json={}).status_code == 409
    assert client.post(f"/v1/projects/{pid}/plan/generate").json()["error"]["code"] == "plan_exists"

    plan = client.get(f"/v1/projects/{pid}/plan").json()
    assert plan["project"]["has_plan"] is True
    assert len(plan["milestones"]) == 8
    tasks = {t["key"]: t for t in plan["tasks"]}
    assert tasks["T1"]["scheduled_start"] == TODAY.isoformat()
    assert all(t["scheduled_end"] for t in plan["tasks"])
    assert tasks["T2"]["depends_on"] == [tasks["T1"]["id"]]
    assert any(t["is_critical"] for t in plan["tasks"])

    checklist = client.get(f"/v1/projects/{pid}/requirements").json()
    assert checklist and all(item["covered"] for item in checklist)

    # --- today and progress --------------------------------------------------------------------
    today = client.get("/v1/me/today").json()
    assert today["focus"][0]["key"] == "T1"
    assert len(today["focus"]) <= 3
    assert today["projects"][0]["has_plan"] is True
    assert today["projects"][0]["health"] == "on_track"

    health = client.get(f"/v1/projects/{pid}/health").json()
    assert health["status"] == "on_track"

    t1 = tasks["T1"]
    fetched = client.get(f"/v1/tasks/{t1['id']}").json()
    assert fetched["project_id"] == pid and fetched["key"] == "T1"
    assert client.get("/v1/tasks/missing").status_code == 404
    done = client.patch(f"/v1/tasks/{t1['id']}", json={"status": "done", "actual_hours": 7}).json()
    assert done["status"] == "done" and done["completed_at"]

    # --- falling behind: three weeks pass with nothing else done ----------------------------------
    client.clock.day = TODAY + timedelta(days=21)
    health = client.get(f"/v1/projects/{pid}/health").json()
    assert health["status"] in ("at_risk", "off_track")
    assert health["late_tasks"] >= 1
    notes = client.get("/v1/notifications").json()
    assert any(n["type"] == "health_drop" for n in notes)

    review = client.get(f"/v1/projects/{pid}/weekly-review").json()
    assert review["recommend_replan"] is True
    assert review["slipped"]
    assert review["summary"] is None and review["ai_used"] is False

    options = client.post(f"/v1/projects/{pid}/replan").json()
    kinds = [o["meta"]["option"] for o in options]
    assert "reschedule" in kinds
    reschedule = next(o for o in options if o["meta"]["option"] == "reschedule")
    assert reschedule["preview"]["changed_count"] > 0
    client.post(f"/v1/suggestions/{reschedule['id']}/apply", json={})
    for other in options:
        if other["id"] != reschedule["id"]:
            assert client.get(f"/v1/suggestions/{other['id']}").json()["status"] == "superseded"

    health = client.get(f"/v1/projects/{pid}/health").json()
    assert health["late_tasks"] == 0
    plan = client.get(f"/v1/projects/{pid}/plan").json()
    t2 = next(t for t in plan["tasks"] if t["key"] == "T2")
    assert t2["scheduled_start"] == client.clock.day.isoformat()


def test_chat_without_ai_returns_cited_passages(client):
    pid = new_project(client)["id"]
    upload(client, pid, "mcts_rts.pdf", make_pdf(JOURNAL_PAGES))
    answer = client.post(f"/v1/projects/{pid}/chat", json={"question": "Berapa persen kemenangan MCTS melawan Utility AI?"}).json()
    message = answer["answer"]
    assert message["kind"] == "extractive"
    first = message["citations"][0]
    assert first["page_start"] <= 3 <= first["page_end"]  # a short paper becomes one chunk
    assert "68 percent" in message["citations"][0]["cited_text"]
    assert answer["ai_error"] == "ai_unavailable"

    followup = client.post(
        f"/v1/projects/{pid}/chat", json={"question": "resep rendang padang", "thread_id": answer["thread"]["id"]}
    ).json()
    assert followup["answer"]["kind"] == "not_found"

    # Worded differently from the paper: only part of the question matches, so the closest
    # passage is shown as such instead of "not found".
    closest = client.post(
        f"/v1/projects/{pid}/chat", json={"question": "siapa pemenang turnamen catur MCTS", "thread_id": answer["thread"]["id"]}
    ).json()["answer"]
    assert closest["kind"] == "closest"
    assert 1 <= len(closest["citations"]) <= 2
    messages = client.get(f"/v1/threads/{answer['thread']['id']}/messages").json()
    assert [m["role"] for m in messages] == ["user", "assistant"] * 3

    liked = client.patch(f"/v1/messages/{message['id']}", json={"feedback": "up"}).json()
    assert liked["feedback"] == "up"


def test_supervision_log_and_task_breakdown_fallbacks(client):
    pid = new_project(client, template="makalah", deadline="2026-12-15")["id"]
    plan = client.post(f"/v1/projects/{pid}/plan/generate").json()
    client.post(f"/v1/suggestions/{plan['id']}/apply", json={})

    note = client.post(
        f"/v1/projects/{pid}/notes",
        json={
            "kind": "supervision",
            "meeting_date": "2026-10-05",
            "content": "- Tambahkan 5 referensi terbaru di bagian literatur\n- Perbaiki rumusan masalah\n- Metode sudah tepat",
        },
    ).json()
    suggestion = note["suggestion"]
    assert suggestion["meta"]["origin"] == "supervision"
    added = [op for op in suggestion["ops"] if op["entity"] == "task"]
    memories = [op for op in suggestion["ops"] if op["entity"] == "memory"]
    assert len(added) == 2 and len(memories) == 1

    # Accept only the first revision task.
    first_task_index = suggestion["ops"].index(added[0])
    partial = client.post(f"/v1/suggestions/{suggestion['id']}/apply", json={"op_indices": [first_task_index]}).json()
    assert partial["status"] == "partially_applied"
    titles = [t["title"] for t in client.get(f"/v1/projects/{pid}/plan").json()["tasks"]]
    assert "Tambahkan 5 referensi terbaru di bagian literatur" in titles
    assert "Perbaiki rumusan masalah" not in titles

    tasks = client.get(f"/v1/projects/{pid}/plan").json()["tasks"]
    target = next(t for t in tasks if t["key"] == "T4")
    help_ = client.post(f"/v1/tasks/{target['id']}/start-help").json()
    assert "25" in help_["first_step"] and help_["ai_used"] is False

    breakdown = client.post(f"/v1/tasks/{target['id']}/breakdown").json()
    assert breakdown["kind"] == "task_change" and len(breakdown["ops"]) == 4
    client.post(f"/v1/suggestions/{breakdown['id']}/apply", json={})
    plan = client.get(f"/v1/projects/{pid}/plan").json()
    children = [t for t in plan["tasks"] if t["parent_task_id"] == target["id"]]
    assert len(children) == 4
    assert all(c["scheduled_start"] for c in children)
    for child in children:
        client.patch(f"/v1/tasks/{child['id']}", json={"status": "done"})
    parent = next(t for t in client.get(f"/v1/projects/{pid}/plan").json()["tasks"] if t["id"] == target["id"])
    assert parent["status"] == "done"


def test_errors_are_codes(client):
    bad = client.post("/v1/projects", json={"template": "skripsi", "title": "", "deadline": "2027-01-01", "hours_by_weekday": [1]})
    assert bad.status_code == 422
    assert bad.json()["error"]["code"] == "validation_failed"
    past = client.post(
        "/v1/projects", json={"template": "skripsi", "title": "x", "deadline": "2026-01-01", "hours_by_weekday": [2] * 7}
    )
    assert past.json()["error"]["code"] == "deadline_in_past"
    assert client.get("/v1/projects/does-not-exist").json()["error"]["code"] == "not_found"

    pid = new_project(client)["id"]
    a = client.post(f"/v1/projects/{pid}/tasks", json={"title": "A", "estimate_hours": 2}).json()
    b = client.post(f"/v1/projects/{pid}/tasks", json={"title": "B", "estimate_hours": 2, "depends_on": [a["id"]]}).json()
    cycle = client.patch(f"/v1/tasks/{a['id']}", json={"depends_on": [b["id"]]})
    assert cycle.status_code == 422 and cycle.json()["error"]["code"] == "dependency_cycle"

    unsupported = client.post(f"/v1/projects/{pid}/documents", files={"file": ("photo.png", b"\x89PNG", "image/png")})
    assert unsupported.json()["error"]["code"] == "unsupported_file_type"


def test_export_and_account_deletion(client):
    pid = new_project(client)["id"]
    upload(client, pid, "mcts_rts.pdf", make_pdf(JOURNAL_PAGES))
    export = client.get("/v1/me/export").json()
    assert export["projects"][0]["id"] == pid
    assert export["documents"] and export["briefs"] == []
    assert client.delete("/v1/me").status_code == 204
    # Local mode recreates an empty local user on the next request.
    assert client.get("/v1/projects").json() == []


def test_serves_the_built_web_app_next_to_the_api(make_client, tmp_path):
    web = tmp_path / "web"
    web.mkdir()
    (web / "index.html").write_text("<title>Purnara</title>", encoding="utf-8")
    client = make_client(env={"PURNARA_WEB_DIR": str(web)})
    page = client.get("/")
    assert "Purnara" in page.text
    assert page.headers["cache-control"] == "no-cache"  # a rebuilt app shows up on reload
    assert client.get("/v1/health").json()["status"] == "ok"


def test_without_a_web_build_only_the_api_answers(make_client, tmp_path):
    client = make_client(env={"PURNARA_WEB_DIR": str(tmp_path / "missing")})
    assert client.get("/").status_code == 404
    assert client.get("/v1/health").status_code == 200
