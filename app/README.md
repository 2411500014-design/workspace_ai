# Rampung: aplikasi Flutter

Satu codebase untuk web, Android, dan iOS. Urutannya web dulu (MVP), lalu Android (V1), lalu iOS.

**Status:** masih kerangka bawaan `flutter create`. Belum ada fitur. Nama package masih `workspace_ai`, dan akan diganti setelah nama *Rampung* lolos cek merek (lihat `Rampung Brain/Keputusan/K-003 Vault dan struktur folder.md`).

**Rencana stack:** Riverpod, go_router, Dio, freezed, dan gen-l10n dengan ARB `id` + `en`. Struktur `lib/` direncanakan menjadi `core/`, `features/`, dan `shared/`. Detailnya ada di catatan vault `Arsitektur/Tech Stack.md`.

```bash
flutter pub get
```

```bash
flutter run -d chrome
```
