---
type: home
tags:
  - rampung
  - home
updated: 2026-09-24
---

# Rampung

**Rampung** (atau **Rampung AI**) artinya *selesai*. Yang dijual adalah hasil akhirnya: project besar benar-benar selesai tepat waktu. Rampung adalah workspace project berbasis AI. AI memegang konteks utuh sebuah project, lalu membantu merencanakan, memantau, dan menyusun ulang rencana saat keadaan berubah. Pasar pertama: mahasiswa tingkat akhir di Indonesia yang mengerjakan skripsi, TA, dan penelitian.

Aplikasi dan web tersedia dalam **Bahasa Indonesia dan English**. Lihat [[K-002 Dua bahasa ID dan EN]].

> [!info] Status per 2026-09-24
> Tahap perencanaan. [[Master Plan]] selesai (43 halaman). Fase 0 (validasi) mulai 28 Sep 2026. Repo sudah berbentuk monorepo dan punya git lokal, tapi **aplikasinya belum dibangun**: `app/` masih kerangka Flutter bawaan, dan fitur baru dimulai setelah Fase 0.

**Folder project:** `D:\Workspace AI\workspace_ai` · **Vault ini:** `Rampung Brain\` di dalam folder itu · **Graph dari master plan:** [[Knowledge Graph]]

## Inti produk
- **Satu siklus:** intake → brief → rencana → eksekusi → pantau → sesuaikan. Lihat [[Siklus Project Adaptif]].
- **AI mengusulkan, pengguna memutuskan.** Setiap perubahan rencana tampil sebagai diff yang bisa diterima sebagian. Lihat [[Prinsip Produk]].
- **LLM memahami dan menulis, kode menghitung.** Tanggal, kapasitas, dan health score dihitung scheduler deterministik. Lihat [[Planning Engine]].
- **Grounded.** Jawaban merujuk dokumen project beserta halamannya. Lihat [[AI Engine]] dan [[Document Engine]].
- **Mode = preset** di atas satu inti. MVP hanya Academic Mode. Lihat [[Mode sebagai Preset]].

## Peta vault

![[Rampung.base#Semua catatan]]

| Area | Catatan |
| --- | --- |
| Produk | [[Visi dan Positioning]] · [[Prinsip Produk]] · [[Persona dan JTBD]] · [[Siklus Project Adaptif]] · [[Fitur MVP V1 V2]] · [[Mode sebagai Preset]] |
| Arsitektur | [[Struktur Sistem]] · [[AI Engine]] · [[Planning Engine]] · [[Document Engine]] · [[Tech Stack]] · [[Model Data]] · [[API]] |
| UX | [[Alur dan Layar]] · [[Bilingual ID-EN]] |
| Kualitas | [[Testing dan Evals]] · [[Operasional]] |
| Bisnis | [[Monetisasi]] · [[Go-to-Market]] · [[Metrik]] |
| Legal | [[Keamanan dan Privasi]] · [[Integritas Akademik]] |
| Rencana | [[Roadmap]] · [[Langkah Pertama 14 Hari]] · [[Risiko]] |
| Validasi (Fase 0) | [[Hipotesis]] · [[Panduan Wawancara Mahasiswa]] · [[Panduan Wawancara Dosen]] · [[Cek Nama]] · `Validasi/Hasil Wawancara.base` |
| Kerja | [[Log Keputusan]] · [[Pertanyaan Terbuka]] · [[Riwayat]] |
| Sumber | [[Master Plan]] · [[Knowledge Graph]] · [[Cara pakai vault ini]] |

## Tanggal penting

| Tanggal | Apa |
| --- | --- |
| 28 Sep 2026 | Fase 0 Validasi dimulai |
| 11 Okt 2026 | Review 14 hari pertama: lanjut atau ubah fokus |
| 19 Okt 2026 | Fase 1 Fondasi |
| 16 Nov 2026 | Fase 2 AI Core |
| 28 Des 2026 | Fase 3 Pantau dan Sesuaikan |
| 16 Jan 2027 | PP 33/2026 berlaku penuh |
| 1 Feb – 7 Mar 2027 | Beta tertutup |
| 16 Mar – Jun 2027 | V1 |
| Jul – Agu 2027 | Launch publik |

Detail dan kriteria keluar tiap fase ada di [[Roadmap]].
