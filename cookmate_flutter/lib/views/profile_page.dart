import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_key_store.dart';
import '../theme/app_theme.dart';

/// Halaman profil pengguna — menggantikan ProfilePage.tsx.
/// Juga menjadi tempat pengaturan Gemini API key (menu "API Key Gemini").
class ProfilePage extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.profile, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _openApiKeyDialog() async {
    final currentKey = await ApiKeyStore.getKey();
    if (!mounted) return;
    final ctrl = TextEditingController(text: currentKey);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Gemini'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan Gemini API key kamu (dari Google AI Studio). Key disimpan lokal di perangkat.',
              style: AppText.body(size: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'AIza...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              await ApiKeyStore.saveKey(ctrl.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: const Color(0xFFDDE3EC), borderRadius: BorderRadius.circular(2))),
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Text('👋', style: TextStyle(fontSize: 30))),
              ),
              Text('Keluar dari CookMate?', style: AppText.heading(size: 18)),
              const SizedBox(height: 8),
              Text(
                'Kamu bisa masuk kembali kapan saja.\nResep tersimpanmu tidak akan hilang.',
                textAlign: TextAlign.center,
                style: AppText.body(color: AppColors.textGrey, height: 1.6),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Batal', style: AppText.heading(size: 14, color: AppColors.textGrey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Ya, Keluar', style: AppText.heading(size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final healthCards = [
      {
        'icon': '❤️',
        'iconBg': AppColors.redBg,
        'label': 'Kondisi Medis',
        'value': profile.medicalConditions.isEmpty ? '-' : profile.medicalConditions.join(', '),
        'sub': 'Dari profil kesehatanmu',
      },
      {
        'icon': '⚠️',
        'iconBg': AppColors.redBg,
        'label': 'Alergi',
        'value': profile.foodAllergies.isEmpty ? '-' : profile.foodAllergies.join(', '),
        'sub': 'Resep akan otomatis menyaring',
      },
      {
        'icon': '🎯',
        'iconBg': AppColors.blueBg,
        'label': 'Tujuan Diet',
        'value': profile.dietGoals.isEmpty ? '-' : profile.dietGoals.join(', '),
        'sub': 'Resep disesuaikan dengan tujuanmu',
      },
    ];

    final menuItems = [
      {'icon': '🔑', 'label': 'API Key Gemini', 'action': _openApiKeyDialog},
      {'icon': '🍽', 'label': 'Resep Tersimpan', 'action': null},
      {'icon': '🔔', 'label': 'Notifikasi', 'action': null},
      {'icon': '❓', 'label': 'Bantuan & FAQ', 'action': null},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '👤',
                        style: AppText.heading(size: 26, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: AppText.heading(size: 17)),
                        Text(profile.email.isEmpty ? '-' : profile.email,
                            style: AppText.body(size: 12, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🩺', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Text('Profil Kesehatan', style: AppText.heading(size: 15)),
              ],
            ),
            const SizedBox(height: 10),
            for (final card in healthCards)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: card['iconBg'] as Color, borderRadius: BorderRadius.circular(13)),
                      child: Center(child: Text(card['icon'] as String, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((card['label'] as String).toUpperCase(),
                              style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.textGrey)),
                          Text(card['value'] as String, style: AppText.heading(size: 14)),
                          Text(card['sub'] as String, style: AppText.body(size: 11, color: AppColors.textMutedGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Text('Pengaturan', style: AppText.heading(size: 15)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < menuItems.length; i++) ...[
                    ListTile(
                      leading: Text(menuItems[i]['icon'] as String, style: const TextStyle(fontSize: 18)),
                      title: Text(menuItems[i]['label'] as String, style: AppText.body(size: 14, weight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedGrey),
                      onTap: menuItems[i]['action'] as VoidCallback?,
                    ),
                    if (i < menuItems.length - 1) const Divider(height: 1, color: Color(0xFFF0F4F8)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _confirmLogout,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.red, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 18, color: AppColors.red),
                    const SizedBox(width: 10),
                    Text('Keluar Akun', style: AppText.heading(size: 14, color: AppColors.red)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
