## Ringkasan

<!-- Apa yang diubah dan kenapa, 1–3 kalimat. -->

**Terkait:** <!-- user story / FR / NFR / DECISIONS, mis. US-03, FR-08, NFR-01, D-042 -->

## Jenis perubahan

- [ ] Fitur baru
- [ ] Perbaikan bug
- [ ] Test
- [ ] Dokumentasi (README, docs/)
- [ ] Konfigurasi / DevOps (CI, Docker, env)

## Test yang dijalankan

- [ ] `npm test` (unit)
- [ ] `npm run test:integration`
- [ ] `npm run test:e2e`
- [ ] `npm run lint` dan `npm run typecheck`
- [ ] Dicoba manual di browser

<!-- Tempel ringkasan hasil, mis. "Tests 187 passed". -->

## Checklist reviewer

Diisi oleh reviewer (Sommerville, Tabel 9.13, disesuaikan untuk TypeScript/Next.js):

- [ ] Nama variabel dan fungsi bermakna dan konsisten dengan istilah dokumen (wilayah, ambang, langganan)
- [ ] Data salah sudah dipertimbangkan dan diuji: kosong, `null`, nilai batas, kode wilayah salah
- [ ] Semua galat ditangani (Open-Meteo, push service, database)
- [ ] Masukan API divalidasi dengan skema Zod
- [ ] Tidak memakai `any` tanpa alasan
- [ ] Tidak ada rahasia di kode; `NEXT_PUBLIC_*` tidak berisi kunci privat; `.env` tidak ikut
- [ ] Perubahan logika risiko atau notifikasi disertai unit test baru
- [ ] README / docs ikut diperbarui bila perilaku atau konfigurasi berubah
