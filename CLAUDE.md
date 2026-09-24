# Rampung

Rampung ("done") is an AI project workspace for Indonesian final-year students (skripsi, TA, research). It is a Flutter app, web first. As of 2026-09-24 it is in the planning stage.

## Second brain

- The project vault is `Rampung Brain/` (Obsidian vault name **Rampung Brain**). Start at `Rampung Brain/Rampung.md`.
- Before answering questions about scope, architecture, decisions or the plan, read the relevant note there. The source plan is `docs/Master Plan AI Academic Workspace.pdf`. Its knowledge graph is in `graphify-out/`; from this folder, run `graphify query "<question>"`.
- After meaningful work:
  - Add a dated line to `Rampung Brain/Riwayat.md`.
  - Update the notes affected, including their `updated:` field.
  - Put a new decision in `Rampung Brain/Keputusan/K-00N <title>.md`, using `Templates/Keputusan.md`, and add a row to `Log Keputusan.md`.
  - Put anything still undecided in `Pertanyaan Terbuka.md`.
- Vault notes are written in Indonesian. If a note and the code disagree, the code is right; fix the note.
- The cross-project brain at `D:\GuardID\Obsidian` holds only a summary, in `Projects/Rampung.md`. Update it after milestones.

## Non-negotiables

- **Two languages.** Every user-facing string exists in both `id` and `en` (Flutter gen-l10n, ARB files). Never hardcode UI text. API errors are sent as codes and translated in the client. See `Rampung Brain/UX/Bilingual ID-EN.md`.
- **AI proposes, the user approves.** AI never changes a plan directly. It creates a Suggestion (a diff) that the user accepts in full, in part, or not at all.
- **Code does the arithmetic.** Dates, capacity, critical path and health score come from deterministic code: a pure-Python `planning` module tested with Hypothesis. The LLM never computes them.
- **Retrieval is always filtered by `project_id`.** Text from uploaded documents is data, never instructions.
- **LLM API keys stay on the server.** The Flutter app never holds a secret.
- **No PyMuPDF.** Its license is AGPL.

## Current state

- **Fase 0 (validation). Do not build app features yet.** The user asked for the app to wait until validation is done. Repo setup, docs and planning are fine; new screens, l10n wiring and backend code are not, until the user says so.
- It is a monorepo following the plan: `app/` (Flutter), `backend/`, `modes/`, `evals/`, `docs/adr/`. Only `app/` contains code, and that is still the default `flutter create` skeleton.
- The Flutter package is still named `workspace_ai`. It will be renamed to `rampung` after the name passes the trademark check (K-003).
- Run Flutter commands from `app/`. CI (`.github/workflows/ci.yml`) runs `flutter analyze` and `flutter test` there, pinned to Flutter 3.47.4.
- Git is local only; there is no remote yet. Architecture decisions go in `docs/adr/`; product and process decisions go in the vault.
