# Catatan keputusan arsitektur (ADR)

Satu file per keputusan arsitektur yang penting: `NNNN-judul-singkat.md`, nomornya berurutan dan tidak pernah dipakai ulang. ADR yang digantikan tidak dihapus. Statusnya diubah menjadi *Digantikan oleh ADR-NNNN*.

**Pembagian dengan vault:** keputusan **arsitektur** dicatat di sini, di samping kodenya. Keputusan **produk dan proses**, misalnya nama produk atau dukungan dua bahasa, dicatat di vault (`Purnara Brain/Keputusan/`). Keduanya saling merujuk.

| ADR | Judul | Status |
| --- | --- | --- |
| [0001](0001-pilihan-stack.md) | Pilihan stack teknis | Diterima (2026-09-24) |
| [0002](0002-pengembangan-lokal-tanpa-biaya.md) | Pengembangan lokal tanpa biaya | Diterima (2026-09-24) |

## Format

```markdown
# ADR-NNNN: Judul

- Status: Diusulkan | Diterima | Digantikan oleh ADR-NNNN
- Tanggal: YYYY-MM-DD

## Konteks
## Keputusan
## Konsekuensi
## Alternatif yang ditolak
```
