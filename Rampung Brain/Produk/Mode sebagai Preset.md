---
type: note
area: Produk
sumber: "§5"
tags:
  - produk
  - mode
updated: 2026-09-24
---

# Mode sebagai Preset

Satu codebase, satu inti. Sebuah **mode** hanyalah preset konfigurasi yang disuntikkan ke Intelligence Layer dan Core Engines (lihat [[Struktur Sistem]]). Menambah mode baru cukup dengan konfigurasi, tanpa engine baru.

Rencana urutan mode: **Academic** (MVP) → Research (V1) → Developer, Work, Personal (V2).

## Isi sebuah preset

| Isi konfigurasi | Academic (MVP) | Developer (V2) |
| --- | --- | --- |
| Template project | Skripsi, TA, makalah, lomba atau PKM | Side project, MVP startup, hackathon |
| Istilah di UI | Bab, bimbingan, seminar, sidang | Sprint, issue, rilis |
| Persona AI | Pembimbing akademik | Tech lead |
| Fitur khusus | Log bimbingan, matriks literatur, format sitasi | Sinkron GitHub, changelog |
| Skema ekstraksi dokumen | Syarat dosen, rubrik, tanggal seminar | Spesifikasi, acceptance criteria |

## Penyimpanan

Konfigurasi mode disimpan sebagai **file YAML berversi di repo** (folder `modes/`, lihat [[Tech Stack]]). Konfigurasi baru pindah ke database saat pengguna mulai membuat template sendiri.

## Dampak dua bahasa

Setiap preset membawa teks yang tampil ke pengguna: nama template, istilah UI, dan persona AI. Karena Rampung dua bahasa, field seperti ini perlu versi `id` dan `en` di YAML. Contoh bentuknya:

```yaml
terms:
  chapter:     { id: "Bab",        en: "Chapter" }
  supervision: { id: "Bimbingan",  en: "Supervision" }
  proposal_seminar: { id: "Seminar proposal", en: "Proposal seminar" }
  defense:     { id: "Sidang",     en: "Thesis defense" }
```

Ini baru sketsa. Istilah akademik Indonesia tidak selalu punya padanan persis, dan cara menampilkannya di UI English masih terbuka. Lihat [[Bilingual ID-EN]] dan [[Pertanyaan Terbuka]].

Terkait: [[Persona dan JTBD]] · [[AI Engine]] · [[K-002 Dua bahasa ID dan EN]]
