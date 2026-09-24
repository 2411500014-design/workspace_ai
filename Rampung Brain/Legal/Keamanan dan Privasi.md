---
type: note
area: Legal
sumber: "§13"
tags:
  - legal
  - privasi
  - keamanan
updated: 2026-09-24
---

# Keamanan dan Privasi

Rampung menyimpan dokumen dan rencana studi pengguna, jadi keamanan dan kepatuhan UU PDP masuk scope MVP. **PP 33/2026**, aturan pelaksana UU PDP, berlaku penuh **16 Jan 2027**, sekitar dua minggu sebelum beta.

> [!warning] Bukan nasihat hukum
> Ini ringkasan teknis dari master plan. Minta ahli hukum meninjau kebijakan privasi dan DPIA sebelum rilis publik. Master plan mengutip UU 27/2022 Pasal 46 (Pasal.id) dan ringkasan PP 33/2026 (Veritask), dibaca 24 Sep 2026.

Latar belakang hukumnya sudah dirangkum di brain umum: `D:\GuardID\Obsidian\Topics\UU PDP and PP 33-2026.md`. Catatan itu ditulis untuk project GuardID, tapi instrumen hukumnya sama.

## Kewajiban UU PDP yang relevan

| Kewajiban | Penerapan di produk | Dasar |
| --- | --- | --- |
| Dasar pemrosesan sah, misalnya persetujuan eksplisit | Persetujuan jelas saat daftar, **kebijakan privasi berbahasa Indonesia** | PP 33/2026 Pasal 30 |
| Hak subjek data lewat kanal permohonan elektronik | Fitur ekspor data dan hapus akun di dalam aplikasi | PP 33/2026 Pasal 20–27 |
| Pemberitahuan kegagalan pelindungan data paling lambat 3 × 24 jam | Runbook insiden, template pemberitahuan, log akses | UU PDP Pasal 46; PP 33/2026 Pasal 114 |
| Penilaian dampak sebelum pemrosesan berisiko tinggi (teknologi baru, penskoran, pemantauan sistematis) | DPIA sederhana sebelum rilis publik | PP 33/2026 Pasal 120–122 |
| Transfer data ke luar negeri | API LLM berada di luar negeri: jelaskan tujuan, mekanisme, dan risikonya; pastikan perlindungan setara atau minta persetujuan | PP 33/2026 Pasal 160–166 |

**Dua bahasa:** versi English kebijakan privasi dan persetujuan boleh ada, tetapi versi Indonesia wajib tersedia dan menjadi acuan. Lihat [[Bilingual ID-EN]].

## Keamanan aplikasi

- FastAPI memverifikasi JWT Supabase di setiap request. Satu fungsi pusat mengecek akses pengguna ke workspace dan project. Row Level Security Supabase menjadi lapis kedua.
- File disimpan di bucket privat dan diakses lewat signed URL berumur 10 menit, dengan validasi tipe, ukuran, dan nama file acak.
- **API key LLM hanya ada di server.** Aplikasi Flutter tidak pernah memegang kunci rahasia.
- Rate limit per pengguna dan per IP, verifikasi email, dan captcha saat daftar untuk mencegah penyalahgunaan kredit AI gratis.
- HTTPS di semua jalur, enkripsi at rest dari penyedia, backup harian, dan uji restore setiap bulan.
- Dependabot untuk celah dependensi, audit log untuk aksi sensitif, service key dengan hak akses minimum.
- Pastikan ketentuan provider LLM menyatakan data API tidak dipakai untuk melatih model, lalu tulis hal itu di kebijakan privasi.
- Google Play dan App Store mewajibkan opsi hapus akun di dalam aplikasi. Fitur ini dibangun sejak MVP web.

Dokumen unggahan juga diperlakukan sebagai data, bukan perintah. Lihat guardrails di [[AI Engine]].

Terkait: [[Integritas Akademik]] · [[Model Data]] · [[Risiko]] · [[Operasional]]
