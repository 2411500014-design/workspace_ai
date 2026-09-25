---
type: log
area: Kerja
tags:
  - riwayat
updated: 2026-09-25
---

# Riwayat

Catatan bertanggal tentang apa yang terjadi di project ini. Entri terbaru ditaruh di atas. Satu baris per kejadian yang berarti.

## 2026-09

- **2026-09-25**: **Tampilan aplikasi dipoles agar terasa premium**, tanpa mengganti identitasnya (teal, Plus Jakarta Sans, tata letak tetap). Netral dibuat lebih tenang sehingga teal menjadi satu-satunya aksen, kartu diberi kedalaman halus, loading memakai skeleton, gerak halus dan menghormati setelan "kurangi gerak", layar sambutan kini menampilkan pratinjau aplikasi, dan logo baru (huruf P dengan cincin tertutup, dari *purna*) di atas *squircle* teal bergradasi dipakai di semua ikon platform, termasuk adaptive icon Android, favicon SVG, dan gambar pratinjau saat link dibagikan. Dicek lewat screenshot desktop dan ponsel, terang dan gelap. Aturannya dicatat di `design-system/purnara/MASTER.md`.
- **2026-09-25**: **Versi pertama aplikasi jalan**, lokal tanpa biaya. → [[K-005 Mulai membangun aplikasi]]
  - Aplikasi Flutter (package `purnara`) untuk web, Android, dan desktop. Isinya setup project 6 langkah, Hari Ini, Rencana (daftar, papan, linimasa), detail task, Project, Sesuaikan rencana, Dokumen, Asisten bersitasi, Brief, Log bimbingan, Review mingguan, dan Pengaturan. Semua teks ada dalam `id` dan `en` (323 kunci).
  - Backend FastAPI: planning engine, dokumen, AI gateway dengan versi dasar tanpa AI, usulan (diff), dan health harian. Backend juga melayani hasil build web di port 8000.
  - Diuji: 58 test backend (termasuk properti Hypothesis) dan 16 test Flutter lolos, termasuk cek bahwa kedua bahasa lengkap. Alur lengkap dicoba di browser dalam dua bahasa dan dua tema.
  - Hypothesis menemukan satu kasus tepi: rencana yang kurang beberapa detik ditandai tidak muat tapi kekurangannya 0 jam. Sudah diperbaiki.
  - Heuristik tanpa AI diperbaiki dari hasil uji di browser: label tanggal penting diambil dari kata sebelum tanggal, deadline tidak lagi masuk syarat dosen, dan usulan pembaruan brief ditutup otomatis kalau brief yang disimpan sudah memuat syaratnya.
  - Konfigurasi VS Code (`.vscode/`) untuk menjalankan backend dan aplikasi dengan F5. CI sekarang juga memeriksa backend.
  - Catatan: Android SDK dan Visual Studio (C++) belum terpasang di laptop, jadi build Android dan Windows belum dicoba.
- **2026-09-24**: **Pembangunan aplikasi dimulai**, paralel dengan Fase 0. Semua bagian dibuat bisa jalan lokal tanpa layanan berbayar: SQLite, file lokal, satu pengguna tanpa login, pencarian BM25, dan AI opsional. → [[K-005 Mulai membangun aplikasi]] · ADR-0002
- **2026-09-24**: **Nama produk menjadi Purnara**, menggantikan Rampung. Vault diganti nama menjadi *Purnara Brain*, dan beranda menjadi [[Purnara]]. Semua rujukan ke produk di vault dan repo ikut diganti; catatan riwayat dan cek nama tetap apa adanya. Untuk sekarang hanya GitHub yang diamankan, karena belum ada dana untuk domain dan merek. → [[K-004 Nama produk Purnara]]
- **2026-09-24**: 16 nama cadangan dicek (merek di PDKI, domain lewat RDAP, username).
  - Finalis: **Purnara** (direkomendasikan; .com, .ai, .app, dan .id tersedia, tidak ada merek serupa di kelas 9/41/42), **Tonggak**, dan **Tekun**.
  - Tuntask dan Setapak dicoret karena ada merek terdaftar di kelas 41 atau 9.
  - → [[Nama Cadangan]]
- **2026-09-24**: Nama **Rampung** dicek:
  - Merek terdaftar "Rampung Indonesia" ditemukan di kelas 41 (pendidikan, IDM000904862, berlaku sampai 2029).
  - `rampung.com` dan `rampung.id` sudah dipakai; `rampung.ai` dan `rampung.app` tersedia.
  - Username `rampung` sudah dipakai (tidak aktif) di TikTok, X, YouTube, dan GitHub.
  - K-001 berubah menjadi *ditinjau ulang*, menunggu konsultan KI. → [[Cek Nama]]
- **2026-09-24**: Bahan Fase 0 selesai dirancang:
  - [[Hipotesis]]: calon pengguna, 5 hipotesis masalah, 3 hipotesis solusi, 2 hipotesis harga, dan asumsi paling berisiko.
  - [[Panduan Wawancara Mahasiswa]]: 10 pertanyaan *The Mom Test*, kode kesulitan yang ditetapkan sebelum wawancara, dan teks izin untuk concierge test.
  - [[Panduan Wawancara Dosen]]: 6 pertanyaan.
  - Template catatan wawancara dan `Hasil Wawancara.base`, yang menghitung kriteria keluar Fase 0 secara otomatis. Tabelnya sudah dicek dengan dua catatan contoh, lalu contohnya dihapus.
- **2026-09-24**: Repo disusun sebagai monorepo sesuai master plan. Kerangka Flutter dipindah ke `app/`, lalu dibuat `backend/`, `modes/`, `evals/` (baru berisi README), `docs/adr/0001-pilihan-stack.md`, README root, dan CI GitHub Actions. `flutter analyze` dan `flutter test` lolos sebelum dan sesudah dipindah. Git lokal diinisialisasi dengan commit pertama. → [[K-003 Vault dan struktur folder]]
- **2026-09-24**: Ditetapkan: **aplikasi belum dibangun selama Fase 0**. Pemasangan l10n dan penggantian nama package ditunda. → [[Langkah Pertama 14 Hari]]
- **2026-09-24**: Master plan "AI Academic Workspace" selesai ditulis (43 halaman, 19 bagian). Disalin ke `docs/`. → [[Master Plan]]
- **2026-09-24**: Nama produk ditetapkan: **Rampung** / Rampung AI. → [[K-001 Nama produk Rampung]]
- **2026-09-24**: Diputuskan aplikasi dan web memakai **Bahasa Indonesia dan English**. English pindah dari V1 ke MVP. → [[K-002 Dua bahasa ID dan EN]]
- **2026-09-24**: Folder project ditetapkan di `D:\Workspace AI\workspace_ai`. Isinya kerangka Flutter bawaan (package `workspace_ai`, Dart SDK ^3.13.3) dan belum ada git.
- **2026-09-24**: Vault **Rampung Brain** dibuat di dalam folder project, berisi 35 catatan: ringkasan master plan per area, log keputusan, dan pertanyaan terbuka. Vault didaftarkan di Obsidian; Obsidian CLI sudah dicek (`vault=` harus ditulis sebelum perintah). → [[K-003 Vault dan struktur folder]]
- **2026-09-24**: Knowledge graph dibangun dari master plan dengan graphify (`graphify-out/`). → [[Knowledge Graph]]

## Berikutnya
- **2026-09-28**: Fase 0 Validasi dimulai. → [[Langkah Pertama 14 Hari]]

Terkait: [[Purnara]] · [[Log Keputusan]]
