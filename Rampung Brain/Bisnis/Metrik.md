---
type: note
area: Bisnis
sumber: "§17"
tags:
  - bisnis
  - metrik
updated: 2026-09-24
---

# Metrik

**North Star Metric: project yang bergerak setiap minggu**, yaitu project aktif dengan minimal satu task selesai dalam 7 hari terakhir. Angka ini hanya naik jika pengguna benar-benar maju, jadi lebih jujur daripada jumlah pendaftar atau pesan chat.

Semua target di bawah adalah target awal. Tinjau ulang setelah dua minggu data beta.

## Metrik produk

| Metrik | Definisi | Target awal | Diukur |
| --- | --- | --- | --- |
| Project bergerak per minggu | Project aktif dengan ≥1 task selesai dalam 7 hari | Naik setiap minggu selama beta | Mingguan |
| Aktivasi | Pendaftar yang membuat project dan menerima rencana di sesi pertama | ≥ 60% | Harian |
| Waktu sampai rencana | Median waktu dari daftar sampai rencana diterima | ≤ 10 menit | Mingguan |
| Retensi W1 dan W4 | Pengguna yang memperbarui task di minggu ke-1 dan ke-4 | W1 ≥ 60%, W4 ≥ 40% | Per kohort mingguan |
| Milestone tepat waktu | Milestone yang selesai paling lambat di tanggal rencananya | ≥ 70% | Mingguan |
| Opt-out pengingat | Pengguna yang mematikan semua pengingat | ≤ 20% | Mingguan |
| Tes Sean Ellis | Pengguna aktif ≥2 minggu yang menjawab "sangat kecewa" jika produk hilang | ≥ 40% | Akhir beta |

Setelah V1, ukur juga persentase project yang selesai sebelum deadline, lalu bandingkan dengan pengalaman responden di Fase 0.

## Kualitas AI

| Metrik | Definisi | Target awal |
| --- | --- | --- |
| Penerimaan usulan | Kartu usulan AI yang diterima penuh atau sebagian | ≥ 50% |
| Rencana diedit | Task buatan AI yang dihapus atau diubah besar dalam 7 hari pertama | ≤ 30% |
| Klaim bersitasi | Klaim tentang dokumen yang punya sitasi valid (dataset evals) | ≥ 90% |
| Sitasi palsu | Sitasi ke dokumen atau halaman yang tidak ada | 0 di dataset evals |
| Jawaban disukai | Jawaban chat bernilai suka dari semua yang dinilai | ≥ 80% |

## Bisnis dan biaya (mulai V1)

| Metrik | Target awal |
| --- | --- |
| Konversi gratis ke berbayar | 3–5% dari pengguna aktif bulanan |
| Biaya AI per pengguna aktif bulanan | ≤ 25% harga Pro ([[Monetisasi]]) |
| Margin kotor | ≥ 60% |
| Churn Pro karena kecewa | ≤ 8% per bulan |

Pisahkan churn karena project selesai (pengguna lulus) dari churn karena kecewa. Churn jenis pertama justru tanda produk bekerja.

## Instrumentasi

Event PostHog dicatat sejak Fase 1:

`project_created` · `brief_confirmed` · `plan_generated` · `plan_accepted` · `task_updated` · `task_completed` · `suggestion_shown` · `suggestion_applied` · `suggestion_rejected` · `chat_asked` · `citation_opened` · `replan_started` · `reminder_opened` · `weekly_review_opened`

Setiap event membawa `project_id` dan `mode`. Event yang melibatkan AI juga membawa versi prompt. Karena Rampung dua bahasa, tambahkan juga properti `locale`, supaya metrik bisa dibandingkan antara pengguna ID dan EN.

Terkait: [[Testing dan Evals]] · [[Operasional]] · [[Roadmap]]
