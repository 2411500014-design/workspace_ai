"""The one-tap sample project: real documents, brief, accepted plan, progress and a pending suggestion."""

import pytest

from app.modules.documents.heuristics import classify

from .conftest import TODAY


@pytest.mark.parametrize("locale", ["id", "en"])
def test_sample_project_is_a_complete_working_project(client, locale):
    response = client.post("/v1/projects/sample", json={"locale": locale})
    assert response.status_code == 201, response.text
    project = response.json()
    pid = project["id"]
    assert project["has_plan"] is True
    assert project["task_count"] >= 20
    assert project["title"].startswith("Contoh:" if locale == "id" else "Sample:")
    assert project["deadline"] > TODAY.isoformat()

    docs = client.get(f"/v1/projects/{pid}/documents").json()
    assert sorted(d["kind"] for d in docs) == ["instruction", "journal"]
    assert all(d["status"] == "ready" for d in docs)

    brief = client.get(f"/v1/projects/{pid}/brief").json()
    assert brief["version"] == 1
    texts = " ".join(r["text"] for r in brief["content"]["requirements"])
    assert ("20 referensi" if locale == "id" else "20 references") in texts
    assert "IEEE" in texts
    assert len(brief["content"]["important_dates"]) == 3

    plan = client.get(f"/v1/projects/{pid}/plan").json()
    statuses = {t["key"]: t["status"] for t in plan["tasks"]}
    assert statuses["T1"] == "done"
    assert statuses["T2"] == "in_progress"
    first_title = next(t["title"] for t in plan["tasks"] if t["key"] == "T1")
    # Task titles follow the requested language.
    indonesian = "Kumpulkan 20 sampai 25 jurnal yang relevan"
    assert (first_title == indonesian) == (locale == "id")

    pending = [s for s in client.get(f"/v1/projects/{pid}/suggestions").json() if s["status"] == "pending"]
    supervision = [s for s in pending if s["meta"].get("origin") == "supervision"]
    assert supervision, pending
    assert any(op["entity"] == "task" for op in supervision[0]["ops"])

    today = client.get("/v1/me/today").json()
    # Day one already has something to do: the task in progress.
    assert [t["key"] for t in today["focus"]] == ["T2"]
    summary = next(p for p in today["projects"] if p["id"] == pid)
    assert summary["health"] is not None
    assert summary["pending_suggestions"] >= 1

    notes = client.get(f"/v1/projects/{pid}/notes", params={"kind": "supervision"}).json()
    assert len(notes) == 1

    # It is an ordinary project: it can be deleted like any other.
    assert client.delete(f"/v1/projects/{pid}").status_code == 204
    assert all(p["id"] != pid for p in client.get("/v1/projects").json())


def test_samples_can_be_created_again(client):
    first = client.post("/v1/projects/sample", json={}).json()
    second = client.post("/v1/projects/sample", json={}).json()
    assert first["id"] != second["id"]
    assert first["title"].startswith("Contoh:")


def test_a_guideline_that_mentions_supervision_is_still_a_guideline():
    text = "PANDUAN PENULISAN SKRIPSI\nProgram Studi Informatika\n1. Setiap bab wajib dikonsultasikan dalam bimbingan."
    assert classify("panduan.pdf", text) == "instruction"
    assert classify("catatan.txt", "Catatan bimbingan 12 Oktober\n- Perbaiki Bab 2") == "supervision"


def test_health_lists_lan_addresses_in_local_mode(client):
    health = client.get("/v1/health").json()
    assert isinstance(health["lan_urls"], list)
    assert all(url.startswith("http://") for url in health["lan_urls"])
    assert isinstance(health["lan_listening"], bool)
    assert isinstance(health["web_app"], bool)


def test_accepts_connections_tells_a_listening_port_from_a_closed_one():
    import socket

    from app.core.network import accepts_connections

    with socket.socket() as server:
        server.bind(("127.0.0.1", 0))
        server.listen()
        port = server.getsockname()[1]
        assert accepts_connections("127.0.0.1", port)
    assert not accepts_connections("127.0.0.1", port)


def test_a_started_task_stays_in_focus_before_its_planned_start(client):
    from .conftest import new_project

    pid = new_project(client)["id"]
    suggestion = client.post(f"/v1/projects/{pid}/plan/generate").json()
    client.post(f"/v1/suggestions/{suggestion['id']}/apply", json={})
    tasks = {t["key"]: t for t in client.get(f"/v1/projects/{pid}/plan").json()["tasks"]}
    later = next(t for t in tasks.values() if t["scheduled_start"] and t["scheduled_start"] > TODAY.isoformat() and not t["deferred"])

    def today_keys() -> list[str]:
        today = client.get("/v1/me/today").json()
        return [t["key"] for t in today["focus"] + today["more_today"]]

    assert later["key"] not in today_keys()
    client.patch(f"/v1/tasks/{later['id']}", json={"status": "in_progress"})
    assert later["key"] in today_keys()


@pytest.mark.parametrize(
    ("locale", "question", "expected"),
    [("en", "How many references do I need?", "at least 20 references"), ("id", "Berapa banyak referensi yang perlu saya pakai?", "minimal 20 referensi")],
)
def test_without_ai_a_plain_question_finds_the_guideline(client, locale, question, expected):
    pid = client.post("/v1/projects/sample", json={"locale": locale}).json()["id"]
    answer = client.post(f"/v1/projects/{pid}/chat", json={"question": question}).json()["answer"]
    assert answer["kind"] in ("extractive", "closest")
    assert expected in answer["citations"][0]["cited_text"]
