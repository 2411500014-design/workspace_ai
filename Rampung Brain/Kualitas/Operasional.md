---
type: note
area: Kualitas
sumber: "§14"
tags:
  - kualitas
  - devops
updated: 2026-09-24
---

# Operasional

## CI/CD

- GitHub Actions menjalankan lint (ruff, dart analyze), type check (pyright), test, dan build di setiap pull request.
- Trunk-based development: branch fitur berumur pendek, pull request dengan checklist review, termasuk saat bekerja sendiri.
- Merge ke `main` otomatis deploy ke staging. Tag rilis deploy ke production. Migrasi database berjalan sebelum aplikasi baru aktif.
- Feature flag PostHog untuk merilis fitur AI bertahap, misalnya ke 10% pengguna dulu.
- Keputusan arsitektur penting dicatat sebagai ADR di `docs/adr`. Keputusan produk dan proses dicatat di vault ini ([[Log Keputusan]]).

## Observability

| Alat | Yang dipantau |
| --- | --- |
| Sentry | Error dan crash di Flutter dan FastAPI |
| PostHog | Event produk, funnel, retensi (daftar event di [[Metrik]]) |
| Langfuse | Trace setiap panggilan AI: versi prompt, token, latensi, biaya, feedback |
| Uptime monitor | Ketersediaan API dan web, alert ke email atau Telegram |
| Dashboard biaya | Biaya AI harian per pengguna aktif, alert saat melewati ambang |

## Target non-fungsional MVP

| Aspek | Target |
| --- | --- |
| Muat halaman setelah aplikasi ter-cache | < 2 detik |
| Token pertama jawaban chat | < 3 detik (streaming) |
| Rencana selesai dibuat | < 60 detik, dengan indikator progres |
| Dokumen 30 halaman siap ditanya | < 2 menit |
| Ketersediaan | 99,5% per bulan |
| Kehilangan data maksimal saat bencana | 24 jam (backup harian) |

Terkait: [[Testing dan Evals]] · [[Tech Stack]] · [[Keamanan dan Privasi]]
