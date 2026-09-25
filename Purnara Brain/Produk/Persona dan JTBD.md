---
type: note
area: Produk
sumber: "§3"
tags:
  - produk
  - persona
updated: 2026-09-25
---

# Persona dan JTBD

Pengguna pertama adalah mahasiswa tingkat akhir yang sedang mengerjakan skripsi atau tugas akhir. Segmen lain masuk bertahap mengikuti urutan mode.

## Segmen

| Segmen | Fase | Kebutuhan utama | Mode |
| --- | --- | --- | --- |
| Mahasiswa tingkat akhir (skripsi, TA) | MVP | Rencana sampai sidang, kelola revisi dosen, referensi | Academic |
| Mahasiswa dengan tugas besar atau kerja kelompok | V1 | Pembagian tugas adil, deadline bersama | Academic |
| Peneliti, mahasiswa S2, dosen | V1–V2 | Literatur, eksperimen, publikasi | Research |
| Developer (side project, lomba, freelance) | V2 | Sprint, issue, rilis | Developer |
| Pekerja dan tim kecil | V2+ | Project kerja, stakeholder, rapat | Work |
| Siswa SMA dan pengguna umum | V2+ | Tugas proyek, tujuan pribadi | Personal |

## Persona

| Persona | Konteks | Masalah | Tanda berhasil |
| --- | --- | --- | --- |
| **Raka**, semester 7 Informatika (MVP) | Skripsi decision-making berbasis AI untuk NPC game RTS; sidang 6 bulan lagi; 10 jam/minggu | Bingung urutan kerja, Bab 2 terus ditunda, revisi dosen tercecer di WhatsApp | Tahu apa yang dikerjakan hari ini; seminar proposal sesuai jadwal |
| **Nadia**, semester 5 Sistem Informasi (V1) | Ketua kelompok 4 orang, tugas besar 8 minggu | Pembagian kerja timpang, anggota pasif, begadang di malam terakhir | Kontribusi tiap anggota terlihat; selesai H-2 |
| **Dimas**, developer indie (V2) | Game side project sambil kerja penuh waktu | Project mangkrak berbulan-bulan | Rilis versi pertama |

> [!note] Raka dan riset penulis sendiri
> Topik skripsi Raka sama dengan riset pembuat plan ini, yaitu SLR decision-making NPC di game RTS militer (catatan `SLR NPC RTS Militer` di brain umum). Riset itu kandidat alami untuk dogfooding: [[Langkah Pertama 14 Hari]] meminta satu project nyata milik sendiri dikelola dengan alur concierge.

## Jobs-to-be-done

1. Saat mengerjakan project besar dengan deadline, saya ingin tahu langkah berikutnya dan apakah saya masih on track, supaya selesai tanpa panik di akhir.
2. Saat dosen memberi revisi, saya ingin revisi itu langsung masuk ke rencana, supaya tidak ada yang terlewat.
3. Saat membaca puluhan jurnal, saya ingin bertanya ke semua jurnal itu sekaligus dan mendapat jawaban bersumber, supaya Bab 2 cepat tersusun.

**Validasi:** ketiga persona diuji lewat wawancara 10–15 mahasiswa di Fase 0, sebelum kode fitur ditulis. Lihat [[Roadmap]].

> [!info] Untuk English
> Persona di atas semuanya mahasiswa Indonesia. Pengguna versi English adalah pengguna di luar Indonesia ([[K-006 Pengguna English di luar Indonesia]]); personanya belum dibuat.

Terkait: [[Visi dan Positioning]] · [[Mode sebagai Preset]] · [[Go-to-Market]]
