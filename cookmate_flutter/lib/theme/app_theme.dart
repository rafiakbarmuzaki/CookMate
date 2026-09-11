import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna utama CookMate AI — diambil dari desain prototype asli.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2DBB6A);
  static const Color primaryDark = Color(0xFF1A9E57);
  static const Color primaryDarker = Color(0xFF1A8C4E);
  static const Color primarySoft = Color(0xFFE8F9F0);
  static const Color primarySoftBorder = Color(0xFFA8E6C3);

  static const Color textDark = Color(0xFF1A2330);
  static const Color textGrey = Color(0xFF7A8A99);
  static const Color textMutedGrey = Color(0xFFB0BCC8);

  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5EAF0);
  static const Color fieldBg = Color(0xFFF7F8FA);

  static const Color amber = Color(0xFFF4A836);
  static const Color amberBg = Color(0xFFFFF8ED);
  static const Color amberBorder = Color(0xFFFFD9A0);

  static const Color blue = Color(0xFF6C8EF5);
  static const Color blueBg = Color(0xFFF0F3FF);

  static const Color red = Color(0xFFF87171);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFF5AAAA);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient primaryGradientDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDarker, primary],
  );
}

/// Helper typography — Poppins untuk judul (heading), Nunito untuk isi (body).
class AppText {
  AppText._();

  static TextStyle heading({
    double size = 20,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.textDark,
    double? height,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle body({
    double size = 13,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textDark,
    double? height,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, fontFamily: GoogleFonts.nunito().fontFamily);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textDark),
      titleTextStyle: AppText.heading(size: 17),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primary),
  );
}
