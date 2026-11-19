// Uji beban NFR-01: 95% request halaman level risiko selesai ≤ 2 detik untuk 100 pengguna bersamaan.
//
// Prasyarat:
//   1. Pasang k6 (sekali saja):  winget install k6 --source winget
//   2. Jalankan build produksi (bukan `npm run dev`):  npm run build  lalu  npm run start
//      (atau `docker compose up -d` lalu tembak http://localhost:3000, BUKAN https://localhost:8443)
//
// Jalankan dari folder repo:
//   k6 run scripts/k6/nfr-01-beban.js
//   k6 run -e BASE_URL=http://localhost:3000 -e DURASI=5m -e VUS=100 scripts/k6/nfr-01-beban.js
//   k6 run --summary-export docs/hasil-k6-nfr-01.json scripts/k6/nfr-01-beban.js
//
// Catatan rate limit: /api/risiko dibatasi 60 request/menit per IP. Agar 100 pengguna virtual
// tidak dianggap satu IP, setiap pengguna memakai alamat X-Forwarded-For sendiri (10.88.x.y).
// Header ini hanya dipercaya bila aplikasi diakses langsung di port 3000; Caddy (port 8443) dan
// Vercel menimpanya dengan IP asli, jadi di sana semua request dari satu laptop terhitung satu IP.

import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";
const VUS = Number(__ENV.VUS || 100);
const DURASI = __ENV.DURASI || "5m";

// Desa/kelurahan yang juga dipakai test (lihat tests/): beberapa sel grid berbeda, tiga zona waktu.
const WILAYAH = [
  "33.74.02.1002", // Kelurahan Bulu Lor, Kota Semarang (WIB)
  "36.71.01.1001", // Kelurahan Sukarasa, Kota Tangerang (WIB)
  "33.75.03.1009", // Kelurahan Bandengan, Kota Pekalongan (WIB)
  "51.71.01.1001", // Kelurahan Serangan, Kota Denpasar (WITA)
  "82.71.01.1001", // Kelurahan Jambula, Kota Ternate (WIT)
];

export const options = {
  scenarios: {
    nfr01: {
      executor: "constant-vus",
      vus: VUS,
      duration: DURASI,
      gracefulStop: "30s",
    },
  },
  thresholds: {
    // Kriteria NFR-01: persentil ke-95 halaman Risiko ≤ 2 detik.
    "http_req_duration{jenis:halaman-risiko}": ["p(95)<2000"],
    // Pendukung: API yang dipanggil halaman untuk pembaruan berkala.
    "http_req_duration{jenis:api-risiko}": ["p(95)<2000"],
    // Hampir tidak boleh ada request gagal (termasuk 429 dan 5xx).
    "http_req_failed{scenario:nfr01}": ["rate<0.01"],
    "checks{scenario:nfr01}": ["rate>0.99"],
  },
  summaryTrendStats: ["avg", "min", "med", "p(90)", "p(95)", "max"],
};

// Pemanasan: isi cache cuaca setiap sel grid sekali, agar uji mengukur kondisi normal
// (data cuaca di-cache 30 menit), bukan waktu tunggu Open-Meteo pada request pertama.
export function setup() {
  for (const kode of WILAYAH) {
    const res = http.get(`${BASE_URL}/api/risiko?wilayah=${kode}`, { tags: { jenis: "pemanasan" } });
    if (res.status !== 200) {
      console.warn(`Pemanasan ${kode}: status ${res.status}. Periksa server, seed database, dan internet.`);
    }
  }
}

export default function ujiBeban() {
  const kode = WILAYAH[(__VU + __ITER) % WILAYAH.length];
  const headers = { "X-Forwarded-For": `10.88.${Math.floor(__VU / 250)}.${__VU % 250}` };

  const halaman = http.get(`${BASE_URL}/risiko?wilayah=${kode}`, {
    headers,
    tags: { jenis: "halaman-risiko", name: "/risiko?wilayah=…" },
  });
  check(halaman, {
    "halaman Risiko 200": (r) => r.status === 200,
    "halaman memuat judul Risiko Banjir": (r) => typeof r.body === "string" && r.body.includes("Risiko Banjir"),
  });

  const api = http.get(`${BASE_URL}/api/risiko?wilayah=${kode}`, {
    headers,
    tags: { jenis: "api-risiko", name: "/api/risiko?wilayah=…" },
  });
  check(api, {
    "API risiko 200": (r) => r.status === 200,
    "API mengembalikan level": (r) => {
      try {
        return ["RENDAH", "SEDANG", "TINGGI"].includes(r.json("data.level"));
      } catch {
        return false;
      }
    },
  });

  // Jeda baca 1–3 detik, seperti pengguna sungguhan.
  sleep(1 + Math.random() * 2);
}
