---
type: index
area: Keputusan
tags:
  - keputusan
updated: 2026-09-24
---

# Log Keputusan

Satu tempat untuk semua keputusan. Keputusan baru dibuat dari template `Templates/Keputusan` dengan nomor berikutnya.

## Keputusan project

![[Rampung.base#Keputusan]]

| No | Keputusan | Tanggal | Status |
| --- | --- | --- | --- |
| [[K-001 Nama produk Rampung]] | Nama produk Rampung / Rampung AI | 2026-09-24 | Diterima, menunggu cek merek |
| [[K-002 Dua bahasa ID dan EN]] | Aplikasi dan web dalam Bahasa Indonesia dan English | 2026-09-24 | Diterima |
| [[K-003 Vault dan struktur folder]] | Vault di dalam folder project; monorepo menyusul | 2026-09-24 | Diterima, sebagian terbuka |

## Keputusan arsitektur (ADR di repo)

Keputusan arsitektur dicatat di `docs/adr/` di repo, bukan di vault. Obsidian tidak bisa menautkan file di luar vault, jadi daftarnya ditulis di sini.

| ADR | Judul | Tanggal |
| --- | --- | --- |
| ADR-0001 | Pilihan stack teknis (`docs/adr/0001-pilihan-stack.md`), meresmikan MP-06 sampai MP-11 di bawah | 2026-09-24 |

## Keputusan dasar dari master plan

Diambil saat master plan ditulis (24 Sep 2026). Mengubah salah satunya butuh catatan K-baru.

| # | Area | Keputusan | Alasan singkat | Catatan |
| --- | --- | --- | --- | --- |
| MP-01 | Pasar awal | Mahasiswa tingkat akhir di Indonesia (skripsi, TA, penelitian) | Struktur kerja berulang, deadline nyata, masalah jelas | [[Persona dan JTBD]] |
| MP-02 | Diferensiasi | Project Context: brief, rencana, dokumen, progress, riwayat keputusan | To-do, kalender, dan chatbot sudah komoditas | [[Siklus Project Adaptif]] |
| MP-03 | Pola AI | AI mengusulkan, pengguna menyetujui (usulan tampil sebagai diff) | Rencana tidak pernah berubah diam-diam | [[Prinsip Produk]] |
| MP-04 | Penjadwalan | Scheduler deterministik di kode; LLM memecah pekerjaan dan menjelaskan | LLM sering salah hitung tanggal dan kapasitas | [[Planning Engine]] |
| MP-05 | Mode | Satu codebase; mode = preset (template, istilah, persona AI) | Mode baru cukup berupa konfigurasi | [[Mode sebagai Preset]] |
| MP-06 | Frontend | Flutter: web dulu, lalu Android, lalu iOS | Satu codebase untuk semua platform | [[Tech Stack]] |
| MP-07 | Backend | Python (FastAPI) + worker background | Ekosistem AI dan parsing dokumen paling matang | [[Tech Stack]] |
| MP-08 | Data | PostgreSQL + pgvector di Supabase (plus Auth dan Storage) | Satu layanan untuk data, pencarian semantik, login, file | [[Model Data]] |
| MP-09 | Arsitektur | Modular monolith | Cukup untuk satu developer, bisa dipecah nanti | [[Struktur Sistem]] |
| MP-10 | Pendekatan AI | Structured output + RAG + tool calling; agen otonom menunggu V2 | Workflow terstruktur lebih mudah diuji | [[AI Engine]] |
| MP-11 | Model awal | Haiku 4.5 untuk kelas ringan, Sonnet 5 untuk kelas kuat; final dari evals | Titik awal, bisa diganti lewat gateway | [[AI Engine]] |
| MP-12 | Scope MVP | Academic Mode versi web; mobile, kolaborasi, dan mode lain antre | Risiko terbesar ada di scope | [[Fitur MVP V1 V2]] |
| MP-13 | Aturan molor | Potong scope dulu, baru geser tanggal | Tanggal beta terikat awal semester | [[Roadmap]] |

Terkait: [[Pertanyaan Terbuka]] · [[Riwayat]]
