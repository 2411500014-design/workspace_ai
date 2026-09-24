---
type: source
area: Sumber
tags:
  - sumber
  - graph
updated: 2026-09-24
---

# Knowledge Graph

Graph pengetahuan yang dibangun dari [[Master Plan]] dengan **graphify** pada 2026-09-24. Semua konsep, engine, tabel, fitur, risiko, dan metrik di plan menjadi node, dan hubungan antar-node menjadi edge. Graph view Obsidian menunjukkan hubungan antar-*catatan* vault. Graph ini menunjukkan hubungan antar-*konsep* di dalam plan.

**Buka:** [graph.html](file:///D:/Workspace%20AI/workspace_ai/graphify-out/graph.html) (interaktif, di browser) · [GRAPH_REPORT.md](file:///D:/Workspace%20AI/workspace_ai/graphify-out/GRAPH_REPORT.md) (laporan lengkap)

## Angka

- **219 node · 488 edge · 11 komunitas · 3 hyperedge**
- 78% edge EXTRACTED (tertulis eksplisit di plan), 21% INFERRED (rata-rata confidence 0,87), 1 AMBIGUOUS.
- Health check: tidak ada edge yang menggantung, hilang, atau terlipat.

## Node paling terhubung

| Node | Edge | Catatan vault |
| --- | --- | --- |
| Project Chat | 18 | [[AI Engine]] |
| V1 | 18 | [[Fitur MVP V1 V2]] |
| Plan Generator | 17 | [[Planning Engine]], [[AI Engine]] |
| Re-plan | 16 | [[Planning Engine]] |
| Health score | 16 | [[Planning Engine]] |
| Scheduler | 15 | [[Planning Engine]] |
| MVP | 15 | [[Fitur MVP V1 V2]] |
| Document ingestion | 13 | [[Document Engine]] |
| Mode Presets | 11 | [[Mode sebagai Preset]] |
| Project Brief | 11 | [[Siklus Project Adaptif]] |

**Plan Generator** dan **MVP** adalah jembatan terbesar antar-komunitas. Perubahan pada keduanya menjalar ke paling banyak bagian plan.

## Komunitas

| # | Komunitas | Node | Kohesi | Catatan vault terdekat |
| --- | --- | --- | --- | --- |
| 0 | AI Engine dan Grounding | 35 | 0,10 | [[AI Engine]] |
| 1 | Usulan dan Loop Re-plan | 31 | 0,11 | [[Planning Engine]], [[Alur dan Layar]] |
| 2 | Fondasi Teknis dan Fase Awal | 30 | 0,10 | [[Tech Stack]], [[Roadmap]] |
| 3 | Persona, Kompetitor, Literatur | 20 | 0,14 | [[Persona dan JTBD]], [[Visi dan Positioning]] |
| 4 | Lapisan Sistem dan Mode Lanjut | 19 | 0,18 | [[Struktur Sistem]], [[Mode sebagai Preset]] |
| 5 | Document Engine dan Retrieval | 18 | 0,16 | [[Document Engine]] |
| 6 | Scheduler dan Graf Task | 17 | 0,20 | [[Planning Engine]] |
| 7 | Intake, Brief, Rencana | 16 | 0,23 | [[Siklus Project Adaptif]] |
| 8 | Health Score dan Pengingat | 12 | 0,26 | [[Planning Engine]], [[Alur dan Layar]] |
| 9 | Paket Harga dan Integritas | 12 | 0,21 | [[Monetisasi]], [[Integritas Akademik]] |
| 10 | Legal dan Rujukan | 9 | 0,33 | [[Keamanan dan Privasi]] |

Kohesi rendah (0,10–0,33) wajar untuk satu dokumen plan, karena hampir semua bagian saling merujuk.

## Temuan yang berguna

- **Satu ketidakkonsistenan di plan.** Tabel workflow menulis kelas model Project Chat "kuat atau ringan", sedangkan tabel unit economics menghitungnya sebagai kelas kuat. Selisih ini memengaruhi estimasi biaya AI. Sudah dicatat di [[Pertanyaan Terbuka]].
- **Concierge test mirip Siklus Project Adaptif.** Fase 0 menjalankan siklus produk secara manual, jadi temuan concierge langsung menguji desain intinya.
- **Context Engine terhubung ke Mode Presets dan Plan State.** Persona dan istilah per bahasa ([[Bilingual ID-EN]]) masuk lewat jalur ini.
- **Kontrak JSON Plan Generator adalah antarmuka paling kritis** (ditelusuri 2026-09-24). Plan Generator punya 17 edge dan menjembatani 7 komunitas. Yang memakai output-nya: scheduler (`estimate_hours`, `depends_on`), checklist syarat (`requirement_refs`), kartu usulan (Suggestion), pertanyaan terbuka di brief, dan kalibrasi estimasi V1. Yang bergantung padanya: Fase 2, endpoint `plan/generate`, target "rencana < 60 detik", dan metrik "rencana diedit ≤ 30%". Artinya schema Pydantic kontrak ini perlu dikunci dan diberi versi sebelum kode di sekitarnya ditulis. Lihat [[Planning Engine]].
- **21 node hampir terisolasi**, misalnya OpenAlex, Semantic Scholar, python-docx, dan model embedding multilingual. Plan hanya menyebutnya sekilas. Keputusannya bisa ditunda sampai fitur terkait dibangun.

## Memakai graph

Dari folder project (`D:\Workspace AI\workspace_ai`):

```bash
graphify query "apa saja yang bergantung pada Plan Generator?"
```

```bash
graphify path "Log bimbingan" "Health score"
```

Setelah master plan diperbarui, jalankan perintah ini di Claude Code dari folder project. Hanya file yang berubah yang diekstrak ulang:

```text
/graphify docs --update
```

CLI `graphify update` hanya mengekstrak ulang file kode, jadi tidak cukup untuk PDF.

Graph ini hanya berisi master plan. English dan nama Rampung belum ada di dalamnya, karena keduanya diputuskan setelah plan ditulis.

Terkait: [[Master Plan]] · [[Rampung]]
