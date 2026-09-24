---
type: log
area: Kerja
tags:
  - riwayat
updated: 2026-09-24
---

# Riwayat

Catatan bertanggal tentang apa yang terjadi di project ini. Entri terbaru ditaruh di atas. Satu baris per kejadian yang berarti.

## 2026-09

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

Terkait: [[Rampung]] · [[Log Keputusan]]
