---
type: note
area: UX
sumber: "§6, §12 + keputusan 2026-09-24"
tags:
  - ux
  - i18n
  - bilingual
updated: 2026-09-24
---

# Bilingual ID-EN

Purnara memakai **Bahasa Indonesia dan English**. Keputusannya ada di [[K-002 Dua bahasa ID dan EN]]. Catatan ini menjelaskan artinya di setiap lapisan produk.

## Apa yang berubah dari master plan

| | Master plan | Sekarang |
| --- | --- | --- |
| UI | Indonesia dulu, file ARB disiapkan sejak awal | Indonesia **dan** English |
| English | V1, bersama Research Mode | Masuk sejak fondasi (Fase 1) |
| Kebijakan privasi | Berbahasa Indonesia (syarat PP 33/2026) | Tetap wajib Indonesia; English sebagai terjemahan |

Menyiapkan dua bahasa sejak hari pertama jauh lebih murah daripada menambalnya belakangan. Biaya tambahannya ada di penerjemahan setiap teks dan dataset evals yang jadi dua kali lipat.

## Per lapisan

### Flutter (UI)
- Pakai gen-l10n bawaan Flutter: `flutter_localizations` + `intl`, dengan file ARB `app_id.arb` dan `app_en.arb` di `lib/l10n/`.
- **Tidak ada teks UI yang ditulis langsung di widget.** Semua lewat `AppLocalizations`.
- Bahasa default mengikuti perangkat. Pengguna bisa mengubahnya di Pengaturan, dan pilihannya disimpan di `profiles.locale` ([[Model Data]]). Bahasa selain `id` dan `en` jatuh ke `id`.
- Tanggal, angka, dan rupiah diformat lewat `intl` sesuai locale. Contoh: "24 Sep 2026" dan "Rp29.000". Harga tetap dalam rupiah di kedua bahasa.
- Bentuk jamak dan variabel memakai format ICU di ARB, bukan string yang disambung manual.
- CI mengecek bahwa kedua ARB punya key yang sama. Key yang belum diterjemahkan membuat build gagal.

### Backend dan API
- Error dikirim sebagai **kode**, lalu diterjemahkan di Flutter. Lihat [[API]].
- Email (Resend/Brevo) dan notifikasi memakai template per bahasa, dipilih dari `profiles.locale`.

### AI
- Instruksi sistem menyebut bahasa jawaban. Usulan aturan: jawab dalam bahasa pertanyaan pengguna; untuk output tanpa pertanyaan (brief, review mingguan, re-plan), pakai `profiles.locale`. Aturan ini belum diputuskan dan ada di [[Pertanyaan Terbuka]].
- Persona AI per mode punya versi `id` dan `en`. Contohnya "pembimbing akademik" dan "academic supervisor". Lihat [[Mode sebagai Preset]].
- Prompt disimpan berversi di repo, per bahasa. Setiap pesan AI mencatat versi prompt dan bahasanya.
- Prefix yang di-cache berbeda per bahasa. Ini tidak masalah, cukup diperhitungkan di estimasi biaya ([[Monetisasi]]).
- Sitasi tidak terpengaruh. Kutipan tetap dalam bahasa dokumen aslinya.
- Model embedding sudah direncanakan multilingual ([[Document Engine]]). Pertanyaan dalam English harus bisa menemukan jurnal berbahasa Indonesia, dan sebaliknya.

### Mode dan istilah akademik
- Istilah seperti Bab, bimbingan, seminar proposal, sidang, sempro, PKM, dan UTS/UAS tidak selalu punya padanan persis.
- Template Academic Mode mengikuti alur kampus Indonesia (Bab 1–5). Apakah versi English perlu template internasional (thesis chapters, proposal defense, viva) tergantung siapa pengguna English-nya. Lihat [[Pertanyaan Terbuka]].

### Evals
- Dataset evals ([[Testing dan Evals]]) perlu kasus English juga: pertanyaan English ke dokumen Indonesia, dokumen campuran, dan brief dalam English.
- Tambahkan cek otomatis bahwa jawaban memakai bahasa yang benar.

### Landing page dan legal
- Landing page (Astro) memakai rute `/id` dan `/en` dengan tag `hreflang` untuk SEO.
- Kebijakan privasi dan persetujuan saat daftar **wajib tersedia dalam Bahasa Indonesia**. Versi English adalah terjemahan, dan versi Indonesia yang berlaku jika ada perbedaan. Lihat [[Keamanan dan Privasi]].

## Nada di kedua bahasa

Prinsip *tanpa menghakimi* ([[Prinsip Produk]]) berlaku di kedua bahasa. Terjemahan harus netral dan tidak menyalahkan. Contoh: "Rencana perlu disesuaikan" / "Your plan needs an adjustment", bukan "Kamu tertinggal" / "You're behind".

Terkait: [[K-002 Dua bahasa ID dan EN]] · [[Alur dan Layar]] · [[Tech Stack]]
