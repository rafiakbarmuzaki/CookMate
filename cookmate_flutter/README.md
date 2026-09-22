# CookMate AI — Flutter Frontend

Konversi frontend dari prototype React/TSX (`prototype_cookmate`) ke Flutter,
dengan AI rekomendasi resep & chatbot yang terhubung ke **Google Gemini API**.

## Struktur folder

```
lib/
│
├── models/
│   ├── user_profile.dart     # Menggantikan HealthProfile.tsx & ProfilePage.tsx
│   └── recipe.dart           # Menggantikan RecipeDetail.tsx & RecipeResults.tsx
│
├── services/
│   ├── gemini_service.dart   # Logika integrasi Google Gemini API
│   └── api_key_store.dart    # Penyimpanan API key lokal (SharedPreferences)
│
├── views/
│   ├── auth_page.dart        # Menggantikan AuthPage.tsx
│   ├── profile_page.dart     # Menggantikan ProfilePage.tsx
│   ├── health_profile.dart   # Menggantikan HealthProfile.tsx
│   ├── recipe_results.dart   # Menggantikan RecipeResults.tsx
│   ├── recipe_detail.dart    # Menggantikan RecipeDetail.tsx
│   └── home_page.dart        # Beranda: pilih bahan, preferensi, FAB chatbot
│                                (bagian utama App.tsx yang bukan halaman lain)
│
├── theme/app_theme.dart      # Warna & tipografi terpusat (Poppins + Nunito)
├── widgets/common_widgets.dart  # Chip, tombol gradasi, loading/error box
└── main.dart                 # Titik masuk aplikasi (menggantikan App.tsx & main.tsx)
```

## 1. Cara pasang project ini

Karena project dibuat tanpa Flutter SDK di lingkungan pembuatannya, folder
`android/`, `ios/`, dll. **belum ada**. Cara termudah:

```bash
# 1. Buat project Flutter kosong
flutter create --org com.cookmate cookmate_ai
cd cookmate_ai

# 2. Timpa pubspec.yaml dan folder lib/ dengan isi dari paket ini
#    (copy pubspec.yaml, lib/, analysis_options.yaml ke folder cookmate_ai)

# 3. Ambil dependency
flutter pub get

# 4. Jalankan
flutter run
```

Pastikan platform target (Android/iOS) sudah punya izin **Internet**
(Android biasanya sudah default true; jika tidak, tambahkan di
`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 2. Menyiapkan Gemini API Key

1. Ambil API key gratis di [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Jalankan aplikasi, lalu buka **Profil → Pengaturan → API Key Gemini**,
   tempel key kamu di sana. Key disimpan lokal via `shared_preferences`.
3. Alternatif tanpa UI: jalankan dengan
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=isi_key_kamu
   ```
   (nilai ini dipakai sebagai default jika belum ada key tersimpan di perangkat).

⚠️ **Catatan keamanan**: menyimpan API key langsung di aplikasi mobile
(client-side) berisiko jika di-reverse-engineer. Untuk produksi, sebaiknya
buat backend proxy kecil yang menyimpan key secara aman dan diakses via
endpoint milikmu sendiri, lalu arahkan `GeminiService` untuk memanggil
backend tersebut, bukan Gemini API langsung.

## 3. Model Gemini yang dipakai

Default: `gemini-2.5-flash` (lihat `lib/services/gemini_service.dart`,
parameter `model` di constructor `GeminiService()`). Ganti sesuai kebutuhan
(misal `gemini-2.5-pro` untuk kualitas lebih tinggi tapi lebih lambat/mahal).

## 4. Alur aplikasi

1. **AuthPage** — login/daftar (UI saja, belum terhubung backend auth).
2. **HealthProfile** — onboarding kondisi medis, alergi, tujuan diet.
3. **HomePage** — pilih bahan + preferensi (porsi, waktu, gender, dst),
   tombol **Cari Resep** memanggil `GeminiService.generateRecipes()`.
4. **RecipeResults** — daftar resep hasil generate Gemini, bisa diurutkan.
5. **RecipeDetail** — detail bahan/langkah/nutrisi/tips AI, plus peringatan
   kesehatan otomatis jika `followHealthProfile` diaktifkan.
6. **FAB Chat** (di HomePage) — chatbot "CookMate Bot" yang membalas via
   `GeminiService.sendChatMessage()`, dengan konteks bahan yang dipilih.
7. **ProfilePage** — ringkasan profil kesehatan + menu "API Key Gemini" +
   logout.

## 5. Yang masih perlu kamu lengkapi

- Autentikasi sungguhan (Firebase Auth / backend sendiri) di `AuthPage`.
- Penyimpanan resep favorit / riwayat pencarian (saat ini hanya di memori).
- Gambar resep: saat ini pakai `picsum.photos` (placeholder acak berbasis
  seed judul resep, BUKAN gambar makanan sungguhan) — ganti dengan sumber
  gambar asli jika diperlukan (mis. Gemini image generation, Unsplash API
  resmi dengan API key, dsb).
- Validasi form di `AuthPage` (saat ini hanya UI, belum ada validasi email/password).
