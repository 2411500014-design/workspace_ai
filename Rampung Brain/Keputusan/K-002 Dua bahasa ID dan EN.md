---
type: decision
area: Keputusan
status: diterima
tanggal: 2026-09-24
tags:
  - keputusan
  - i18n
updated: 2026-09-24
---

# K-002 Dua bahasa ID dan EN

## Konteks
Master plan menaruh Bahasa Indonesia di MVP dan menyiapkan file terjemahan ARB Flutter sejak awal. Bahasa Inggris baru masuk di V1, bersama Research Mode dan paket Pro.

## Keputusan
Aplikasi dan web Rampung bisa dipakai dalam **Bahasa Indonesia dan English**. Pondasinya dipasang sejak Fase 1: setiap teks UI punya key di dua ARB, bahasa pengguna tersimpan di `profiles.locale`, dan AI, email, serta notifikasi mengikuti bahasa itu.

## Akibat
- English pindah dari daftar V1 ke MVP ([[Fitur MVP V1 V2]]).
- Setiap lapisan kena: UI, API (error sebagai kode), AI (prompt dan persona per bahasa), preset mode (istilah per bahasa), evals (kasus English), landing page (`/id`, `/en`), dan legal (kebijakan privasi Indonesia tetap wajib). Rinciannya di [[Bilingual ID-EN]].
- Menambah beban kerja Fase 1–3 yang belum dihitung di [[Roadmap]]. Dua risiko baru tercatat di [[Risiko]].
- Yang **belum** diputuskan: apakah semua teks English harus lengkap saat beta (1 Feb 2027), siapa pengguna English, dan aturan bahasa jawaban AI. Semuanya ada di [[Pertanyaan Terbuka]].

Terkait: [[Bilingual ID-EN]] · [[Log Keputusan]]
