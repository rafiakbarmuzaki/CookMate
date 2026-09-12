import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

/// Base URL backend Express (CookMate API).
/// - Web/Desktop/iOS simulator: http://localhost:5000/api
/// - Android emulator      : http://10.0.2.2:5000/api
/// - Device fisik          : pakai IP LAN / URL Render saat deploy.
/// Bisa di-override saat run:
///   flutter run --dart-define=BACKEND_URL=http://192.168.x.x:5000/api
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:5000/api',
);

/// Exception khusus untuk error dari backend auth.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Hasil sukses login/register: token JWT + profil user.
class AuthResult {
  final String token;
  final UserProfile user;
  AuthResult({required this.token, required this.user});
}

/// Service auth yang menghubungkan Flutter ke CookMate Backend
/// (endpoint /api/auth/*). Menyimpan token JWT + user aktif secara global.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  String? _token;
  UserProfile? _user;

  String? get token => _token;
  UserProfile? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return _handleAuthResponse(res);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return _handleAuthResponse(res);
  }

  /// Sinkronkan profil kesehatan ke backend (PUT /api/auth/me).
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final res = await _authed('PUT', '/auth/me', {
      'name': profile.name,
      'gender': profile.gender,
      'age': profile.age,
      'medicalConditions': profile.medicalConditions,
      'foodAllergies': profile.foodAllergies,
      'dietGoals': profile.dietGoals,
    });
    if (res.statusCode >= 400) {
      throw AuthException(_message(res));
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final user = UserProfile(
      name: (data['name'] ?? profile.name).toString(),
      email: (data['email'] ?? profile.email).toString(),
      gender: data['gender'] as String?,
      age: data['age'] as int?,
      medicalConditions: _stringList(data['medicalConditions']),
      foodAllergies: _stringList(data['foodAllergies']),
      dietGoals: _stringList(data['dietGoals']),
    );
    _user = user;
    return user;
  }

  AuthResult _handleAuthResponse(http.Response res) {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('Respons server tidak valid.');
    }

    if (res.statusCode >= 400) {
      throw AuthException(_message(res, data));
    }

    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw AuthException('Token tidak ditemukan dari server.');
    }

    final userJson = data['user'] as Map<String, dynamic>? ?? const {};
    final user = UserProfile(
      name: (userJson['name'] ?? 'Pengguna CookMate').toString(),
      email: (userJson['email'] ?? '').toString(),
    );

    _token = token;
    _user = user;
    return AuthResult(token: token, user: user);
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            Uri.parse('$kBackendBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException(
        'Tidak bisa terhubung ke server. Pastikan backend berjalan di '
        '$kBackendBaseUrl (jalankan `npm start` di folder cookmate-backend).',
      );
    }
  }

  Future<http.Response> _authed(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$kBackendBaseUrl$path');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ''}',
      };
      final payload = jsonEncode(body);
      return await (method == 'PUT'
              ? http.put(uri, headers: headers, body: payload)
              : http.post(uri, headers: headers, body: payload))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException('Gagal terhubung ke server.');
    }
  }

  String _message(http.Response res, [Map<String, dynamic>? data]) {
    return (data ?? const {})['message']?.toString() ??
        'Terjadi kesalahan (${res.statusCode}).';
  }

  List<String> _stringList(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : [];

  void logout() {
    _token = null;
    _user = null;
  }
}
