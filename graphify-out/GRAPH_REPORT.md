# Graph Report - docs  (2026-09-24)

## Corpus Check
- Corpus is ~0 words - fits in a single context window. You may not need a graph.

## Summary
- 219 nodes · 488 edges · 11 communities
- Extraction: 78% EXTRACTED · 21% INFERRED · 0% AMBIGUOUS · INFERRED: 104 edges (avg confidence: 0.87)
- Token cost: 160,342 input · 0 output

## Community Hubs (Navigation)
- AI Engine dan Grounding
- Usulan dan Loop Re-plan
- Fondasi Teknis dan Fase Awal
- Persona, Kompetitor, Literatur
- Lapisan Sistem dan Mode Lanjut
- Document Engine dan Retrieval
- Scheduler dan Graf Task
- Intake, Brief, Rencana
- Health Score dan Pengingat
- Paket Harga dan Integritas
- Legal dan Rujukan

## God Nodes (most connected - your core abstractions)
1. `Project Chat` - 18 edges
2. `V1` - 18 edges
3. `Plan Generator` - 17 edges
4. `Re-plan` - 16 edges
5. `Health score` - 16 edges
6. `Scheduler` - 15 edges
7. `MVP` - 15 edges
8. `Document ingestion` - 13 edges
9. `Mode Presets` - 11 edges
10. `Project Brief` - 11 edges

## Surprising Connections (you probably didn't know these)
- `Project Chat` --references--> `Claude Haiku 4.5`  [AMBIGUOUS]
  Master Plan AI Academic Workspace.pdf → Master Plan AI Academic Workspace.pdf  _Bridges community 0 → community 1_
- `PDKI (DJKI)` --conceptually_related_to--> `AI Academic Workspace`  [INFERRED]
  Master Plan AI Academic Workspace.pdf → Master Plan AI Academic Workspace.pdf  _Bridges community 3 → community 2_
- `Context Engine` --references--> `Mode Presets`  [INFERRED]
  Master Plan AI Academic Workspace.pdf → Master Plan AI Academic Workspace.pdf  _Bridges community 4 → community 0_
- `Concierge test` --semantically_similar_to--> `Siklus Project Adaptif`  [INFERRED] [semantically similar]
  Master Plan AI Academic Workspace.pdf → Master Plan AI Academic Workspace.pdf  _Bridges community 7 → community 2_
- `Context Engine` --references--> `Plan State`  [INFERRED]
  Master Plan AI Academic Workspace.pdf → Master Plan AI Academic Workspace.pdf  _Bridges community 6 → community 0_

## Hyperedges (group relationships)
- **Siklus Project Adaptif: Intake, Brief, Rencana, Pantau, Sesuaikan** — master_plan_ai_academic_workspace_intake_dan_brief, master_plan_ai_academic_workspace_project_brief, master_plan_ai_academic_workspace_plan_generator, master_plan_ai_academic_workspace_scheduler, master_plan_ai_academic_workspace_health_score, master_plan_ai_academic_workspace_re_plan, master_plan_ai_academic_workspace_suggestion [INFERRED 0.85]
- **Alur satu permintaan chat** — master_plan_ai_academic_workspace_project_chat, master_plan_ai_academic_workspace_retrieval, master_plan_ai_academic_workspace_context_engine, master_plan_ai_academic_workspace_model_gateway, master_plan_ai_academic_workspace_citations, master_plan_ai_academic_workspace_suggestion [EXTRACTED 1.00]
- **Algoritma scheduler (MVP)** — master_plan_ai_academic_workspace_scheduler, master_plan_ai_academic_workspace_algoritma_kahn_topological_sort, master_plan_ai_academic_workspace_jalur_kritis, master_plan_ai_academic_workspace_backward_pass, master_plan_ai_academic_workspace_forward_pass_berbasis_kapasitas, master_plan_ai_academic_workspace_cek_kelayakan [EXTRACTED 1.00]

## Communities (11 total, 0 thin omitted)

### Community 0 - "AI Engine dan Grounding"
Cohesion: 0.10
Nodes (35): AI Engine, AI evals, ai_messages, ai_suggestions, ai_threads, Batch API, Citations, Claude API (+27 more)

### Community 1 - "Usulan dan Loop Re-plan"
Cohesion: 0.11
Nodes (31): activity_events, AI mengusulkan, pengguna memutuskan, AI tertanam di alur kerja, AI Workflows, Aturan saat molor, Claude Haiku 4.5, Claude Sonnet 5, Endpoint inti (+23 more)

### Community 2 - "Fondasi Teknis dan Fase Awal"
Cohesion: 0.10
Nodes (30): ADR, Aktivasi, Alembic, Ambassador kampus, CI/CD, Client Dart dari OpenAPI, Concierge test, Deployment (+22 more)

### Community 3 - "Persona, Kompetitor, Literatur"
Cohesion: 0.14
Nodes (20): Academic Mode, AI Academic Workspace, AI scheduler (Motion, Reclaim), Asisten AI umum (ChatGPT, Claude, Gemini), Crossref, CSL, Focus session, Kalibrasi estimasi (+12 more)

### Community 4 - "Lapisan Sistem dan Mode Lanjut"
Cohesion: 0.18
Nodes (19): Churn Pro karena kecewa, Core Engines, Developer Mode, Dimas, developer indie, Experience Layer, Go-to-market, Intelligence Layer, Midtrans atau Xendit (+11 more)

### Community 5 - "Document Engine dan Retrieval"
Cohesion: 0.16
Nodes (18): Chunking dan embedding, Docling, document_chunks, Document Engine, Document ingestion, documents, Full-text search PostgreSQL, Knowledge (+10 more)

### Community 6 - "Scheduler dan Graf Task"
Cohesion: 0.20
Nodes (17): Algoritma Kahn (topological sort), Backward pass, Cek kelayakan, Dependency graph, Forward pass berbasis kapasitas, Jalur kritis, LLM memahami dan menulis, kode biasa menghitung dan menyimpan, Milestone tepat waktu (+9 more)

### Community 7 - "Intake, Brief, Rencana"
Cohesion: 0.23
Nodes (16): Alur onboarding, Checklist syarat, Intake dan Brief, notes, Pertanyaan terbuka, Plan Generator, Project Brief, project_briefs (+8 more)

### Community 8 - "Health Score dan Pengingat"
Cohesion: 0.26
Nodes (12): Firebase Cloud Messaging, Health score, Insight & Notification Engine, notifications, Opt-out pengingat, Pengingat, progress_snapshots, projects (+4 more)

### Community 9 - "Paket Harga dan Integritas"
Cohesion: 0.21
Nodes (12): Integritas akademik, Konversi gratis ke berbayar, Kuota AI, Log kontribusi AI, Model bisnis freemium, Outline Assistant, Paket Gratis, Paket Pro (+4 more)

### Community 10 - "Legal dan Rujukan"
Cohesion: 0.33
Nodes (9): Master Plan: AI Academic Workspace, Claude Platform Docs (Features overview), DPIA, Ekspor data dan hapus akun, Pemberitahuan kegagalan pelindungan data 3 x 24 jam, PP 33/2026, Risiko: Kebocoran data atau pelanggaran UU PDP, The Mom Test (+1 more)

## Ambiguous Edges - Review These
- `Project Chat` → `Claude Haiku 4.5`  [AMBIGUOUS]
  Master Plan AI Academic Workspace.pdf · relation: references

## Knowledge Gaps
- **21 isolated node(s):** `Opsi pemulihan re-plan`, `Model embedding multilingual`, `python-docx`, `OpenAlex`, `Semantic Scholar` (+16 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 24 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Project Chat` and `Claude Haiku 4.5`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `MVP` connect `Usulan dan Loop Re-plan` to `AI Engine dan Grounding`, `Persona, Kompetitor, Literatur`, `Intake, Brief, Rencana`, `Health Score dan Pengingat`, `Paket Harga dan Integritas`, `Legal dan Rujukan`?**
  _High betweenness centrality (0.121) - this node is a cross-community bridge._
- **Why does `Plan Generator` connect `Intake, Brief, Rencana` to `AI Engine dan Grounding`, `Usulan dan Loop Re-plan`, `Fondasi Teknis dan Fase Awal`, `Persona, Kompetitor, Literatur`, `Lapisan Sistem dan Mode Lanjut`, `Scheduler dan Graf Task`?**
  _High betweenness centrality (0.100) - this node is a cross-community bridge._
- **Why does `V1` connect `Persona, Kompetitor, Literatur` to `Usulan dan Loop Re-plan`, `Fondasi Teknis dan Fase Awal`, `Lapisan Sistem dan Mode Lanjut`, `Document Engine dan Retrieval`, `Health Score dan Pengingat`, `Paket Harga dan Integritas`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `Project Chat` (e.g. with `Grounded` and `Jobs-to-be-done`) actually correct?**
  _`Project Chat` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `Plan Generator` (e.g. with `Kalibrasi estimasi` and `Claude Sonnet 5`) actually correct?**
  _`Plan Generator` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `Re-plan` (e.g. with `Claude Sonnet 5` and `Suggestion`) actually correct?**
  _`Re-plan` has 3 INFERRED edges - model-reasoned connections that need verification._