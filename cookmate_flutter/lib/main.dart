import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'theme/app_theme.dart';
import 'views/auth_page.dart';
import 'views/health_profile.dart';
import 'views/home_page.dart';
import 'views/profile_page.dart';

void main() {
  runApp(const CookMateApp());
}

/// Root widget aplikasi — menggantikan main.tsx.
class CookMateApp extends StatelessWidget {
  const CookMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookMate AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppRoot(),
    );
  }
}

/// Tahapan alur utama aplikasi.
enum _Stage { auth, health, home }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

/// Mengatur alur navigasi utama aplikasi (auth -> health -> home -> profile),
/// menggantikan logic switching halaman yang sebelumnya ada di App.tsx.
///
/// PENTING: perpindahan auth -> health -> home dilakukan lewat setState()
/// yang mengubah `_stage`, BUKAN lewat Navigator.pushReplacement(). Alasannya:
/// AppRoot adalah widget root yang tampil di route awal Navigator bawaan
/// MaterialApp. Kalau route itu sendiri di-pushReplacement, maka _AppRootState
/// ikut ter-dispose — akibatnya callback (mis. onComplete di HealthProfile)
/// yang masih menyimpan referensi ke method di State ini akan memanggil
/// setState() pada State yang sudah dibuang, dan itu menyebabkan aplikasi
/// "macet" (loading tidak pernah selesai) tanpa error yang terlihat user.
/// Navigator.push tetap dipakai untuk halaman yang memang perlu bisa di-pop,
/// seperti ProfilePage.
class _AppRootState extends State<AppRoot> {
  UserProfile profile = UserProfile.empty();
  _Stage stage = _Stage.auth;

  void _goToHealthProfile() {
    setState(() => stage = _Stage.health);
  }

  void _goToHome() {
    setState(() => stage = _Stage.home);
  }

  void _goToAuth() {
    setState(() {
      stage = _Stage.auth;
      profile = UserProfile.empty();
    });
  }

  Widget _buildHome() {
    return HomePage(
      profile: profile,
      onProfileChanged: (p) => setState(() => profile = p),
      onOpenProfilePage: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              profile: profile,
              onLogout: _goToAuth,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case _Stage.auth:
        return AuthPage(onLogin: _goToHealthProfile);
      case _Stage.health:
        return HealthProfile(
          onComplete: (p) {
            setState(() => profile = p);
            _goToHome();
          },
        );
      case _Stage.home:
        return _buildHome();
    }
  }
}
