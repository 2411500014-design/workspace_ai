# Purnara: aplikasi Flutter

Satu codebase untuk web, Android, Windows, macOS, Linux, dan iOS. Butuh Flutter 3.47.4 (Dart 3.13). Cara menjalankan bersama backend ada di `README.md` di akar repo.

## Stack

- **Material:** package `material_ui` (Material dipisah dari framework sejak Flutter 3.47). Selalu impor `package:material_ui/material_ui.dart`.
- **State:** Riverpod 3 (`flutter_riverpod`). Retry otomatis dimatikan di `main.dart`, supaya error API langsung tampil.
- **Navigasi:** go_router 18. Lima tab di dalam `AppShell` (Hari Ini, Project, Rencana, Dokumen, Asisten); layar lain dibuka penuh.
- **HTTP:** Dio (`lib/data/api_client.dart`). Error API datang sebagai kode dan diterjemahkan di `lib/core/l10n.dart`.
- **Dua bahasa:** gen-l10n dengan `lib/l10n/app_id.arb` (template) dan `app_en.arb`. Setelah mengubah ARB, jalankan `flutter gen-l10n`.
- **Font:** Plus Jakarta Sans dibundel di `assets/fonts` (SIL OFL 1.1), jadi aplikasi tidak menghubungi CDN font.

## Struktur `lib/`

| Folder | Isi |
| --- | --- |
| `core/` | Konfigurasi alamat server, tema dan token desain, format tanggal/jam, teks error, widget bersama |
| `data/` | Client API, model data, repository, dan provider Riverpod |
| `features/` | Satu folder per layar: `today`, `project`, `plan`, `documents`, `assistant`, `onboarding`, `brief`, `suggestions`, `replan`, `supervision`, `review`, `settings`, `shell` |
| `l10n/` | File ARB dan kode hasil gen-l10n |

## Alamat server

Urutannya: alamat yang disimpan di **Pengaturan**, lalu `--dart-define=API_BASE_URL=...`, lalu bawaan per platform. Web yang dilayani backend di port 8000 memakai origin yang sama; emulator Android memakai `http://10.0.2.2:8000`; selain itu `http://localhost:8000`.

## Pemeriksaan

```bash
flutter analyze
```

```bash
flutter test
```

Test widget memakai repository palsu (`test/fakes.dart`), jadi tidak butuh server.
