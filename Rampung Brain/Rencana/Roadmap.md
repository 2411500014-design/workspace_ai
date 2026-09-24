---
type: note
area: Rencana
sumber: "§16"
tags:
  - rencana
  - roadmap
updated: 2026-09-24
---

# Roadmap

Validasi sampai MVP siap butuh empat fase (17 minggu). Beta tertutup berjalan **1 Feb – 7 Mar 2027**, lalu launch publik menyasar awal semester ganjil, **Agustus 2027**.

**Asumsi:** satu developer, 15–20 jam per minggu, mulai **28 Sep 2026**. Setiap fase punya kriteria keluar, dan fase berikutnya dimulai setelah kriteria itu terpenuhi.

| Fase | Waktu | Isi utama | Kriteria keluar |
| --- | --- | --- | --- |
| **0. Validasi** | 28 Sep – 18 Okt 2026 | Wawancara 10–15 mahasiswa dan 2 dosen, concierge test 5 project (rencana disusun manual dengan Claude dan spreadsheet), prototipe Figma, spesifikasi MVP | ≥ 60% responden menyebut pengelolaan skripsi sebagai 3 kesulitan teratas; 3 dari 5 peserta concierge masih mengikuti rencana di minggu kedua |
| **1. Fondasi** | 19 Okt – 15 Nov 2026 | Monorepo, auth, skema database dan migrasi, CRUD project dan task, UI dasar Flutter web **dengan l10n ID/EN**, CI/CD, staging | Di staging, pengguna bisa daftar, membuat project, dan mengelola task; CI hijau di setiap merge |
| **2. AI Core** | 16 Nov – 27 Des 2026 | Ingestion dokumen, Project Brief, Plan Generator, scheduler, kartu usulan (diff), Project Chat bersitasi | Dari proposal nyata, rencana siap diterima dalam 10 menit; target kualitas AI ([[Metrik]]) tercapai pada dataset evals |
| **3. Pantau dan Sesuaikan** | 28 Des 2026 – 24 Jan 2027 | Progress, health score, pengingat email, re-plan, review mingguan, log bimbingan | Satu siklus penuh (tertinggal → diingatkan → re-plan → rencana baru diterima) berhasil di 5 project uji |
| **Buffer** | 25 – 31 Jan 2027 | Perbaikan bug, onboarding peserta beta, cek biaya dan monitoring | Backup, Sentry, kuota AI, dan kebijakan privasi siap |
| **4. Beta tertutup** | 1 Feb – 7 Mar 2027 | 20–50 mahasiswa tingkat akhir, rilis mingguan, wawancara pengguna setiap minggu | Aktivasi, retensi W4, dan tes Sean Ellis mencapai target awal ([[Metrik]]) |
| **5. V1** | 16 Mar – Jun 2027 | Android dan push notification, project kelompok, matriks literatur, Google Calendar, paket berbayar ([[Fitur MVP V1 V2]]) | Pembayaran pertama masuk; sesi bebas crash > 99% |
| **6. Launch publik** | Jul – Agu 2027 | Rilis Play Store, landing page, kampanye awal semester, ambassador kampus | Target pertumbuhan ditetapkan dari data beta dan V1 |

Penambahan English ([[K-002 Dua bahasa ID dan EN]]) paling terasa di Fase 1: infrastruktur l10n dan kebiasaan menulis setiap teks di dua ARB. Master plan belum menghitung jam untuk ini.

## Kalender yang memengaruhi jadwal

- Libur Nyepi dan Idulfitri 1448 H berlangsung **8–15 Maret 2027** menurut SKB 3 Menteri tentang libur 2027 (dicek 24 Sep 2026). Karena itu beta ditutup 7 Mar 2027, setelah data retensi W4 kohort pertama terkumpul. Tanggal Idulfitri final tetap mengikuti keputusan Menteri Agama.
- Sebagian besar masa beta jatuh di bulan Ramadan, jadi jam aktif pengguna akan bergeser.
- Fase 2 dan 3 melewati Natal, tahun baru, dan musim UAS. Kalau jadwal padat, hitung minggu-minggu itu setengah kapasitas dan pakai minggu buffer.
- PP 33/2026 berlaku penuh 16 Jan 2027 ([[Keamanan dan Privasi]]).

## Aturan saat molor

Kalau satu fase molor lebih dari 2 minggu, **potong scope dulu, baru geser tanggal.** Urutan potong yang aman:

1. Log bimbingan pindah ke V1.
2. Tampilan Timeline ditunda; List dan Board sudah cukup.
3. Review mingguan diganti email ringkasan sederhana.
4. Re-plan cukup memberi satu opsi pemulihan.

**Jangan potong inti produk:** Brief, Plan Generator, scheduler, health score, re-plan, dan chat bersitasi. Kalau fase selesai lebih cepat, pakai sisa waktu untuk dogfooding dan evals.

Terkait: [[Langkah Pertama 14 Hari]] · [[Risiko]] · [[Fitur MVP V1 V2]]
