import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan Gemini API key secara lokal di perangkat (SharedPreferences),
/// supaya pengguna tidak perlu rebuild aplikasi hanya untuk mengganti key.
///
/// Alternatif: jalankan aplikasi dengan
///   flutter run --dart-define=GEMINI_API_KEY=xxxxx
/// nilai ini otomatis dipakai sebagai default jika belum ada key tersimpan.
class ApiKeyStore {
  ApiKeyStore._();

  static const _prefKey = 'gemini_api_key';

  // Seluruh key diatur dari kode, bukan dari input user agar hanya developer yang bisa mengganti.
  static const String _defaultKey = '';

  static Future<String> getKey() async {
    // Prioritaskan key statis dari kode agar tidak tertimpa data lama di SharedPreferences.
    return _defaultKey;
  }

  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = key.trim();
    if (value.isEmpty) {
      await prefs.remove(_prefKey);
      return;
    }
    // tetap simpan, tapi aplikasi akan tetap memakai key statis default.
    await prefs.setString(_prefKey, value);
  }

  static Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
