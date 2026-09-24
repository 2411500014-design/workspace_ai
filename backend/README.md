# Rampung: backend

FastAPI dengan pola modular monolith, ditambah worker background (Celery atau ARQ, dengan Redis). **Belum ada kode.**

Struktur yang direncanakan (master plan §10):

```text
backend/
├── app/
│   ├── api/v1/          # router FastAPI, lapisan tipis
│   ├── modules/
│   │   ├── projects/    # service, repository, schemas
│   │   ├── tasks/
│   │   ├── planning/    # scheduler + health, Python murni tanpa I/O
│   │   ├── documents/
│   │   ├── insight/
│   │   └── ai/          # gateway, context, workflows, prompts
│   ├── core/            # config, db, auth, logging
│   └── workers/         # job background dan cron
├── migrations/          # Alembic
└── tests/
```

Kode pertama yang direncanakan adalah prototipe scheduler Python murni (graf dependensi, jalur kritis, kapasitas) dengan test Hypothesis. Lihat catatan vault `Arsitektur/Planning Engine.md`.
