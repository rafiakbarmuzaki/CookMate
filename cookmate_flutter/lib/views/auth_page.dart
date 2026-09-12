import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Halaman Login/Daftar — menggantikan AuthPage.tsx.
/// Terhubung ke CookMate Backend (POST /api/auth/register & /api/auth/login).
class AuthPage extends StatefulWidget {
  final void Function(String token, UserProfile user) onLogin;
  const AuthPage({super.key, required this.onLogin});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false;
  bool showPassword = false;
  bool showConfirm = false;
  bool submitting = false;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    // 1. Validasi untuk Mode Login
    if (isLogin) {
      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Email dan password tidak boleh kosong!');
        return;
      }
    } 
    // 2. Validasi untuk Mode Daftar
    else {
      if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
        _showSnackBar('Harap isi semua kolom formulir!');
        return;
      }

      if (password != confirm) {
        _showSnackBar('Password dan Konfirmasi Password tidak cocok!');
        return;
      }
    }

    // 3. Panggil backend (register/login) — menggantikan login palsu.
    setState(() => submitting = true);
    try {
      final AuthResult result;
      if (isLogin) {
        result = await AuthService.instance.login(email: email, password: password);
      } else {
        result = await AuthService.instance.register(
          name: name,
          email: email,
          password: password,
        );
      }
      if (!mounted) return;
      widget.onLogin(result.token, result.user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showSnackBar('Terjadi kesalahan: $e');
    }
  }

  InputDecoration _decoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.body(color: AppColors.textMutedGrey, weight: FontWeight.w500),
      prefixIcon: Icon(icon, size: 19, color: AppColors.textMutedGrey),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.textGrey),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Logo Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradientDeep,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('CookMate AI', style: AppText.heading(size: 20)),
                    const SizedBox(height: 2),
                    Text(
                      'Asisten dapur cerdas untuk kamu',
                      style: AppText.body(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // Tab switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _tabButton('Daftar', !isLogin, () => setState(() => isLogin = false)),
                    _tabButton('Masuk', isLogin, () => setState(() => isLogin = true)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isLogin ? 'Selamat datang 👋' : 'Buat akun baru',
                style: AppText.heading(size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                isLogin
                    ? 'Masuk untuk melanjutkan memasak'
                    : 'Daftar gratis dan mulai memasak hari ini',
                style: AppText.body(color: AppColors.textGrey),
              ),
              const SizedBox(height: 22),

              if (!isLogin) ...[
                _label('Nama Lengkap'),
                TextField(
                  controller: nameCtrl,
                  decoration: _decoration(hint: 'Nama kamu', icon: Icons.person_outline),
                ),
                const SizedBox(height: 14),
              ],

              _label('Email'),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(hint: 'email@kamu.com', icon: Icons.mail_outline),
              ),
              const SizedBox(height: 14),

              _label('Password'),
              TextField(
                controller: passwordCtrl,
                obscureText: !showPassword,
                decoration: _decoration(
                  hint: 'Min. 8 karakter',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.textMutedGrey,
                    ),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
              ),

              if (!isLogin) ...[
                const SizedBox(height: 14),
                _label('Konfirmasi Password'),
                TextField(
                  controller: confirmCtrl,
                  obscureText: !showConfirm,
                  onChanged: (_) => setState(() {}),
                  decoration: _decoration(
                    hint: 'Ulangi password',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 19,
                        color: AppColors.textMutedGrey,
                      ),
                      onPressed: () => setState(() => showConfirm = !showConfirm),
                    ),
                  ),
                ),
                if (confirmCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      confirmCtrl.text == passwordCtrl.text
                          ? '✓ Password cocok'
                          : '✗ Password tidak sama',
                      style: AppText.body(
                        size: 11,
                        color: confirmCtrl.text == passwordCtrl.text
                            ? AppColors.primary
                            : AppColors.red,
                      ),
                    ),
                  ),
              ],

              if (isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Lupa password?',
                        style: AppText.body(weight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),

              if (!isLogin)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text.rich(
                    TextSpan(
                      style: AppText.body(size: 11, color: AppColors.textGrey),
                      children: [
                        const TextSpan(text: 'Dengan mendaftar, kamu menyetujui '),
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: AppText.body(
                              size: 11, weight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const TextSpan(text: ' dan '),
                        TextSpan(
                          text: 'Kebijakan Privasi',
                          style: AppText.body(
                              size: 11, weight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const TextSpan(text: ' kami.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                  ),
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(
                          isLogin ? '🔑  Masuk' : '🚀  Buat Akun',
                          style: AppText.heading(size: 15, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau lanjutkan dengan',
                        style: AppText.body(size: 12, color: AppColors.textMutedGrey)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _socialButton('🌐', 'Google')),
                  const SizedBox(width: 12),
                  Expanded(child: _socialButton('🍎', 'Apple')),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppText.body(color: AppColors.textGrey),
                    children: [
                      TextSpan(text: isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? '),
                      TextSpan(
                        text: isLogin ? 'Daftar sekarang' : 'Masuk',
                        style: AppText.body(weight: FontWeight.w800, color: AppColors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => setState(() => isLogin = !isLogin),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.heading(
                size: 14,
                color: active ? AppColors.primaryDarker : AppColors.textMutedGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(label, style: AppText.body(weight: FontWeight.w700)),
        ],
      ),
    );
  }
}