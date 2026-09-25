# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

The primary user is an Indonesian final-year undergraduate (S1 or D4, semester 7 and up) writing a *skripsi* or *tugas akhir* on their own. Their *sidang* (thesis defense) is 3 to 9 months away, they can give it roughly 10 hours a week, and they are supervised by one or two lecturers (*dosen pembimbing*).

Their job: know what to work on today and whether they are still on track, so the thesis finishes without a last-minute panic. They also need a lecturer's revisions to land in the plan instead of getting lost in WhatsApp, and they need to ask questions across the papers and guidelines they have collected and get answers with sources.

The reference persona in the vault is Raka, semester 7 Informatika, writing about AI decision-making for NPCs in an RTS game. He is fictional and exists for planning, not as a real user.

English-language users are **people outside Indonesia** (decided 2026-09-25). Later segments, in order: students doing group coursework (*tugas besar*), researchers and master's students, then Developer, Work and Personal modes. None of these is in scope for the MVP.

## Product Purpose

Purnara, from *purna* ("complete, finished"), turns a big project into a living plan and keeps it true until the project is done. It reads the student's own documents, drafts a brief and a plan through to the defense, says what to do today, tracks progress, and proposes adjustments when the student falls behind or a lecturer asks for revisions.

Success for a student: they always know the next step, reach the proposal seminar (*seminar proposal*, *sempro*) on schedule, and finish without panic at the end. Success for the product: students still follow their plan weeks later. That is the Phase 0 hypothesis being tested; it is not a result yet.

## Positioning

Task managers (Todoist, Trello, Notion) store tasks but do not build a plan from the content of the student's documents. AI schedulers (Motion, Reclaim) arrange calendars without knowledge of academic workflows. General chat assistants answer and write, but do not keep a plan or watch progress. Research tools (NotebookLM, Elicit, Zotero) answer questions about sources but do not manage a timeline.

Purnara's mechanism combines these:
- the plan comes from the student's own proposal and lecturer guidelines;
- deterministic code computes dates, capacity, the critical path and health;
- the AI proposes changes as diffs that the student accepts in full, in part, or not at all;
- it is built on the Indonesian academic workflow: Bab 1 to 5, *bimbingan*, *sempro*, *sidang*.

## Operating Context

- **Inputs** are the student's own files: the thesis proposal, the lecturer's or study programme's writing guidelines, journal papers (often mixed Indonesian and English), and notes from supervision meetings. Formats are PDF, DOCX, TXT and MD, up to 20 MB and 300 pages.
- **Rhythms:**
  - a daily check of what to do today;
  - supervision meetings that produce revisions;
  - a weekly review;
  - milestones: proposal submission, *seminar proposal*, the drafts of Bab 1 to 5, and the *sidang*.
- **Typical setting:** a student working alone, around lectures and exams (UTS, UAS), on a laptop and a phone.
- **Hosting:** at this stage the product runs on the student's own computer. Phones reach it over the same Wi-Fi.

## Capabilities and Constraints

**Built (first version, 2026-09-25):**
- **Project setup:** six steps, from project type to plan preview.
- **Brief and requirements:** a versioned brief and a checklist of the lecturer's requirements.
- **Plan:** views as a list, a board and a timeline, plus task detail with dependencies.
- **Daily focus:** Today shows at most three focus tasks, marks a task done with one tap, and offers "help me start".
- **Progress:** project health with reasons, re-plan options (reschedule, add hours, reduce scope, move the deadline), and suggestions reviewed as diffs.
- **Sources:** a document library, and a project assistant that answers with page citations.
- **Supervision and review:** a supervision log that turns notes into proposed tasks, and a weekly review.
- **Settings:** language, theme and server address, data export, and account deletion.

**Constraints future work must preserve:**
- **Two languages.** Every user-facing string exists in Indonesian and English. The Indonesian version of legal text (privacy policy, consent) is the reference.
- **AI proposes, the user decides.** The AI never changes a plan directly.
- **Code does the arithmetic.** Dates, capacity, the critical path and the health score come from deterministic code, never from the language model.
- **AI is optional.** Every AI feature has a clearly labelled version that works without it, and the whole product runs locally without paid services (ADR-0002).
- **Documents stay contained.** Retrieval is always filtered by project, and text from uploaded documents is data, never instructions. LLM API keys stay on the server.
- **Academic integrity.** The AI is a guide, not a ghostwriter. It explains, structures and gives feedback. It does not write submission-ready chapters, invent references or data, or help evade plagiarism checks.
- **Privacy.** UU PDP and PP 33/2026 apply; PP 33/2026 is fully in force from 16 Jan 2027, before the closed beta. The product must offer data export and account deletion, and must disclose that the LLM provider processes data outside Indonesia.
- **Adaptive platform.** The Flutter app currently uses one Material 3 design on web, Android and desktop. The recorded direction is to adapt per operating system: Material 3 on Android, Apple's Human Interface Guidelines on iPhone and iPad. That adaptation is not built yet.

**Terminology:** *skripsi*, *tugas akhir* (TA), *seminar proposal* (*sempro*), *sidang*, *bimbingan*, *dosen pembimbing*, brief, plan (*rencana*), suggestion (*usulan*), critical path (*jalur kritis*). The health states are *Sesuai jadwal* (on track), *Perlu perhatian* (needs attention) and *Tertinggal* (behind).

**Undecided:**
- **International audience.** Following from the English audience being outside Indonesia:
  - which international thesis structures to support (chapters, proposal defense, viva);
  - how Indonesian academic terms appear in the English UI;
  - which currency and payment channels to offer, since pricing is planned in rupiah through Midtrans or Xendit.
- **Pricing.** Freemium plus a one-off *Paket Skripsi*; all figures are hypotheses to be tested in the beta.
- **English at the beta.** Whether the English text must be complete for the closed beta starting 1 Feb 2027.

## Brand Commitments

- **Name:** Purnara, chosen 2026-09-24 after the working name Rampung clashed with a registered trademark. Only the GitHub name is secured so far. The domain and a trademark registration wait for funding.
- **Voice:** plain and practical in both languages, and neutral when a student falls behind. It offers a way to recover, never blame. Controls name their action.
- **Mark:** a P whose bowl is a closed ring (*purna*, "complete"), white on a teal tile. It stays the same in light and dark themes. The in-app mark and every platform icon come from one geometry (`app/tool/make_icons.py`).

## Evidence on Hand

- **Plan:** a 43-page master plan (`docs/Master Plan AI Academic Workspace.pdf`) and its knowledge graph (`graphify-out/`).
- **Validation material:** a hypothesis page and interview guides for students and lecturers (`Purnara Brain/Validasi/`). Phase 0 validation starts 28 Sep 2026. No interview has been done yet.
- **Product preview:** a real capture of the Today screen (`app/tool/og-preview.png`) and the link-preview image (`app/web/icons/og-image.png`).
- **Sample content:** sample documents in the backend tests (`backend/tests/fixtures.py`). They are fictional.

**Absent, never to be fabricated:** real users, testimonials, usage or outcome numbers, partner universities, named advisors, press, and validated prices.

## Product Principles

1. **The student decides.** Every plan change arrives as a reviewable proposal, and nothing changes silently.
2. **Grounded in their own material.** Plans and answers come from the student's documents, with page references. When the information is not there, say so.
3. **Code computes, AI explains.** Numbers the student plans their life around must be deterministic and testable.
4. **A guide, not a ghostwriter.** Help the student think and plan; the writing stays theirs.
5. **Recovery without judgement.** Falling behind is normal. Show the options calmly and let the student choose.

## Accessibility & Inclusion

The current implementation targets WCAG AA contrast for text and controls, and 48 dp minimum touch targets. It honours the operating system's reduced-motion setting, labels controls for screen readers, never relies on colour alone for status, and supports light and dark themes. Layouts must survive the length differences between Indonesian and English. No further requirement has been set.
