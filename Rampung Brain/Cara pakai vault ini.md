---
type: guide
tags:
  - rampung
  - vault
updated: 2026-09-24
---

# Cara pakai vault ini

Vault ini adalah otak kedua khusus project [[Rampung]]. Isinya Markdown biasa di `D:\Workspace AI\workspace_ai\Rampung Brain`, satu folder dengan kodenya. Project ini besar, jadi keputusan, rencana, dan riwayatnya disimpan bersama kodenya, bukan di vault umum.

## Membuka di Obsidian

Vault sudah terdaftar di Obsidian dengan nama **Rampung Brain** (2026-09-24), jadi cukup pilih dari daftar vault. Di komputer lain: Open folder as vault → `D:\Workspace AI\workspace_ai\Rampung Brain`. Nama ini sengaja dibedakan dari vault umum `Obsidian` di `D:\GuardID\Obsidian`, supaya perintah CLI tidak tertukar.

- [[Rampung]] adalah beranda.
- `Rampung.base` berisi tabel semua catatan per area, daftar keputusan, dan catatan yang lama tidak disentuh.
- Graph view sudah diwarnai per folder: Produk, Arsitektur, UX, Kualitas, Bisnis, Legal, Rencana, Keputusan.

## Obsidian CLI

Syaratnya: aplikasi Obsidian **sedang berjalan** dan Settings → General → *Command line interface* aktif. Di Windows, panggil `D:\Obsidian\Obsidian.com`. Perintah `obsidian` biasa bisa membuka GUI dan menggantung.

> [!warning] `vault=` harus di depan
> Tulis `vault="Rampung Brain"` **sebelum** nama perintah. Jika ditaruh di belakang, argumen itu diabaikan tanpa pesan error, dan perintah jalan di vault yang sedang aktif (bisa jadi vault `Obsidian`). Dicek 2026-09-24.

```bash
"D:\Obsidian\Obsidian.com" vault="Rampung Brain" search query="scheduler"
```

```bash
"D:\Obsidian\Obsidian.com" vault="Rampung Brain" read file="Planning Engine"
```

```bash
"D:\Obsidian\Obsidian.com" vault="Rampung Brain" append file="Riwayat" content="- 2026-10-01 wawancara pertama selesai"
```

```bash
"D:\Obsidian\Obsidian.com" vault="Rampung Brain" tasks
```

`append` menulis di **paling akhir** catatan. Untuk menyisipkan di tengah, edit filenya langsung. `tasks` menampilkan semua checkbox, termasuk [[Langkah Pertama 14 Hari]] dan [[Pertanyaan Terbuka]].

## Aturan menulis

1. **Setelah kerja yang berarti** (fitur jadi, keputusan diambil, fase berganti): tambahkan satu baris bertanggal di [[Riwayat]] dan perbarui catatan yang faktanya berubah. Ubah juga `updated:` di frontmatter.
2. **Keputusan baru** dibuat dari template `Templates/Keputusan` dengan nama `K-00N Judul singkat`, lalu dicatat di [[Log Keputusan]].
3. **Hal yang belum diputuskan** masuk [[Pertanyaan Terbuka]]. Setelah diputuskan, pindahkan ke catatan keputusan.
4. Jika catatan dan kode berbeda, **kode yang benar**. Perbaiki catatannya.
5. Tulis singkat dan faktual. Catatan adalah ringkasan yang ditautkan, bukan salinan [[Master Plan]].

**Yang tidak masuk vault:** API key, password, isi `.env`, data pribadi peserta wawancara (anonimkan), hasil build, dan hal yang sudah tercatat lebih baik di kode atau git.

## Hubungan dengan brain umum

Vault umum di `D:\GuardID\Obsidian` punya satu catatan ringkas `Projects/Rampung.md` yang menunjuk ke sini. Detail tetap di vault ini. Setelah milestone besar, perbarui juga ringkasan di sana.

## Knowledge graph

`graphify-out/` di folder project berisi graph pengetahuan dari master plan. Buka `graph.html` di browser. Dari folder project, jalankan `graphify query "pertanyaan"` untuk menelusuri graph. Lihat [[Knowledge Graph]].

## Git

Vault ini bagian dari repository project (`D:\Workspace AI\workspace_ai`, branch `main`, belum ada remote). Catatan ikut di-commit bersama kodenya. `.gitignore` di vault mengecualikan `workspace.json`, yaitu status jendela Obsidian per komputer.

```bash
git -C "D:\Workspace AI\workspace_ai" add "Rampung Brain"
```

```bash
git -C "D:\Workspace AI\workspace_ai" commit -m "Catatan: <ringkas>"
```

Terkait: [[Rampung]] · [[Riwayat]]
