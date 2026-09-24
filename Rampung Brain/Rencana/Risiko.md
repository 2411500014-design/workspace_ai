---
type: note
area: Rencana
sumber: "§18"
tags:
  - rencana
  - risiko
updated: 2026-09-24
---

# Risiko

Dua risiko teratas adalah **scope yang melebar** dan **retensi rendah**. Skor = dampak × kemungkinan, masing-masing 1–3. Risiko berskor 6 ke atas dicek di setiap review mingguan, sisanya di akhir fase.

| Risiko | Skor | Mitigasi | Tanda awal |
| --- | --- | --- | --- |
| Scope melebar: lima mode, dua platform, dan kolaborasi dikerjakan sekaligus | 9 (3×3) | MVP hanya Academic Mode versi web; ide baru masuk backlog dan dibahas di akhir fase; ikuti urutan potong di [[Roadmap]] | Fase molor > 2 minggu |
| Retensi rendah: pengguna berhenti setelah minggu pertama | 9 (3×3) | Nilai datang tanpa input manual (digest pagi, Fokus Hari Ini); update progress 1 tap; re-plan tanpa nada menyalahkan | Retensi W1 < 40% |
| AI salah menghitung tanggal, salah membaca dokumen, atau mengarang referensi | 6 (3×2) | Tanggal dihitung scheduler di kode; klaim wajib bersitasi; AI menjawab "tidak ditemukan" saat sumber tidak ada; evals sebelum setiap rilis | Laporan jawaban salah atau rasio tidak suka naik |
| Produk dicap alat joki | 6 (3×2) | AI tidak menulis bab jadi; log kontribusi AI bisa diekspor; 2–3 dosen jadi penasihat sejak Fase 0 | Keluhan dosen atau larangan dari kampus |
| Developer solo kelelahan dan timeline molor | 6 (3×2) | Batas 15–20 jam/minggu; potong scope sebelum menambah jam; cari rekan desainer atau co-founder setelah beta | Dua minggu berturut-turut < 10 jam |
| Kompetitor besar merilis fitur serupa | 6 (2×3) | Bersaing di loop rencana–pantau–sesuaikan dan konteks lokal (alur bimbingan, template kampus Indonesia); rilis cepat dari masukan pengguna | Pengguna beta menyebut alat lain sebagai pengganti |
| Pengguna pergi setelah lulus | 6 (2×3) | Paket Skripsi sekali bayar; referral ke adik tingkat; Work dan Personal Mode di V2 | Churn melonjak setelah musim sidang |
| Biaya AI melebihi pendapatan | 4 (2×2) | Kuota per paket, model ringan untuk tugas sederhana, prompt caching, Batch untuk review mingguan | Biaya AI per pengguna aktif di atas target ([[Monetisasi]]) |
| Bergantung pada satu penyedia model | 4 (2×2) | Model Gateway, prompt berversi, evals untuk menguji model alternatif | Kenaikan harga atau model dihentikan |
| Prompt injection lewat dokumen | 4 (2×2) | Isi dokumen diperlakukan sebagai data; AI hanya mengusulkan dan setiap perubahan butuh persetujuan; kasus injeksi masuk dataset evals | Output yang menjalankan perintah dari isi dokumen |
| Kebocoran data atau pelanggaran UU PDP | 3 (3×1) | RLS, enkripsi, akses minimal, DPIA, respons insiden 3×24 jam ([[Keamanan dan Privasi]]) | Akses tidak wajar di log audit |

## Risiko nama (ditemukan 2026-09-24)

| Risiko | Skor usulan | Mitigasi | Tanda awal |
| --- | --- | --- | --- |
| Nama "Rampung" bentrok dengan merek terdaftar "Rampung Indonesia" (kelas 41, pendidikan, berlaku sampai 2029): permohonan merek ditolak, atau ada sengketa setelah launch | 6 (3×2) | Konsultasi konsultan KI sebelum ada biaya untuk merek, domain, atau logo; siapkan nama cadangan; pertimbangkan penghapusan karena tidak dipakai, pembelian, atau lisensi ([[Cek Nama]]) | Konsultan menilai ada persamaan pada pokoknya, atau pemilik merek mulai aktif |

## Risiko baru dari keputusan dua bahasa

Master plan belum memuat risiko ini. Skornya masih usulan.

| Risiko | Skor usulan | Mitigasi |
| --- | --- | --- |
| Beban terjemahan memperlambat Fase 1–3 (satu developer, setiap teks ditulis dua kali) | 4 (2×2) | Key ARB sejak awal; terjemahan English boleh menyusul per fitur selama key lengkap; tanyakan apakah English harus lengkap saat beta ([[Pertanyaan Terbuka]]) |
| Kualitas jawaban AI dalam English tidak teruji | 4 (2×2) | Kasus English di dataset evals ([[Testing dan Evals]]) |

Terkait: [[Roadmap]] · [[Metrik]] · [[Log Keputusan]]
