---
type: note
area: Produk
sumber: "§6"
tags:
  - produk
  - scope
updated: 2026-09-24
---

# Fitur MVP, V1, V2

Semua kemampuan AI yang diminta masuk MVP, masing-masing dalam versi paling sederhana. Yang ditunda adalah platform, kolaborasi, dan mode lain. MVP = **Academic Mode versi web**.

## MVP: kemampuan → fitur

| Kemampuan | Fitur | Versi MVP | Engine |
| --- | --- | --- | --- |
| Memecah project jadi tahap | Plan Generator | Milestone dari template + isi brief | AI, Planning |
| Milestone, task, subtask | Plan Generator | Tiga level | AI, Task |
| Dependensi | Dependency graph | Hanya finish-to-start, deteksi siklus otomatis | Task, Planning |
| Prioritas | Priority score | Skor dari jalur kritis, slack, jumlah task yang menunggu | Planning |
| Menyesuaikan dengan deadline | Scheduler | Jadwal mundur dari deadline, buffer 15%, kapasitas jam/minggu | Planning |
| Mengingatkan saat tertinggal | Health score + pengingat | Cek harian, email dan notifikasi in-app | Insight |
| Membaca dokumen | Document ingestion | PDF dan DOCX, ringkasan per dokumen | Document |
| Menjawab berdasarkan konteks | Project Chat | Jawaban dengan sitasi nama dokumen dan halaman | AI, Document |
| Membantu draft atau struktur | Outline Assistant | Kerangka bab dan poin per subbab dari referensi | AI |
| Menunjukkan yang belum selesai | Checklist syarat + progress | Syarat dosen ditautkan ke task; syarat tanpa task ditandai merah | Project, Insight |
| Menyesuaikan saat ada perubahan | Re-plan | Usulan diff dengan 2–3 opsi pemulihan | AI, Planning |

Wizard intake MVP memuat kesembilan input awal, dari judul sampai target.

## MVP: fitur pendukung

- Login email dan Google, satu workspace pribadi per pengguna.
- Tampilan List, Board, dan Timeline sederhana, plus halaman **Fokus Hari Ini**.
- Aksi AI langsung di task: *Pecah task ini*, *Bantu saya mulai*, *Jelaskan dari referensi*.
- Log bimbingan: catatan pertemuan dosen diubah AI menjadi usulan task revisi.
- Review mingguan otomatis setiap Minggu malam.
- Kuota AI per pengguna, tombol suka/tidak suka di setiap jawaban AI, halaman admin pemakaian token.
- **Dua bahasa, Indonesia dan English.** Ini tambahan dari master plan, yang semula menaruh English di V1. Lihat [[K-002 Dua bahasa ID dan EN]].

## V1 (setelah beta)

- Aplikasi Android dengan push notification; iOS menyusul.
- Project kelompok: undang anggota, assign task, jejak kontribusi.
- Matriks literatur, metadata referensi, sitasi APA dan IEEE, validasi DOI.
- Sinkron satu arah ke Google Calendar.
- Focus session dengan timer dan kalibrasi estimasi pribadi.
- Umpan balik draft: unggah draf bab, AI memberi komentar per bagian.
- Research Mode dan paket Pro berbayar. (~~Bahasa Inggris~~ sudah pindah ke MVP.)

## V2 (setelah product-market fit)

- Developer Mode (sinkron GitHub), Work Mode, Personal Mode.
- Dashboard dosen pembimbing dan paket institusi untuk kampus.
- Impor dari Google Drive dan Notion, pengingat via WhatsApp.
- Capture suara di mobile, mode offline, marketplace template.
- Agen AI multi-langkah dengan batas persetujuan yang jelas.

## Ditunda (nanti dulu)

| Ditunda | Alasan |
| --- | --- |
| Editor dokumen penuh seperti Google Docs | Pengguna tetap menulis di Word atau Docs; Rampung mengelola project dan membaca drafnya |
| Aplikasi mobile di MVP | Web cukup untuk membuktikan nilai; store review memperlambat iterasi |
| Kolaborasi dan izin akses | Menambah kompleksitas data dan keamanan sebelum nilai inti terbukti |
| Fine-tuning atau self-host model | Model API cukup; biaya dan perawatannya belum sebanding |
| Agen otonom | Workflow terstruktur lebih mudah diuji dan diprediksi |

## Kalau jadwal molor

Urutan potong scope yang aman ada di [[Roadmap]]. Inti yang tidak boleh dipotong: Brief, Plan Generator, scheduler, health score, re-plan, dan chat bersitasi.

Terkait: [[Siklus Project Adaptif]] · [[Alur dan Layar]] · [[Roadmap]]
