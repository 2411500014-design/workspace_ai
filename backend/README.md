# Purnara: backend

API FastAPI dengan pola modular monolith (master plan §10). Python 3.12+, dikelola dengan uv. Secara bawaan berjalan penuh di laptop: SQLite, file lokal, satu pengguna tanpa login, dan AI opsional (ADR-0002).

```bash
uv sync
```

```bash
uv run uvicorn app.main:app --reload --port 8000
```

Migrasi Alembic dijalankan otomatis saat server mulai. Dokumentasi API interaktif ada di `http://localhost:8000/docs`. Kalau `app/build/web` ada (hasil `flutter build web`), server juga melayani aplikasi web di `http://localhost:8000`.

## Struktur

```text
backend/
├── app/
│   ├── api/            # router v1 (lapisan tipis), serializer, dependency
│   ├── core/           # config, db, auth, error, clock
│   └── modules/
│       ├── accounts/   # profil, workspace, anggota
│       ├── planning/   # scheduler, jalur kritis, prioritas, health, re-plan; Python murni tanpa I/O
│       ├── tasks/      # task, dependensi, penjadwalan ulang, rencana dan re-plan
│       ├── projects/   # project, brief berversi, syarat dosen, catatan
│       ├── documents/  # ekstraksi PDF/DOCX, chunking, BM25, heuristik tanpa AI
│       ├── ai/         # Model Gateway, prompt, workflow + versi dasar, usulan (diff)
│       ├── insight/    # Hari Ini, health harian, notifikasi, review mingguan
│       └── modes/      # pemuat preset dari ../modes/*.yaml
├── migrations/         # Alembic
└── tests/              # pytest + Hypothesis
```

## Konfigurasi

Semua lewat variabel lingkungan berawalan `PURNARA_` atau file `backend/.env` (tidak masuk git).

| Variabel | Bawaan | Keterangan |
| --- | --- | --- |
| `PURNARA_DATABASE_URL` | SQLite di `backend/data/purnara.db` | URL SQLAlchemy; Postgres untuk produksi |
| `PURNARA_STORAGE_DIR` | `backend/data/files` | Tempat file dokumen |
| `PURNARA_AUTH_MODE` | `local` | `supabase` untuk memverifikasi token Supabase |
| `PURNARA_WEB_DIR` | `../app/build/web` | Hasil build Flutter web yang ikut dilayani |
| `ANTHROPIC_API_KEY` | kosong | Tanpa kunci, fitur AI memakai versi dasar |

## Pemeriksaan

```bash
uv run ruff check .
```

```bash
uv run pytest
```

Test planning engine memakai Hypothesis (1.500 contoh acak per properti). Test API menjalankan seluruh siklus tanpa AI: dokumen, brief, rencana, progress, tertinggal, lalu re-plan.
