# Purnara

**Purnara** berasal dari kata *purna*: lengkap, tuntas. Nama kerja sebelumnya adalah Rampung. Ini workspace project berbasis AI untuk mahasiswa tingkat akhir di Indonesia yang mengerjakan skripsi, TA, dan penelitian. AI memegang konteks utuh project, lalu membantu menyusun rencana, memantau progress, dan mengusulkan re-plan saat keadaan berubah. Setiap perubahan rencana tampil sebagai usulan yang disetujui pengguna. Aplikasi tersedia dalam Bahasa Indonesia dan English.

> **Status (2026-09-24):** tahap perencanaan, Fase 0 (validasi). Belum ada kode fitur. Folder `app/` masih berisi kerangka bawaan `flutter create`.

## Struktur repo

| Folder | Isi | Status |
| --- | --- | --- |
| `app/` | Aplikasi Flutter (web dulu, lalu Android, lalu iOS) | Kerangka bawaan |
| `backend/` | FastAPI modular monolith + worker background | Kosong |
| `modes/` | Preset mode (YAML berversi) dan template project | Kosong |
| `evals/` | Dataset dan skrip evals AI | Kosong |
| `docs/` | Master plan (PDF) dan catatan keputusan arsitektur (`docs/adr/`) | Ada |
| `graphify-out/` | Knowledge graph dari master plan (`graph.html`, `GRAPH_REPORT.md`) | Ada |
| `Purnara Brain/` | Vault Obsidian: otak kedua project ini | Ada |

## Dokumen

- **Mulai dari vault:** buka `Purnara Brain/` di Obsidian sebagai vault bernama *Purnara Brain*. Berandanya `Purnara.md`. Keputusan ada di `Keputusan/`, pertanyaan yang belum diputuskan di `Pertanyaan Terbuka.md`, dan riwayat di `Riwayat.md`.
- **Master plan:** `docs/Master Plan AI Academic Workspace.pdf`. Nama kerja di plan masih "AI Academic Workspace".
- **Keputusan arsitektur:** `docs/adr/`.

## Menjalankan kerangka Flutter

Butuh Flutter 3.47 (Dart 3.13).

```bash
cd app
```

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

Pemeriksaan yang sama dengan CI (`.github/workflows/ci.yml`):

```bash
flutter analyze
```

```bash
flutter test
```

## Aturan yang tidak ditawar

1. **Dua bahasa.** Setiap teks yang dilihat pengguna ada dalam `id` dan `en`. Tidak ada teks UI yang ditulis langsung di kode.
2. **AI mengusulkan, pengguna memutuskan.** AI tidak pernah mengubah rencana secara langsung.
3. **Kode yang menghitung.** Tanggal, kapasitas, jalur kritis, dan health score dihitung kode deterministik, bukan LLM.
4. **API key LLM hanya di server.**

Rinciannya ada di `CLAUDE.md` dan di vault.
