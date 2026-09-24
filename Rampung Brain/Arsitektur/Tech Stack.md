---
type: note
area: Arsitektur
sumber: "§10"
tags:
  - arsitektur
  - stack
updated: 2026-09-24
---

# Tech Stack

Stack utama: **Flutter** untuk semua UI, **FastAPI (Python)** untuk backend dan AI, **Supabase** untuk database, login, dan file. Flutter dan Python sudah pernah dipakai, jadi energi bisa fokus ke produk.

```mermaid
flowchart LR
  F[Flutter app<br/>web, Android, iOS] -->|HTTPS + JWT| A[FastAPI<br/>modular monolith]
  F -->|login| SA[Supabase Auth]
  A --> DB[(PostgreSQL<br/>+ pgvector)]
  A --> ST[Supabase Storage]
  A --> Q[Redis queue]
  Q --> W[Worker Python<br/>ingestion, cron]
  W --> DB
  W --> LLM[LLM + embedding API]
  A --> LLM
```

API melayani permintaan cepat dan chat streaming. Worker mengerjakan tugas berat: ingestion dokumen, cek health harian, dan pengiriman pengingat.

## Pilihan per lapisan

| Lapisan | Pilihan | Alasan | Alternatif |
| --- | --- | --- | --- |
| UI web dan mobile | Flutter, Riverpod, go_router, Dio, freezed | Satu codebase untuk tiga platform | Next.js untuk web + Flutter untuk mobile |
| i18n | Flutter gen-l10n dengan file ARB `id` dan `en` | Bawaan Flutter, sudah direncanakan sejak awal | — |
| Landing page | Situs statis (Astro atau website builder) | SEO; Flutter web lemah untuk SEO | — |
| API | FastAPI, Pydantic v2, SQLAlchemy 2, Alembic | Validasi tipe kuat, async, OpenAPI otomatis | Django + DRF |
| Worker | Celery atau ARQ, dengan Redis | Job ingestion, cron harian, retry | Dramatiq |
| Database | PostgreSQL di Supabase + pgvector | Data relasional dan vektor di satu tempat | Neon |
| Auth | Supabase Auth (email, Google) | SDK Flutter resmi; FastAPI cukup memverifikasi JWT | Firebase Auth |
| File | Supabase Storage dengan signed URL | Satu platform dengan database | Cloudflare R2 |
| LLM | Claude API lewat Model Gateway | Citations, prompt caching, batch | Provider lain lewat gateway |
| Email | Resend atau Brevo | API sederhana | — |
| Push (V1) | Firebase Cloud Messaging | Standar di Flutter | — |
| Observability | Sentry, PostHog, Langfuse | Error, analitik produk, tracing LLM | — |
| Pembayaran (V1) | Midtrans atau Xendit | QRIS, e-wallet, virtual account | — |

**Catatan Flutter web:** unduhan awalnya besar dan SEO-nya lemah. Karena aplikasi berada di balik login, cukup buat landing page terpisah dan tampilkan layar loading ringan. Landing page juga perlu dua bahasa. Lihat [[Bilingual ID-EN]].

## Struktur repo (monorepo, rencana)

```text
rampung/
├── app/                     # Flutter (web + mobile)
│   └── lib/
│       ├── core/            # tema, router, api client, auth, l10n
│       ├── features/        # project, task, plan, documents, chat, insight
│       └── shared/          # widget umum
├── backend/
│   ├── app/
│   │   ├── api/v1/          # router FastAPI, lapisan tipis
│   │   ├── modules/
│   │   │   ├── projects/    # service, repository, schemas
│   │   │   ├── tasks/
│   │   │   ├── planning/    # scheduler + health, Python murni tanpa I/O
│   │   │   ├── documents/
│   │   │   ├── insight/
│   │   │   └── ai/          # gateway, context, workflows, prompts
│   │   ├── core/            # config, db, auth, logging
│   │   └── workers/         # job background dan cron
│   ├── migrations/          # Alembic
│   └── tests/
├── modes/                   # YAML preset mode + template project
├── evals/                   # dataset dan skrip evals AI
└── docs/adr/                # catatan keputusan arsitektur
```

> [!info] Kondisi repo sekarang (2026-09-24)
> `D:\Workspace AI\workspace_ai` sudah memakai struktur monorepo di atas. `app/` berisi kerangka bawaan `flutter create` (package masih `workspace_ai`, Flutter 3.47.4 / Dart 3.13.3). `backend/`, `modes/`, dan `evals/` baru berisi README. Selain itu ada `docs/adr/0001-pilihan-stack.md`, CI di `.github/workflows/ci.yml`, `graphify-out/`, dan vault ini. Git masih lokal tanpa remote. Nama package menunggu cek merek, lihat [[K-003 Vault dan struktur folder]].

Client Dart di-generate dari spesifikasi OpenAPI FastAPI, supaya model data di Flutter selalu sama dengan backend. Lihat [[API]].

## Deployment

| Komponen | Tempat | Region |
| --- | --- | --- |
| Flutter web | Cloudflare Pages atau Firebase Hosting | CDN global |
| FastAPI dan worker (Docker) | Railway, Render, atau Fly.io | Singapura |
| Database, Auth, Storage | Supabase | Singapura |
| Redis | Upstash atau add-on platform | Singapura |

Ada tiga lingkungan: **lokal** (Supabase CLI + Docker), **staging**, dan **production**, masing-masing dengan kunci API terpisah. Paket gratis Supabase cukup untuk development. Production memakai paket berbayar agar tidak dijeda dan punya backup.

Terkait: [[Struktur Sistem]] · [[Model Data]] · [[API]] · [[Operasional]]
