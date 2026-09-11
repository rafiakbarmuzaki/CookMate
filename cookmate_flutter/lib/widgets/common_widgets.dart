import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Chip toggle bulat (dipakai di pemilihan bahan & kategori kesehatan).
class SelectableChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? icon;
  final Color activeColor;
  final Color activeBg;

  const SelectableChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.activeColor = AppColors.primary,
    this.activeBg = AppColors.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? activeBg : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: active ? activeColor : AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
            ],
            if (active) ...[
              Icon(Icons.check, size: 13, color: activeColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppText.body(
                size: 13,
                weight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? activeColor : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay loading sederhana dengan pesan, dipakai saat memanggil Gemini API.
class LoadingOverlay extends StatelessWidget {
  final String message;
  const LoadingOverlay({super.key, this.message = 'Memuat...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(message, style: AppText.body(color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

/// Badge kesalahan/inline error ringkas dengan tombol coba lagi.
class InlineErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorBox({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.redBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppText.body(size: 13, color: const Color(0xFFA03030)),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                ),
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tombol utama gradasi hijau, dipakai di banyak halaman (CTA utama).
class PrimaryGradientButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryGradientButton({
    super.key,
    required this.label,
    this.emoji,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: loading ? null : onPressed,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.38),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (emoji != null) ...[
                          Text(emoji!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                        ],
                        Text(label, style: AppText.heading(size: 15, color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
