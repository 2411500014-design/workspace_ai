---
type: index
area: Kerja
tags:
  - pertanyaan
updated: 2026-09-24
---

# Pertanyaan Terbuka

Hal yang belum diputuskan. Setelah diputuskan, buat catatan keputusan ([[Log Keputusan]]) lalu centang di sini.

## Nama dan merek
- [x] ~~Apakah **Rampung** tersedia sebagai domain, username media sosial, dan merek di PDKI?~~ Sudah dicek 2026-09-24. Ada merek terdaftar "Rampung Indonesia" di kelas 41 (pendidikan), dan `rampung.com` serta `rampung.id` sudah dipakai. → [[Cek Nama]]
- [x] ~~**Tetap memakai nama Rampung atau ganti?**~~ Ganti ke Purnara (2026-09-24, [[K-004 Nama produk Purnara]]). Catatan lama: Pertanyaannya: bisakah "Rampung" didaftarkan di kelas 9 dan 42, dan apa pilihan terhadap IDM000904862 (penghapusan karena tidak dipakai, pembelian, atau lisensi)? → [[K-001 Nama produk Rampung]]
- [x] ~~**Nama cadangan:** siapkan 3–4 nama dan cek.~~ Sudah 2026-09-24: finalisnya **Purnara** (direkomendasikan), Tonggak, dan Tekun. → [[Nama Cadangan]]
- [x] ~~**Pilih nama**~~ **Purnara**. → [[K-004 Nama produk Purnara]]
- [ ] **Kapan mendaftarkan merek Purnara dan membeli domain** (`purnara.com`, `purnara.id`)? Keduanya menunggu dana. Cek ulang ketersediaannya sebelum mengumumkan nama secara luas. → [[K-004 Nama produk Purnara]]

## Dua bahasa
- [ ] **Apakah semua teks English harus lengkap saat beta tertutup (1 Feb 2027)?** Peserta beta adalah mahasiswa Indonesia. Pilihan yang lebih ringan: key dan infrastruktur lengkap sejak Fase 1, terjemahan English menyusul per fitur, dan English lengkap saat launch publik. → [[K-002 Dua bahasa ID dan EN]]
- [ ] **Siapa pengguna English?** Pilihannya: mahasiswa Indonesia yang lebih nyaman dengan UI English, mahasiswa internasional di kampus Indonesia, atau pengguna di luar Indonesia. Jawabannya menentukan apakah perlu template akademik internasional selain alur Bab 1–5, sempro, dan sidang. → [[Persona dan JTBD]], [[Mode sebagai Preset]]
- [ ] **Bahasa jawaban AI:** ikut bahasa pertanyaan, ikut bahasa UI, atau pengaturan per project? Usulan: ikut bahasa pertanyaan, default ke bahasa UI. → [[Bilingual ID-EN]]
- [ ] Di UI English, istilah khas Indonesia ditampilkan bagaimana: diterjemahkan ("Thesis defense"), dibiarkan ("Sidang"), atau keduanya? → [[Bilingual ID-EN]]

## Repo dan setup
- [x] ~~Kapan kerangka Flutter dipindah ke `app/`?~~ Sudah dipindah 2026-09-24. → [[K-003 Vault dan struktur folder]]
- [ ] Ganti nama package `workspace_ai` menjadi `rampung`, setelah nama lolos cek merek. → [[K-003 Vault dan struktur folder]]
- [x] ~~Inisialisasi git~~ Sudah 2026-09-24, lokal di branch `main`.
- [ ] Buat remote GitHub (privat atau publik?) supaya CI berjalan. → [[Operasional]]

## Dari master plan (diputuskan lewat data)
- [ ] **Project Chat pakai kelas model apa?** Tabel workflow menulis "kuat atau ringan", tapi hitungan unit economics memakai kelas kuat untuk 60 panggilan per bulan. Ketidakkonsistenan ini ditemukan lewat [[Knowledge Graph]] dan paling besar pengaruhnya ke biaya AI. → [[AI Engine]], [[Monetisasi]]
- [ ] Model final per kelas, dipilih lewat evals. → [[AI Engine]]
- [ ] Model embedding: Voyage, OpenAI, atau bge-m3, dipilih lewat uji 50 pertanyaan. → [[Document Engine]]
- [ ] Celery atau ARQ untuk worker. → [[Tech Stack]]
- [ ] Harga Pro dan Paket Skripsi, divalidasi lewat Van Westendorp di beta. → [[Monetisasi]]
- [ ] Bobot skor prioritas (0,4 / 0,3 / 0,2 / 0,1), disetel ulang setelah beta. → [[Planning Engine]]

Terkait: [[Log Keputusan]] · [[Riwayat]] · [[Purnara]]
