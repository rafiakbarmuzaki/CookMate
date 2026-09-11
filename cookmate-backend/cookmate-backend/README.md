# CookMate Backend — Express + MongoDB Atlas

Backend ini melengkapi bagian yang masih kosong di repo Flutter `CookMate`
(lihat README repo tersebut, bagian "Yang masih perlu kamu lengkapi"):
autentikasi sungguhan, penyimpanan resep favorit, dan riwayat chat.

## Struktur

```
cookmate-backend/
├── server.js              # entry point
├── config/db.js           # koneksi MongoDB Atlas
├── models/                # User, Recipe, Favorite, ChatMessage
├── controllers/           # logika bisnis tiap fitur
├── routes/                # daftar endpoint API
└── .env.example           # contoh variabel lingkungan
```

## 1. Setup MongoDB Atlas (gratis, 24 jam nonstop)

MongoDB Atlas menyediakan tier gratis **M0** — cluster cloud yang tetap
menyala 24/7 tanpa perlu kamu hosting sendiri, cocok untuk tugas akhir/skripsi.

1. Buat akun di https://www.mongodb.com/cloud/atlas/register
2. Buat **Project** baru, lalu klik **Create Cluster** → pilih tier **M0 Free**.
3. Pilih provider & region terdekat (mis. AWS - Singapore), beri nama cluster
   (mis. `cookmate-cluster`), lalu **Create**.
4. Di **Database Access** → **Add New Database User**: buat username &
   password (simpan baik-baik, dipakai di connection string).
5. Di **Network Access** → **Add IP Address** → pilih **Allow Access from
   Anywhere** (`0.0.0.0/0`). Ini penting supaya backend yang di-deploy ke
   layanan hosting mana pun bisa konek — tanpa ini koneksi akan ditolak.
6. Setelah cluster aktif (~1-3 menit), klik **Connect** → **Drivers** → copy
   **connection string**, contoh:
   ```
   mongodb+srv://<username>:<password>@cookmate-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
7. Tambahkan nama database setelah `.net/`, misal `.../cookmate?retryWrites=...`.

## 2. Jalankan backend secara lokal

```bash
cd cookmate-backend
npm install
cp .env.example .env
# edit .env: isi MONGODB_URI dari langkah di atas, dan JWT_SECRET bebas (string acak panjang)
npm run dev
```

Cek di browser: `http://localhost:5000` → harus muncul `{"status":"ok",...}`.

## 3. Endpoint yang tersedia

| Method | Endpoint                     | Keterangan                                |
|--------|-------------------------------|--------------------------------------------|
| POST   | `/api/auth/register`         | Daftar akun baru                            |
| POST   | `/api/auth/login`            | Login, dapat JWT token                      |
| GET    | `/api/auth/me`               | Profil + data kesehatan (perlu token)       |
| PUT    | `/api/auth/me`                | Update profil kesehatan (perlu token)       |
| POST   | `/api/recipes`               | Simpan resep hasil generate Gemini          |
| GET    | `/api/recipes`               | Riwayat resep milik user                    |
| GET    | `/api/recipes/:id`           | Detail satu resep                           |
| DELETE | `/api/recipes/:id`           | Hapus resep                                 |
| POST   | `/api/recipes/:id/favorite`  | Tandai resep sebagai favorit                |
| DELETE | `/api/recipes/:id/favorite`  | Batal favorit                               |
| GET    | `/api/recipes/favorites/list`| Daftar resep favorit                        |
| POST   | `/api/chat`                  | Simpan 1 pesan chat (role: user/bot)        |
| GET    | `/api/chat/history`          | Ambil riwayat chat                          |
| DELETE | `/api/chat/history`          | Hapus riwayat chat                          |

Semua endpoint kecuali `register`/`login` butuh header:
`Authorization: Bearer <token>` (token didapat dari hasil login/register).

## 4. Di mana host backend ini supaya bisa diakses 24 jam gratis?

Database (MongoDB Atlas M0) sudah otomatis 24/7 begitu dibuat. Yang masih
perlu dihosting adalah **server Express-nya** (kode di server.js). Beberapa
opsi gratis:

- **Render.com (Free Web Service)** — paling umum dipakai untuk skripsi.
  Deploy langsung dari GitHub repo, otomatis dapat URL publik HTTPS.
  Catatan: instance gratis akan "tidur" setelah ~15 menit tanpa request, dan
  bangun lagi (delay beberapa detik) saat ada request baru — bukan benar-benar
  nonstop tanpa jeda, tapi tetap bisa diakses 24 jam selama kamu sabar
  menunggu proses "wake up" di request pertama.
- **Railway.app** — free trial credit bulanan, mirip Render, mudah deploy dari GitHub.
- **Cyclic.sh / Fly.io** — alternatif lain dengan free tier, mekanisme sleep serupa Render.
- Jika perlu benar-benar tanpa sleep, opsi gratis terbatas — biasanya sudah
  masuk kategori berbayar (mis. VPS murah). Untuk kebutuhan skripsi/demo,
  Render/Railway biasanya cukup.

Langkah umum deploy ke Render:
1. Push folder `cookmate-backend/` ini ke repo GitHub kamu.
2. Di Render → **New** → **Web Service** → hubungkan repo tersebut.
3. Build command: `npm install` — Start command: `npm start`.
4. Di tab **Environment**, tambahkan `MONGODB_URI` dan `JWT_SECRET` (isi sama
   seperti di `.env` lokal kamu).
5. Deploy → Render akan kasih URL publik, misalnya
   `https://cookmate-backend.onrender.com`, itu yang dipanggil dari Flutter.

## 5. Menghubungkan ke Flutter

Di `GeminiService` atau service baru (mis. `ApiService`), arahkan base URL ke
alamat backend yang sudah di-deploy, contoh:

```dart
const baseUrl = 'https://cookmate-backend.onrender.com/api';
```

Lalu gunakan `http.post('$baseUrl/auth/login', ...)` dsb. untuk menggantikan
bagian "UI saja, belum terhubung backend auth" di `AuthPage`.
