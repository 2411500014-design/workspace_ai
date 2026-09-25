---
type: decision
area: Keputusan
status: diterima
tanggal: 2026-09-24
tags:
  - keputusan
  - roadmap
updated: 2026-09-24
---

# K-005 Mulai membangun aplikasi

## Konteks
Master plan meminta fitur baru dibangun **setelah** kriteria keluar Fase 0 terpenuhi (wawancara dan concierge test). Pada 2026-09-24 pemilik project sempat menahan pembangunan aplikasi, lalu di hari yang sama memintanya dimulai: "langsung eksekusi kodingan untuk pembuatan aplikasi, android maupun desktop/web, sesuai planning".

## Keputusan
Pembangunan aplikasi dimulai sekarang, paralel dengan validasi Fase 0. Iterasi pertama memuat fondasi dan inti produk (Fase 1 dan sebagian Fase 2): Flutter untuk web, Android, dan desktop, serta backend FastAPI dengan Planning Engine.

## Akibat
- **Risiko:** fitur bisa dibangun untuk masalah yang ternyata tidak dirasakan responden. Mitigasinya: prioritaskan inti yang tidak boleh dipotong ([[Roadmap]]), dan tetap jalankan wawancara serta concierge test. Hasil Fase 0 tetap bisa mengubah arah.
- **Tanpa dana:** semuanya harus bisa berjalan lokal tanpa layanan berbayar. Detailnya di ADR-0002 (`docs/adr/0002-pengembangan-lokal-tanpa-biaya.md`).
- Package Flutter diganti menjadi `purnara` sekarang, karena Fase 1 praktis sudah dimulai ([[K-004 Nama produk Purnara]]).

Terkait: [[Log Keputusan]] · [[Roadmap]] · [[Langkah Pertama 14 Hari]]
