# Purnara

**Purnara** berasal dari kata *purna*: lengkap, tuntas. Nama kerja sebelumnya adalah Rampung. Ini workspace project berbasis AI untuk mahasiswa tingkat akhir di Indonesia yang mengerjakan skripsi, TA, dan penelitian. Purnara menyusun rencana dari dokumen project, memberi tahu apa yang dikerjakan hari ini, memantau progress, dan mengusulkan penyesuaian saat keadaan berubah. Setiap perubahan rencana tampil sebagai usulan yang disetujui pengguna. Aplikasi tersedia dalam Bahasa Indonesia dan English.

> **Status (2026-09-24):** versi pertama aplikasi sudah jalan: web, Android, dan desktop dari satu codebase Flutter, dengan backend FastAPI. Semuanya berjalan di laptop tanpa layanan berbayar (ADR-0002). AI bersifat opsional; tanpa API key, setiap fitur memakai versi dasar yang diberi label jelas.

## Isi aplikasi

- **Setup project dalam 6 langkah:** jenis project, judul dan deadline, unggah dokumen, periksa brief, waktu yang tersedia, lalu pratinjau rencana.
- **Hari Ini:** maksimal tiga task fokus, tandai selesai dengan satu ketukan (bisa dibatalkan), dan "Bantu saya mulai" untuk langkah pertama 25 menit.
- **Rencana:** tampilan Daftar per milestone, Papan per status (bisa diseret), dan Linimasa. Detail task berisi estimasi, dependensi, dan syarat dosen yang dipenuhi.
- **Project:** status kesehatan beserta alasannya, progress rencana dibanding yang tercapai, milestone, checklist syarat dosen, dan usulan yang menunggu keputusan.
- **Sesuaikan rencana:** penjadwal menghitung beberapa opsi (susun ulang, tambah jam, kurangi scope, mundurkan target). Pengguna memilih satu.
- **Dokumen dan Asisten:** unggah PDF/DOCX/TXT/MD, lalu tanya jawab dengan kutipan halaman. Tanpa AI, asisten menampilkan bagian dokumen yang paling relevan.
- **Log bimbingan, Review mingguan, Brief project, dan Pengaturan:** bahasa, tema terang/gelap, alamat server, ekspor data, dan hapus akun.

## Struktur repo

| Folder | Isi |
| --- | --- |
| `app/` | Aplikasi Flutter (web, Android, Windows, macOS, Linux, iOS) |
| `backend/` | API FastAPI (modular monolith): planning engine, dokumen, AI gateway |
| `modes/` | Preset mode dan template project (`academic.yaml`, dua bahasa) |
| `evals/` | Dataset dan skrip evals AI (belum diisi) |
| `docs/` | Master plan (PDF) dan catatan keputusan arsitektur (`docs/adr/`) |
| `design-system/` | Sistem desain Purnara (`purnara/MASTER.md`) |
| `graphify-out/` | Knowledge graph dari master plan |
| `Purnara Brain/` | Vault Obsidian: otak kedua project ini |

## Yang perlu dipasang

- **Flutter 3.47.4** (Dart 3.13) dan **VS Code** dengan ekstensi yang direkomendasikan (VS Code menawarkannya saat folder dibuka).
- **Python 3.12+** dan **uv** untuk backend.
- Untuk **Android**: Android Studio (Android SDK dan emulator).
- Untuk **Windows desktop**: Visual Studio 2022 dengan workload *Desktop development with C++*, dan *Developer Mode* Windows aktif.

Pertama kali, pasang dependensi backend:

```bash
cd backend && uv sync
```

## Menjalankan dari VS Code

1. Buka folder `D:\Workspace AI\workspace_ai` di VS Code.
2. Buka panel **Run and Debug**, pilih **Purnara: backend + app (Chrome)**, lalu tekan F5.
3. Backend jalan di port 8000 dan aplikasi terbuka di Chrome (port 5000). Hot reload aktif saat file Dart disimpan.

Pilihan lain di panel yang sama: **backend + app (Windows)**, **backend + app (Android)**, dan **Backend: tests**. Perintah build dan pemeriksaan ada di **Terminal → Run Task**.

## Menjalankan dari terminal

Backend:

```bash
cd backend && uv run uvicorn app.main:app --reload --port 8000
```

Aplikasi di Chrome (terminal kedua):

```bash
cd app && flutter run -d chrome --web-port 5000
```

**Satu port saja:** setelah `flutter build web` di `app/`, backend ikut melayani aplikasinya. Buka `http://localhost:8000`.

```bash
cd app && flutter build web --release
```

**Ponsel di Wi-Fi yang sama:** jalankan backend dengan `--host 0.0.0.0` (di VS Code: *Backend: API for phones on the same Wi-Fi*). Lalu di aplikasi, buka **Pengaturan → Alamat server** dan isi `http://<IP laptop>:8000`. Emulator Android otomatis memakai `http://10.0.2.2:8000`.

**AI (opsional):** buat file `backend/.env` berisi `ANTHROPIC_API_KEY=...`. File ini tidak pernah masuk git. Tanpa kunci, semua fitur tetap jalan dengan versi dasar.

## Pemeriksaan

Sama dengan CI (`.github/workflows/ci.yml`):

```bash
cd backend && uv run ruff check . && uv run pytest
```

```bash
cd app && flutter analyze && flutter test
```

## Dokumen

- **Mulai dari vault:** buka `Purnara Brain/` di Obsidian sebagai vault bernama *Purnara Brain*. Berandanya `Purnara.md`.
- **Master plan:** `docs/Master Plan AI Academic Workspace.pdf`.
- **Keputusan arsitektur:** `docs/adr/`. Stack target ada di ADR-0001; versi lokal tanpa biaya di ADR-0002.

## Aturan yang tidak ditawar

1. **Dua bahasa.** Setiap teks yang dilihat pengguna ada dalam `id` dan `en`. Tidak ada teks UI yang ditulis langsung di kode.
2. **AI mengusulkan, pengguna memutuskan.** AI tidak pernah mengubah rencana secara langsung.
3. **Kode yang menghitung.** Tanggal, kapasitas, jalur kritis, dan health score dihitung kode deterministik, bukan LLM.
4. **API key LLM hanya di server.**

Rinciannya ada di `CLAUDE.md` dan di vault.
