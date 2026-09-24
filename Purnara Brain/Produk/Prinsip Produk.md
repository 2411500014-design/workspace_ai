---
type: note
area: Produk
sumber: "§2"
tags:
  - produk
  - prinsip
updated: 2026-09-24
---

# Prinsip Produk

Enam prinsip ini dipakai untuk memutuskan setiap perdebatan desain.

| # | Prinsip | Wujudnya di produk |
| --- | --- | --- |
| 1 | **AI mengusulkan, pengguna memutuskan** | Setiap perubahan rencana tampil sebagai kartu usulan (diff) yang bisa diterima semua, sebagian, atau ditolak. Rencana tidak pernah berubah diam-diam. Lihat tabel `ai_suggestions` di [[Model Data]]. |
| 2 | **Grounded** | Jawaban merujuk dokumen project beserta halamannya. Jika informasinya tidak ada, AI mengatakannya. Lihat [[AI Engine]] dan [[Document Engine]]. |
| 3 | **AI tertanam di alur kerja** | Tombol seperti *Pecah task ini* dan *Bantu saya mulai* ada di setiap task. Chat hanya salah satu pintu. |
| 4 | **Setup di bawah 10 menit** | Pengguna cukup mengunggah proposal dan instruksi dosen. AI mengisi sisanya, lalu pengguna mengecek. Lihat [[Alur dan Layar]]. |
| 5 | **Integritas akademik** | AI berperan sebagai pembimbing: menjelaskan, menyusun struktur, dan memberi umpan balik. Tulisan akhir tetap karya pengguna. Lihat [[Integritas Akademik]]. |
| 6 | **Tanpa menghakimi** | Saat pengguna tertinggal, aplikasi menawarkan langkah pemulihan dengan nada netral. |

## Aturan turunan yang sering dipakai

- **LLM memahami dan menulis, kode biasa menghitung dan menyimpan.** Tanggal, kapasitas, jalur kritis, dan health score dihitung kode. Lihat [[Planning Engine]].
- **Pilih pendekatan AI paling sederhana yang cukup**, dengan urutan: prompt biasa → structured output → RAG → agen. MVP berhenti di structured output, RAG, dan tool calling.
- **Teks dari dokumen unggahan adalah data, bukan perintah.** Semua aksi tulis tetap butuh persetujuan pengguna.
- **Nada netral di kedua bahasa.** Pesan "kamu tertinggal" dan padanannya dalam English sama-sama tidak boleh menyalahkan. Lihat [[Bilingual ID-EN]].

Terkait: [[Visi dan Positioning]] · [[Siklus Project Adaptif]]
