---
type: note
area: Validasi
sumber: "§1–§3, §15, §16, §19"
status: draf
tags:
  - validasi
  - hipotesis
updated: 2026-09-24
---

# Hipotesis

> [!info] Draf pertama, 2026-09-24
> Halaman ini berisi yang kita *percaya* sebelum bicara dengan satu pun mahasiswa. Semuanya bisa salah. Fase 0 (28 Sep – 18 Okt 2026) ada untuk membuktikan atau membantahnya, lewat [[Panduan Wawancara Mahasiswa|wawancara]] dan concierge test. Perbarui halaman ini setelah review 11 Okt.

**Dalam satu kalimat:** banyak mahasiswa tingkat akhir molor bukan karena materinya terlalu sulit, tetapi karena pekerjaan sebesar skripsi tidak punya rencana yang hidup. Rampung menyusun rencana itu dari dokumen mereka sendiri dan menyesuaikannya setiap kali keadaan berubah.

## Calon pengguna

Mahasiswa S1/D4 tingkat akhir (semester 7 ke atas) yang mengerjakan skripsi atau TA sendirian. Sidangnya 3–9 bulan lagi, waktunya sekitar 10 jam per minggu, dan bimbingannya dengan satu atau dua dosen.

| # | Hipotesis | Diuji |
| --- | --- | --- |
| P1 | Segmen ini merasakan masalah pengelolaan paling tajam | Q1, Q2 |
| P2 | Mereka sudah memakai AI umum untuk skripsi, tetapi untuk menjelaskan atau menulis, bukan untuk merencanakan | Q9 |
| P3 | *(sekunder, dua bahasa)* Sebagian memakai perangkat dalam English, dan referensi mereka campuran Indonesia–English | Profil |

## Masalah

| # | Hipotesis | Tanda benar | Tanda salah | Diuji |
| --- | --- | --- | --- | --- |
| M1 | Tidak tahu langkah berikutnya, jadi menunda | Menyebut bingung mulai atau menunda tanpa diarahkan; minggu lalu tidak ada kerja skripsi yang jelas | Tahu persis langkah berikutnya; hambatannya hal lain | Q2, Q3, Q4 |
| M2 | Rencana dibuat sekali lalu ditinggal | Jadwal tidak dibuka atau diubah lebih dari 2 minggu, atau tidak punya sama sekali | Jadwal diperbarui rutin dan diikuti | Q5 |
| M3 | Revisi dosen tercecer, dan ada yang terlewat | Revisi dicatat di WhatsApp, kertas, atau ingatan; pernah ada yang terlewat | Semua revisi tercatat di satu tempat dan selesai | Q6, Q7 |
| M4 | Menyusun tinjauan pustaka dari puluhan jurnal itu lambat | Lebih dari 15 jurnal tersebar di folder unduhan; Bab 2 lama tertunda | Referensi rapi di Zotero atau Mendeley, dan Bab 2 lancar | Q8 |
| M5 | Baru sadar tertinggal menjelang tenggat | Cerita panik menjelang sempro atau sidang; tahu terlambat dari dosen atau teman | Sadar jauh hari dan sempat menyesuaikan | Q7 |

## Solusi

Rampung membaca proposal dan instruksi dosen, menyusun rencana sampai sidang, memberi tahu apa yang dikerjakan hari ini, dan mengusulkan penyesuaian saat tertinggal atau ada revisi. Pengguna selalu menyetujui setiap perubahan.

| # | Hipotesis | Diuji lewat concierge test | Tanda benar |
| --- | --- | --- | --- |
| S1 | Rencana yang disusun dari dokumen sendiri terasa masuk akal tanpa banyak diedit | Rencana disusun dengan Claude dari proposal peserta | Peserta menerima rencana dengan koreksi kecil |
| S2 | Ringkasan mingguan membuat peserta tetap mengikuti rencana | Digest dikirim manual setiap minggu | Minimal 3 dari 5 peserta masih mengikuti rencana di minggu kedua |
| S3 | Revisi yang langsung menjadi daftar task mengurangi yang terlewat | Catatan bimbingan peserta diubah jadi daftar revisi | Peserta memakai daftar itu di bimbingan berikutnya |

Chat bersitasi atas jurnal (M4) tidak diuji di Fase 0. Fitur itu diuji dengan evals di Fase 2 ([[Testing dan Evals]]).

## Harga

**Hipotesis:** Paket Skripsi Rp149.000–Rp199.000 sekali bayar lebih cocok daripada langganan Rp29.000–Rp49.000 per bulan, karena skripsi punya awal dan akhir ([[Monetisasi]]).

| # | Hipotesis | Diuji |
| --- | --- | --- |
| H1 | Mahasiswa sudah mengeluarkan uang untuk hal yang berhubungan dengan skripsi: langganan AI, aplikasi, kursus, jasa konsultasi, atau cetak | Q10 |
| H2 | Pengeluaran itu lebih sering sekali bayar daripada langganan | Q10 |

Di Fase 0 kita **tidak** bertanya "mau bayar berapa", karena jawabannya tidak bisa dipercaya. Yang dicatat adalah apa yang *sudah* mereka bayar. Uji harga dilakukan di beta dengan survei Van Westendorp.

## Asumsi paling berisiko

Diurutkan dari yang paling fatal jika salah:

1. **Kesulitan utamanya soal pengelolaan**, bukan materi, data, atau dosen. Jika salah, inti produk salah sasaran. (M1–M5)
2. **Rencana tetap dipakai setelah minggu pertama.** Jika salah, retensi runtuh. Ini risiko nomor dua di [[Risiko]]. (S2)
3. **Mereka mau membayar.** (H1, H2)

## Kriteria keluar Fase 0

Diambil dari [[Roadmap]]. Hitungannya muncul otomatis di `Hasil Wawancara.base`.

- [ ] Minimal **60%** responden menyebut hal pengelolaan di antara 3 kesulitan teratas. Jawabannya berasal dari Q2 tanpa diarahkan, lalu dikode setelah wawancara dengan kode yang sudah ditetapkan di [[Panduan Wawancara Mahasiswa]].
- [ ] Minimal **3 dari 5** peserta concierge masih mengikuti rencana di minggu kedua.

## Kalau hipotesisnya salah

- **Kesulitan teratas soal dosen** (sulit ditemui, lambat membalas): pertimbangkan fokus ke persiapan dan tindak lanjut bimbingan, dengan Log bimbingan sebagai inti produk.
- **Soal materi atau metode:** produk bergeser ke belajar dan menjelaskan referensi. Pasar itu jauh lebih ramai (ChatGPT, NotebookLM).
- **Soal menulis:** wilayah ini rawan integritas akademik ([[Integritas Akademik]]).
- **Rencana tidak diikuti di concierge:** cari tahu kenapa sebelum menulis kode apa pun.

Terkait: [[Panduan Wawancara Mahasiswa]] · [[Panduan Wawancara Dosen]] · [[Langkah Pertama 14 Hari]] · [[Persona dan JTBD]]
