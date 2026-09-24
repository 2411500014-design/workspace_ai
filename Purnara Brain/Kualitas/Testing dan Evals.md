---
type: note
area: Kualitas
sumber: "§14"
tags:
  - kualitas
  - testing
  - evals
updated: 2026-09-24
---

# Testing dan Evals

Kualitas dijaga di tiga lapis: **test** untuk kode, **evals** untuk AI, dan **monitoring** untuk production ([[Operasional]]). Scheduler dan health score butuh cakupan test tertinggi, karena satu tanggal yang salah langsung merusak kepercayaan pengguna.

## Strategi testing

| Jenis | Cakupan | Tools | Kapan jalan |
| --- | --- | --- | --- |
| Unit test | Scheduler, health score, skor prioritas, validasi diff | pytest, Hypothesis | Setiap commit |
| Integration test | API, database, auth | pytest + PostgreSQL di Docker | Setiap pull request |
| Widget test | Komponen Flutter penting | flutter_test | Setiap pull request |
| End-to-end | Onboarding sampai rencana diterima, lalu tandai task selesai | Flutter integration_test | Sebelum rilis |
| AI evals | Kualitas output setiap workflow AI | Skrip evals + Langfuse | Setiap perubahan prompt atau model |

**Property-based testing (Hypothesis) untuk scheduler.** Hypothesis membangkitkan ribuan project acak. Test memastikan tiga aturan ini selalu benar:
1. Task tidak dimulai sebelum dependensinya selesai.
2. Jam per hari tidak melebihi kapasitas.
3. Rencana yang layak selalu selesai sebelum deadline.

Untuk dua bahasa: widget test sebaiknya dijalankan di locale `id` dan `en`, supaya teks yang lebih panjang atau key yang hilang ketahuan. Lihat [[Bilingual ID-EN]].

## AI evals

Dataset: **30–50 project realistis** (skripsi berbagai prodi, tugas besar, lomba) lengkap dengan dokumen contoh, plus **50 pertanyaan** yang jawabannya sudah diketahui. Cek otomatis dijalankan dulu, lalu rubrik penilaian. Dataset mulai dibangun di [[Langkah Pertama 14 Hari]] (10 project, 20 pertanyaan, semua data peserta dianonimkan).

| Workflow | Cek otomatis | Cek rubrik (LLM judge + review manual) |
| --- | --- | --- |
| Intake dan Brief | Field wajib terisi, tanggal valid, persentase syarat dosen yang tertangkap | Akurasi terhadap dokumen asli |
| Plan Generator | JSON valid, graf tanpa siklus, estimasi dalam rentang, setiap syarat punya task | Kelengkapan, urutan logis, ukuran task |
| Project Chat | Setiap klaim tentang dokumen bersitasi; jawaban "tidak ditemukan" saat memang tidak ada | Kebenaran dan kegunaan |
| Re-plan | Setiap opsi lolos cek kelayakan scheduler | Kejelasan penjelasan |
| Semua (tambahan) | Jawaban memakai bahasa yang benar (ID/EN) | Terjemahan istilah akademik wajar |

Kasus prompt injection lewat dokumen juga masuk dataset evals ([[Risiko]]).

## Aturan merge

- Perubahan prompt atau model hanya boleh masuk jika skor evals **tidak turun lebih dari 2 poin persentase**.
- Prompt disimpan sebagai file berversi di repo (`evals/` dan `backend/app/modules/ai/prompts`). Setiap pesan AI mencatat versi prompt yang dipakai.

## Sinyal kualitas di production

Tingkat penerimaan Suggestion, seberapa banyak rencana AI diedit, tombol suka/tidak suka, dan frekuensi regenerate. Targetnya ada di [[Metrik]].

Terkait: [[Planning Engine]] · [[AI Engine]] · [[Operasional]] · [[Metrik]]
