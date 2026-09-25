---
type: decision
area: Keputusan
status: diterima
tanggal: 2026-09-25
tags:
  - keputusan
  - ux
updated: 2026-09-25
---

# K-007 Platform adaptive

## Konteks
Aplikasi Flutter memakai satu desain Material 3 yang sama di web, Android, dan desktop. `PRODUCT.md` perlu mencatat platform desainnya: `web`, `android`, `ios`, atau `adaptive`.

## Keputusan
Platform desainnya **adaptive**. Purnara adalah satu produk yang menyesuaikan bahasa desainnya per sistem operasi: Material 3 di Android, dan Human Interface Guidelines Apple di iPhone dan iPad.

## Akibat
- **Belum dibangun:** penyesuaian ini baru arah. Saat ini semua platform masih memakai desain Material yang sama.
- **iOS:** saat iOS dikerjakan, perlu memakai safe area, gestur back dari tepi layar, kontrol dan transisi bawaan iOS, serta Dynamic Type.
- **Android:** perlu tombol Back sistem (termasuk *predictive back*), tampilan edge-to-edge, dan boleh memakai Dynamic Color.
- **Verifikasi:** screenshot untuk platform native diambil dari emulator, simulator, atau perangkat asli, bukan dari browser.

## Alternatif yang ditolak
- `web`: satu desain untuk semua platform, tanpa aturan khusus per OS.
- `android`: Android sebagai platform utama.

Terkait: [[Log Keputusan]] · [[Tech Stack]] · [[Alur dan Layar]]
