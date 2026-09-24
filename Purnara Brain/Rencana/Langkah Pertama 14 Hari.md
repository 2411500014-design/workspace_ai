---
type: note
area: Rencana
sumber: "§19"
tags:
  - rencana
  - checklist
updated: 2026-09-24
---

# Langkah Pertama 14 Hari

**28 Sep – 11 Okt 2026.** Dua minggu pertama dipakai untuk menguji masalah dan menyiapkan fondasi teknis. Fitur baru dibangun setelah kriteria keluar Fase 0 terpenuhi ([[Roadmap]]).

Centang langsung di Obsidian. Setelah selesai, catat hasilnya di [[Riwayat]].

## Minggu 1: pahami masalahnya (28 Sep – 4 Okt)

- [x] Tulis satu halaman hipotesis: masalah, calon pengguna, solusi, dan harga yang mungkin dibayar. → [[Hipotesis]] *(draf 2026-09-24, baca ulang sebelum wawancara pertama)*
- [x] Susun 10 pertanyaan wawancara tentang cara responden mengelola skripsi sekarang. Tanyakan kejadian nyata dan jangan menawarkan ide, sesuai prinsip buku *The Mom Test*. → [[Panduan Wawancara Mahasiswa]], ditambah 6 pertanyaan untuk dosen di [[Panduan Wawancara Dosen]]. *(draf 2026-09-24; uji coba dulu dengan satu teman)*
- [ ] Jadwalkan 10–15 wawancara mahasiswa tingkat akhir dari minimal 3 prodi, plus 2 dosen pembimbing.
- [ ] Rekrut 5 peserta concierge test dan minta proposal atau draf mereka dengan izin tertulis.
- [x] Cek ketersediaan nama **Rampung**: domain, username media sosial, dan merek terdaftar di PDKI milik DJKI. *Selesai 2026-09-24.* Ada merek terdaftar "Rampung Indonesia" di kelas 41, jadi nama ini perlu ditinjau konsultan KI. → [[Cek Nama]]
- [x] Cek nama cadangan dengan cara yang sama. *Selesai 2026-09-24: 16 nama dicek, dengan tiga finalis Purnara, Tonggak, dan Tekun.* → [[Nama Cadangan]]
- [x] Pilih nama: **Purnara** (2026-09-24). → [[K-004 Nama produk Purnara]]
- [ ] Amankan nama **Purnara** di GitHub (gratis).
- [ ] *Saat ada dana:* daftarkan merek Purnara di DJKI (kelas 9 dan 42, pertimbangkan 41) dan beli domain `purnara.com` atau `purnara.id`. Cek ulang ketersediaannya dulu.
- [x] Siapkan monorepo (`app/`, `backend/`, `modes/`, `evals/`, `docs/adr/`), README, ADR-001 tentang pilihan stack, dan lint di GitHub Actions. *Selesai 2026-09-24. CI baru berjalan setelah ada remote GitHub.* Lihat [[K-003 Vault dan struktur folder]].
- [ ] ~~Pasang l10n Flutter dengan dua ARB (`id`, `en`)~~ **Ditunda:** aplikasi belum dibangun selama Fase 0. Pasang sebagai langkah pertama saat Fase 1 dimulai, sebelum layar pertama dibuat ([[Bilingual ID-EN]]).

## Minggu 2: uji solusinya (5 – 11 Okt)

- [ ] Jalankan concierge test: susun brief dan rencana 5 project dengan Claude, kirim digest mingguan secara manual, dan catat setiap koreksi peserta.
- [ ] Bangun prototipe scheduler Python murni (graf dependensi, jalur kritis, kapasitas) lengkap dengan test Hypothesis ([[Planning Engine]], [[Testing dan Evals]]).
- [ ] Buat prototipe Figma untuk onboarding, Fokus Hari Ini, dan kartu usulan AI, lalu uji ke 5 orang ([[Alur dan Layar]]).
- [ ] Buat project Supabase di region Singapura untuk development dan aktifkan pgvector ([[Tech Stack]]).
- [ ] Mulai dataset evals: 10 project dan 20 pertanyaan dengan jawaban acuan, semua data peserta dianonimkan.
- [ ] Kelola satu project nyata milik sendiri dengan alur concierge yang sama. Kandidatnya riset SLR NPC RTS ([[Persona dan JTBD]]).

## Review 11 Okt 2026

- [ ] Rangkum temuan, cek kriteria keluar Fase 0, lalu putuskan lanjut atau ubah fokus.
- [ ] Perbarui master plan sesuai temuan, lalu perbarui catatan vault yang terdampak.

Terkait: [[Roadmap]] · [[Pertanyaan Terbuka]]
