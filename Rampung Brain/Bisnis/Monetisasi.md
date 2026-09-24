---
type: note
area: Bisnis
sumber: "§15"
tags:
  - bisnis
  - harga
updated: 2026-09-24
---

# Monetisasi

Model bisnis: **freemium** untuk individu, paket **tim** untuk kerja kelompok, lalu **lisensi kampus**. Beta berjalan gratis. Semua harga di bawah masih hipotesis yang divalidasi selama beta.

## Paket (hipotesis)

| Paket | Isi | Harga hipotesis |
| --- | --- | --- |
| Gratis | 1 project aktif, 30 dokumen, kredit AI bulanan terbatas, pengingat email | Rp0 |
| Pro | Project tanpa batas, kredit AI lebih besar, matriks literatur, ekspor, log kontribusi AI | Rp29.000–Rp49.000 per bulan |
| Paket Skripsi | Semua fitur Pro selama 6 bulan, sesuai durasi skripsi | Rp149.000–Rp199.000 sekali bayar |
| Tim (V1) | Project kelompok, assign task, jejak kontribusi | Per anggota per bulan, diskon kelompok |
| Kampus (V2) | Dashboard dosen, login kampus, laporan progres prodi | Lisensi tahunan per mahasiswa aktif |

Harga diuji di beta dengan survei **Van Westendorp**, yaitu empat pertanyaan: terlalu murah, murah, mahal, dan terlalu mahal.

## Unit economics

Biaya AI per pengguna aktif per bulan:

$$C_{AI} = \sum_{w} n_w \times \left(T^{in}_w \times p^{in} + T^{out}_w \times p^{out}\right)$$

$n_w$ = jumlah panggilan workflow $w$ per bulan, $T$ = jumlah token, $p$ = harga per token model. Token yang kena cache dihitung dengan harga cache yang lebih murah.

| Workflow (asumsi pengguna Pro aktif) | Panggilan/bulan | Token masuk/panggilan | Token keluar/panggilan | Kelas model |
| --- | --- | --- | --- | --- |
| Project Chat | 60 | 11.000 | 600 | Kuat |
| Task Helper | 30 | 3.000 | 400 | Ringan |
| Intake, brief, rencana, re-plan | 3 | 20.000 | 3.000 | Kuat |
| Ringkasan dokumen | 20 | 15.000 | 500 | Ringan |
| Review mingguan (Batch) | 4 | 6.000 | 800 | Ringan |

Kalikan dengan harga per juta token terbaru dari halaman pricing provider, lalu bandingkan dengan data nyata dari `usage_ledger` selama beta.

**Target awal:** biaya AI maksimal **25% dari harga Pro**, margin kotor minimal **60%**.

## Kanal pembayaran

Paket berbayar dijual lewat web dengan **Midtrans atau Xendit** (QRIS, e-wallet, virtual account). Pembelian langganan di dalam aplikasi Android dan iOS tunduk pada aturan billing Google Play dan App Store. Cek kebijakan terbaru sebelum menampilkan tombol beli di aplikasi mobile.

Harga ditampilkan dalam rupiah di kedua bahasa. Lihat [[Bilingual ID-EN]].

Terkait: [[Go-to-Market]] · [[Metrik]] · [[AI Engine]]
