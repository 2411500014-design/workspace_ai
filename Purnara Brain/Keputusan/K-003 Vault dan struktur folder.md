---
type: decision
area: Keputusan
status: diterima
tanggal: 2026-09-24
tags:
  - keputusan
  - repo
  - vault
updated: 2026-09-25
---

# K-003 Vault dan struktur folder

## Konteks
Project ini besar. Keputusan, rencana, dan riwayatnya perlu tempat yang bertahan lintas sesi dan tetap dekat dengan kodenya. Folder project `D:\Workspace AI\workspace_ai` sudah ada dan berisi kerangka Flutter bawaan (package `workspace_ai`) di root.

## Keputusan
1. **Otak kedua (vault Obsidian) disimpan di dalam folder project**, di `Purnara Brain\`. Vault ikut masuk repository saat git diinisialisasi.
2. Nama vault **Purnara Brain** (semula *Rampung Brain*, diganti 2026-09-24 mengikuti [[K-004 Nama produk Purnara]]), bukan "Obsidian". Brain umum di `D:\GuardID\Obsidian` sudah bernama "Obsidian", dan Obsidian CLI memilih vault berdasarkan nama.
3. Brain umum cukup menyimpan satu ringkasan (`Projects/Purnara.md`) yang menunjuk ke vault ini.
4. Master plan (PDF) disimpan di `docs/`. Knowledge graph dari plan ada di `graphify-out/` ([[Knowledge Graph]]).

5. **Monorepo sesuai master plan** (dikerjakan 2026-09-24): kerangka Flutter dipindah ke `app/`, lalu dibuat `backend/`, `modes/`, `evals/`, `docs/adr/`, README, ADR-0001 (pilihan stack), dan CI GitHub Actions (`flutter analyze` + `flutter test`, Flutter 3.47.4). `flutter analyze` dan `flutter test` tetap lolos setelah dipindah.
6. **Git lokal** sudah diinisialisasi dengan commit pertama di `main`.
7. ~~**Selama Fase 0, aplikasi belum dibangun** (permintaan 2026-09-24). Boleh: struktur repo, dokumen, perencanaan. Belum boleh: layar baru, pemasangan l10n, dan kode backend.~~ **Digantikan** oleh [[K-005 Mulai membangun aplikasi]] di hari yang sama.

## Belum diputuskan
- **Mengganti nama package** `workspace_ai` menjadi `purnara`, termasuk application ID Android (`com.example.workspace_ai`) dan bundle ID iOS. Nama Purnara sudah dipilih ([[K-004 Nama produk Purnara]]). Penggantian dilakukan saat Fase 1 dimulai, karena aplikasi belum dibangun selama Fase 0. **Selesai 2026-09-24:** package `purnara`, application ID dan bundle ID `id.purnara.app` ([[K-005 Mulai membangun aplikasi]]).
- **Remote GitHub.** CI baru berjalan setelah repo di-push. Membuat repo di GitHub adalah langkah publik, jadi menunggu keputusan pemilik project.

Terkait: [[Cara pakai vault ini]] · [[Log Keputusan]] · [[Pertanyaan Terbuka]]
