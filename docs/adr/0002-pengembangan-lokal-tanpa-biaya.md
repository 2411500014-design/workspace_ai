# ADR-0002: Pengembangan lokal tanpa biaya

- Status: Diterima
- Tanggal: 2026-09-24
- Melengkapi: ADR-0001 (stack target tetap berlaku)
- Terkait: vault `Keputusan/K-005 Mulai membangun aplikasi.md`

## Konteks

- Pembangunan aplikasi dimulai sekarang (K-005), sejajar dengan validasi Fase 0.
- Belum ada anggaran: tidak ada domain, hosting berbayar, atau langganan layanan. Repo cukup di GitHub.
- ADR-0001 menetapkan stack produksi: Supabase (Postgres + pgvector, Auth, Storage), worker dengan Redis, embedding, Sentry/PostHog/Langfuse, dan hosting cloud. Semua itu butuh akun, kartu, atau biaya.
- Aplikasi harus tetap bisa dipakai penuh di laptop mahasiswa dan diuji otomatis di CI, termasuk saat server berjalan tanpa `ANTHROPIC_API_KEY`.

## Keputusan

Semua bagian punya versi lokal yang gratis. Versi produksi dari ADR-0001 dipasang lewat konfigurasi, bukan lewat perubahan kode.

| Kebutuhan | Versi lokal sekarang | Versi produksi (ADR-0001) |
| --- | --- | --- |
| Database | SQLite (`backend/data/purnara.db`), skema lewat Alembic | PostgreSQL di Supabase; URL diganti lewat `PURNARA_DATABASE_URL` |
| File dokumen | Folder lokal (`backend/data/files`) | Supabase Storage |
| Login | `PURNARA_AUTH_MODE=local`: satu pengguna, tanpa login | `supabase`: token Supabase diverifikasi (HS256 atau JWKS) |
| Pemrosesan dokumen | `BackgroundTasks` FastAPI di proses yang sama | Worker Celery/ARQ + Redis |
| Pencarian dokumen | BM25 berbobot dengan perluasan istilah ID↔EN, filter `project_id` | Hybrid: BM25 + pgvector, digabung dengan RRF (fungsinya sudah ada) |
| AI | Opsional. Tanpa kunci, setiap fitur memakai versi dasar yang deterministik dan diberi label jelas | Claude API lewat Model Gateway, dengan kuota token per pengguna |
| Hosting | Backend melayani API dan hasil `flutter build web` di satu port (8000). Ponsel di Wi-Fi yang sama memakai alamat LAN laptop | Cloudflare Pages / Firebase Hosting + Railway/Render/Fly.io |
| Observability | Log proses dan `activity_events` di database | Sentry, PostHog, Langfuse |

Keputusan pendukung:

- **Versi dasar tanpa AI adalah fitur, bukan cadangan darurat.** Brief disusun dari pola teks dokumen, rencana dari template mode, tanya-jawab mengutip potongan dokumen yang paling relevan beserta halamannya, dan pecah task memakai aturan sederhana. Semuanya diuji di `backend/tests/api/test_flow_without_ai.py`.
- **Material dari package `material_ui`.** Mulai Flutter 3.47, Material dipisah dari framework, dan go_router 18 sudah memakainya. Aplikasi mengimpor `package:material_ui/material_ui.dart` di semua tempat.
- **Model data ditulis tangan untuk sekarang.** freezed dan client Dart hasil generate OpenAPI (ADR-0001) ditunda sampai API stabil. Kontrak dijaga oleh test API di backend dan test widget di aplikasi.
- **Android memakai HTTP biasa ke laptop** (`usesCleartextTraffic`), karena server lokal belum punya HTTPS. Setelah server punya HTTPS, izin ini dicabut.

## Konsekuensi

- Satu perintah menjalankan seluruh produk di laptop, dan CI tidak butuh rahasia apa pun.
- SQLite dan Postgres berbeda dalam hal tanggal dan zona waktu. Kolom waktu memakai tipe `UTCDateTime` supaya perilakunya sama di keduanya.
- BM25 tidak mengenali sinonim di luar tabel perluasan. Pertanyaan yang tidak cocok kata per kata bisa dijawab "tidak ditemukan di dokumen". Kelemahan ini hilang saat embedding dipasang.
- `BackgroundTasks` berhenti kalau proses server mati di tengah jalan. Dokumen tertahan di status *processing* dan pengguna bisa menekan **Coba lagi**.
- Mode `local` hanya untuk satu orang di satu mesin. Jangan membuka port server ke internet dalam mode ini.

## Alternatif yang ditolak

| Alternatif | Alasan ditolak |
| --- | --- |
| Langsung memakai paket gratis Supabase | Tetap butuh akun dan koneksi internet untuk setiap test; data uji bercampur dengan data nyata |
| Docker Compose (Postgres + Redis) untuk pengembangan | Berat untuk laptop mahasiswa dan tidak perlu selama pengguna masih satu orang |
| Menunda fitur AI sampai ada anggaran | Alur utama (brief, rencana, tanya-jawab) harus bisa divalidasi sekarang; versi dasar memungkinkan itu |
| Embedding lokal (sentence-transformers) | Unduhan model besar dan lambat di CPU; BM25 cukup untuk validasi awal |
