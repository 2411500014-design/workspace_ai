---
type: note
area: Arsitektur
sumber: "§10"
tags:
  - arsitektur
  - api
updated: 2026-09-24
---

# API

Endpoint inti FastAPI untuk MVP. Router di `api/v1/` sengaja tipis dan hanya memanggil service layer modul (lihat [[Struktur Sistem]]).

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| POST | `/v1/projects` | Buat project dari wizard intake |
| POST | `/v1/projects/{id}/documents` | Minta signed URL upload, daftarkan dokumen |
| POST | `/v1/projects/{id}/brief/extract` | Ekstraksi brief (async) |
| POST | `/v1/projects/{id}/plan/generate` | Buat rencana sebagai Suggestion |
| POST | `/v1/suggestions/{id}/apply` | Terapkan semua atau sebagian diff |
| GET | `/v1/projects/{id}/tasks` | Daftar task dengan filter |
| PATCH | `/v1/tasks/{id}` | Ubah status, estimasi, tanggal |
| POST | `/v1/projects/{id}/chat` | Chat berkonteks, streaming SSE |
| GET | `/v1/projects/{id}/health` | Health score dan riwayatnya |
| GET | `/v1/me/today` | Fokus hari ini lintas project |

## Konvensi

- Autentikasi: JWT Supabase di header, diverifikasi FastAPI di setiap request.
- Client Dart di-generate dari spesifikasi OpenAPI, supaya model data Flutter selalu sama dengan backend.
- Aksi AI yang mengubah data tidak pernah langsung menulis. Hasilnya berupa Suggestion yang diterapkan lewat `/v1/suggestions/{id}/apply`.

## Dua bahasa di API

- **Error dikirim sebagai kode stabil** (misalnya `quota_exhausted`), bukan kalimat. Flutter menerjemahkan kode itu lewat ARB. Dengan begitu backend tidak perlu tahu bahasa UI untuk pesan error.
- Konten yang dibuat AI (brief, penjelasan re-plan, jawaban chat) dihasilkan dalam bahasa dari `profiles.locale`. Pilihan lain adalah header `Accept-Language` dari app. Aturannya dicatat di [[Bilingual ID-EN]].
- Email dan notifikasi dirender server dengan template per bahasa.

Terkait: [[Tech Stack]] · [[Model Data]] · [[AI Engine]]
