# ADR-0001: Pilihan stack teknis

- Status: Diterima
- Tanggal: 2026-09-24
- Sumber: master plan §1, §10 (`docs/Master Plan AI Academic Workspace.pdf`)

## Konteks

- Satu developer, 15–20 jam per minggu. Beta tertutup harus siap 1 Feb 2027.
- Web dulu, lalu Android, lalu iOS, sebaiknya dari satu codebase.
- Fitur inti banyak bergantung pada AI dan dokumen: ekstraksi PDF/DOCX, embedding, retrieval bersitasi, dan structured output.
- Data relasional (project, task, dependensi) dan data vektor (chunk dokumen) dipakai bersama. Setiap query harus bisa difilter per project.
- Pengguna di Indonesia, dan data tunduk pada UU PDP dan PP 33/2026.
- UI dua bahasa: Indonesia dan English (vault: `Keputusan/K-002 Dua bahasa ID dan EN.md`).
- Flutter dan Python sudah dikuasai.

## Keputusan

| Lapisan | Pilihan |
| --- | --- |
| UI web dan mobile | Flutter dengan Riverpod, go_router, Dio, freezed; i18n lewat gen-l10n dengan ARB `id` dan `en` |
| Landing page | Situs statis terpisah (Astro atau website builder), rute `/id` dan `/en` |
| API | FastAPI, Pydantic v2, SQLAlchemy 2, Alembic, sebagai **modular monolith** (modul saling memanggil hanya lewat service layer) |
| Worker | Celery atau ARQ dengan Redis (diputuskan saat Fase 2) |
| Database | PostgreSQL + pgvector di Supabase, region Singapura |
| Auth dan file | Supabase Auth (email, Google); Supabase Storage dengan signed URL |
| LLM | Claude API di balik satu **Model Gateway** internal; model final per kelas dipilih lewat evals |
| Email / push | Resend atau Brevo; Firebase Cloud Messaging (V1) |
| Observability | Sentry, PostHog, Langfuse |
| Pembayaran (V1) | Midtrans atau Xendit |
| Hosting | Flutter web di Cloudflare Pages atau Firebase Hosting; API dan worker (Docker) di Railway, Render, atau Fly.io, region Singapura |

Client Dart di-generate dari spesifikasi OpenAPI FastAPI.

## Konsekuensi

- Satu codebase Flutter untuk tiga platform. Harganya: unduhan awal Flutter web besar dan SEO-nya lemah. Karena itu landing page dibuat terpisah, dan aplikasi yang berada di balik login cukup menampilkan layar loading ringan.
- Python memberi ekosistem AI dan parsing dokumen yang paling matang. Konsekuensinya ada dua bahasa pemrograman (Dart dan Python), dan kontrak di antaranya dijaga lewat OpenAPI.
- Supabase menyatukan data, pencarian semantik, login, dan file. Ketergantungannya terbatas karena intinya PostgreSQL standar dan migrasi dikelola Alembic, bukan dashboard Supabase.
- Model Gateway membuat provider LLM bisa diganti tanpa menyentuh workflow, dan menjadi satu tempat untuk kuota, retry, dan pencatatan biaya.
- Modul `planning` ditulis sebagai Python murni tanpa I/O, supaya bisa diuji dengan Hypothesis dalam hitungan detik.
- **Tidak memakai PyMuPDF.** Lisensinya AGPL. Pakai pypdf atau pdfplumber (BSD/MIT) dan python-docx (MIT).
- API key LLM dan service key Supabase hanya ada di server. Aplikasi Flutter tidak pernah memegang kunci rahasia.

## Alternatif yang ditolak

| Alternatif | Alasan ditolak |
| --- | --- |
| Next.js untuk web + Flutter untuk mobile | Dua codebase UI untuk satu developer |
| Django + DRF | FastAPI lebih ringan, async, dan menghasilkan OpenAPI otomatis untuk client Dart |
| Firebase Auth | Supabase Auth punya SDK Flutter resmi dan satu platform dengan database |
| Neon (Postgres) | Butuh layanan auth dan storage terpisah |
| Cloudflare R2 | Storage terpisah dari database dan auth |
| Microservices | Terlalu berat untuk satu developer; modular monolith bisa dipecah nanti |
| Fine-tuning atau self-host model | Model API cukup; biaya dan perawatannya belum sebanding |
