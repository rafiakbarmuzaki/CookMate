import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import '../models/user_profile.dart';
import 'api_key_store.dart';

/// Exception khusus untuk error yang berasal dari Gemini API / Backend.
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);

  @override
  String toString() => message;
}

/// Service yang membungkus semua komunikasi ke Google Gemini API 
/// dan integrasi ke CookMate Backend (Express + MongoDB Atlas).
class GeminiService {
  /// Gunakan model resmi yang stabil dari Google AI Studio.
  final String model;

  /// URL Backend Express kamu (Sesuaikan jika sudah di-deploy ke Render)
  final String backendUrl;

  GeminiService({
    this.model = 'gemini-1.5-flash',
    this.backendUrl = 'http://localhost:5000/api', // Ubah ke URL Render jika sudah deploy
  });

  Uri _endpoint(String apiKey) => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

  Future<String> _generateRaw(
    String prompt, {
    bool jsonMode = false,
    double temperature = 0.8,
  }) async {
    final apiKey = await ApiKeyStore.getKey();
    if (apiKey.isEmpty) {
      throw GeminiException(
        'Gemini API key belum diatur. Buka Profil → Pengaturan Akun → API Key Gemini.',
      );
    }

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': temperature,
        if (jsonMode) 'responseMimeType': 'application/json',
      },
    };

    http.Response response;
    try {
      response = await http
          .post(
            _endpoint(apiKey),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw GeminiException('Gagal terhubung ke Gemini API: $e');
    }

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        detail = decoded['error']?['message']?.toString() ?? response.body;
      } catch (_) {}
      throw GeminiException('Gemini API error (${response.statusCode}):$detail');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('Gemini API tidak mengembalikan hasil apa pun.');
    }

    final parts = candidates.first['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw GeminiException('Format respons Gemini API tidak sesuai.');
    }

    return parts.map((p) => p['text']?.toString() ?? '').join();
  }

  /// Membaca foto bahan dan mengembalikan nama bahan yang terlihat.
  Future<List<String>> detectIngredients({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    final apiKey = await ApiKeyStore.getKey();
    if (apiKey.isEmpty) {
      throw GeminiException(
        'Gemini API key belum diatur. Buka Profil → Pengaturan Akun → API Key Gemini.',
      );
    }

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            {
              'text': '''Analisis foto bahan makanan ini. Identifikasi hanya bahan makanan yang terlihat jelas.
Balas HANYA dengan JSON array string dalam Bahasa Indonesia, misalnya ["Telur", "Tomat", "Bawang putih"].
Jangan masukkan alat masak, kemasan, meja, bumbu yang tidak terlihat, atau penjelasan lain.''',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      },
    };

    http.Response response;
    try {
      response = await http
          .post(
            _endpoint(apiKey),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw GeminiException('Gagal mengirim foto ke Gemini API: $e');
    }

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        detail = decoded['error']?['message']?.toString() ?? response.body;
      } catch (_) {}
      throw GeminiException('Gemini API error (${response.statusCode}):$detail');
    }

    final raw = await _extractText(response);
    final decoded = _decodeJson(raw);
    if (decoded is! List) {
      throw GeminiException('Format daftar bahan dari Gemini tidak dikenali.');
    }

    return decoded
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<String> _extractText(http.Response response) async {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('Gemini API tidak mengembalikan hasil deteksi.');
    }
    final parts = candidates.first['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw GeminiException('Format respons deteksi Gemini tidak sesuai.');
    }
    return parts.map((p) => p['text']?.toString() ?? '').join();
  }

  /// Membersihkan output Gemini dari pagar kode ```json ... ``` jika ada.
  dynamic _decodeJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
    }
    return jsonDecode(text.trim());
  }

  /// Meminta Gemini membuat daftar rekomendasi resep lengkap dalam format JSON.
  Future<List<Recipe>> generateRecipes({
    required List<String> ingredients,
    required String portion,
    required String cookTime,
    UserProfile? profile,
    bool followHealthProfile = false,
    int count = 5,
    String? userToken, // Opsional: Tambahkan token JWT untuk simpan ke backend
  }) async {
    final healthContext = followHealthProfile && profile != null
        ? '''
Perhatikan juga profil kesehatan pengguna berikut, dan WAJIB sertakan field
"healthWarning" berisi peringatan singkat (bahasa Indonesia) jika ada bahan
dalam resep yang berpotensi berbahaya/tidak disarankan untuk kondisi ini
(misal karena alergi atau kondisi medis). Jika aman, biarkan healthWarning null.
Profil kesehatan (JSON): ${jsonEncode(profile.toPromptContext())}
'''
        : 'Pengguna tidak mengaktifkan profil kesehatan, jadi field healthWarning boleh null.';

    final prompt = '''
Kamu adalah asisten dapur AI bernama "CookMate". Buatkan $count rekomendasi resep masakan
Indonesia sehari-hari menggunakan bahan-bahan berikut sebagai basis utama: ${ingredients.join(', ')}.

Preferensi pengguna:
- Porsi: $portion
- Waktu memasak yang diinginkan: $cookTime

$healthContext

Balas HANYA dengan JSON array (tanpa teks lain, tanpa markdown), setiap elemen array
mengikuti schema persis berikut:
{
  "id": "string unik singkat, mis. recipe_1",
  "title": "nama resep",
  "description": "1-2 kalimat deskripsi singkat & menggugah selera",
  "difficulty": "Mudah | Sedang | Sulit",
  "time": "contoh: 20 menit",
  "servings": "contoh: 2 Porsi",
  "tags": ["#Tag1", "#Tag2"],
  "matchPercent": angka 0-100 seberapa cocok resep ini dengan bahan & preferensi pengguna,
  "ingredientsOwned": [{"nama": "nama bahan", "jumlah": "takaran"}],
  "ingredientsToBuy": [{"nama": "nama bahan tambahan yang perlu dibeli", "jumlah": "takaran"}],
  "steps": ["langkah 1", "langkah 2", "..."],
  "nutrition": {"kalori": "320 kcal", "protein": "24g", "karbo": "12g", "lemak": "18g"},
  "aiTips": ["tips memasak singkat 1", "tips singkat 2"],
  "healthWarning": null atau "string peringatan singkat"
}

Urutkan array dari matchPercent tertinggi ke terendah.
''';

    final raw = await _generateRaw(prompt, jsonMode: true, temperature: 0.9);
    final decoded = _decodeJson(raw);

    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['recipes'] is List) {
      list = decoded['recipes'] as List;
    } else {
      throw GeminiException('Format resep dari Gemini tidak dikenali.');
    }

    final recipes = [
      for (var i = 0; i < list.length; i++)
        Recipe.fromJson(Map<String, dynamic>.from(list[i] as Map), fallbackIndex: i),
    ];

    // Opsional: Simpan hasil resep ke MongoDB melalui backend jika token disertakan
    if (userToken != null && userToken.isNotEmpty) {
      for (var recipe in recipes) {
        _saveRecipeToBackend(recipe, userToken);
      }
    }

    return recipes;
  }

  /// Balasan chatbot "CookMate Bot" — percakapan bebas seputar resep & bahan.
  Future<String> sendChatMessage({
    required String message,
    required List<ChatMessage> history,
    List<String> contextIngredients = const [],
    String? userToken, // Opsional: Tambahkan token JWT untuk simpan riwayat chat ke backend
  }) async {
    final historyText = history
        .take(10)
        .map((m) => '${m.role == ChatRole.user ? 'Pengguna' : 'CookMate Bot'}: ${m.text}')
        .join('\n');

    final prompt = '''
Kamu adalah "CookMate Bot", asisten memasak AI yang ramah, ringkas, dan menggunakan Bahasa
Indonesia santai (boleh pakai 1-2 emoji relevan, jangan berlebihan). Bantu pengguna seputar
resep, bahan masakan, substitusi bahan, atau info nutrisi.

Bahan yang sedang dipilih pengguna saat ini: ${contextIngredients.isEmpty ? '(belum ada)' : contextIngredients.join(', ')}.

Riwayat percakapan sebelumnya:
$historyText

Pesan baru dari pengguna: "$message"

Balas dengan 1-3 kalimat singkat, jelas, dan actionable. Jangan gunakan format JSON atau markdown.
''';

    final raw = await _generateRaw(prompt, temperature: 0.85);
    final reply = raw.trim();

    // Opsional: Simpan pesan user & bot ke MongoDB melalui backend jika token disertakan
    if (userToken != null && userToken.isNotEmpty) {
      _saveChatMessageToBackend('user', message, userToken);
      _saveChatMessageToBackend('bot', reply, userToken);
    }

    return reply;
  }

  // --- INTEGRASI BACKEND (Express + MongoDB) ---

  /// Fungsi internal untuk mengirim resep ke Endpoint POST /api/recipes
  Future<void> _saveRecipeToBackend(Recipe recipe, String token) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(recipe.toJson()),
      );
    } catch (_) {
      // Mengabaikan error simpan background agar flow UI tidak terganggu
    }
  }

  /// Fungsi internal untuk mengirim riwayat pesan ke Endpoint POST /api/chat
  Future<void> _saveChatMessageToBackend(String role, String text, String token) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'role': role, 'text': text}),
      );
    } catch (_) {
      // Mengabaikan error simpan background
    }
  }
}