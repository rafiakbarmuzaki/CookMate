import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class _HealthCategory {
  final String key;
  final String title;
  final String emoji;
  final Color color;
  final Color bg;
  final Color border;
  final String description;
  final List<Map<String, String>> chips; // {label, icon}

  const _HealthCategory({
    required this.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.bg,
    required this.border,
    required this.description,
    required this.chips,
  });
}

const _categories = [
  _HealthCategory(
    key: 'medis',
    title: 'Kondisi Medis',
    emoji: '🩺',
    color: AppColors.primary,
    bg: AppColors.primarySoft,
    border: AppColors.primarySoftBorder,
    description: 'Pilih kondisi kesehatanmu saat ini',
    chips: [
      {'label': 'Hipertensi', 'icon': '❤️'},
      {'label': 'Diabetes', 'icon': '🩸'},
      {'label': 'Asam Lambung', 'icon': '🫁'},
      {'label': 'Kolesterol', 'icon': '🧬'},
    ],
  ),
  _HealthCategory(
    key: 'alergi',
    title: 'Alergi Makanan',
    emoji: '⚠️',
    color: AppColors.amber,
    bg: AppColors.amberBg,
    border: AppColors.amberBorder,
    description: 'Kami akan hindari bahan ini di resepmu',
    chips: [
      {'label': 'Seafood', 'icon': '🦐'},
      {'label': 'Kacang', 'icon': '🥜'},
      {'label': 'Susu', 'icon': '🥛'},
      {'label': 'Telur', 'icon': '🥚'},
    ],
  ),
  _HealthCategory(
    key: 'diet',
    title: 'Tujuan Diet',
    emoji: '🎯',
    color: AppColors.blue,
    bg: AppColors.blueBg,
    border: Color(0xFFC4CFFC),
    description: 'Kami sesuaikan resep dengan tujuanmu',
    chips: [
      {'label': 'Turun Berat Badan', 'icon': '⚖️'},
      {'label': 'Tinggi Protein', 'icon': '💪'},
      {'label': 'Vegetarian', 'icon': '🥦'},
    ],
  ),
];

/// Halaman onboarding profil kesehatan — menggantikan HealthProfile.tsx.
class HealthProfile extends StatefulWidget {
  final void Function(UserProfile profile) onComplete;
  const HealthProfile({super.key, required this.onComplete});

  @override
  State<HealthProfile> createState() => _HealthProfileState();
}

class _HealthProfileState extends State<HealthProfile> {
  final Map<String, List<String>> selected = {'medis': [], 'alergi': [], 'diet': []};
  bool saving = false;

  int get totalSelected => selected.values.fold(0, (sum, l) => sum + l.length);

  void _toggle(String catKey, String label) {
    setState(() {
      final list = selected[catKey]!;
      if (list.contains(label)) {
        list.remove(label);
      } else {
        list.add(label);
      }
    });
  }

  void _save() {
    setState(() => saving = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final profile = UserProfile(
        medicalConditions: selected['medis']!,
        foodAllergies: selected['alergi']!,
        dietGoals: selected['diet']!,
      );
      widget.onComplete(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('LANGKAH 2 DARI 2',
                              style: AppText.body(
                                  size: 11, weight: FontWeight.w700, color: AppColors.textGrey)),
                          Text('Hampir selesai!',
                              style: AppText.body(
                                  size: 11, weight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 5,
                          color: AppColors.primarySoft,
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          border: Border.all(color: AppColors.primarySoftBorder),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text('Personalisasi Resep',
                                style: AppText.body(
                                    size: 12, weight: FontWeight.w700, color: AppColors.primaryDarker)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Bantu Kami Mengenal Kamu 🤝',
                          style: AppText.heading(size: 22, height: 1.25)),
                      const SizedBox(height: 6),
                      Text(
                        'Pilih kondisi kesehatanmu agar resep yang kami rekomendasikan lebih aman dan tepat untukmu.',
                        style: AppText.body(color: AppColors.textGrey, height: 1.5),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      children: [
                        for (final cat in _categories) ...[
                          _categoryCard(cat),
                          const SizedBox(height: 18),
                        ],
                        OutlinedButton(
                          onPressed: _save,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('👍  Tidak ada — saya sehat sepenuhnya!',
                              style: AppText.body(weight: FontWeight.w600, color: AppColors.textGrey)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF0F4F8))),
                  ),
                  child: Column(
                    children: [
                      if (totalSelected > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC0EDCF)),
                          ),
                          child: Row(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$totalSelected preferensi dipilih — resepmu akan dipersonalisasi!',
                                  style: AppText.body(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.primaryDarker),
                                ),
                              ),
                            ],
                          ),
                        ),
                      PrimaryGradientButton(
                        label: saving ? 'Menyimpan...' : 'Simpan & Mulai Memasak',
                        emoji: saving ? '✓' : '🍽',
                        onPressed: _save,
                        loading: saving,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(_HealthCategory cat) {
    final picked = selected[cat.key]!;
    final hasPicked = picked.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasPicked ? cat.border : AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: hasPicked ? cat.color.withValues(alpha: 0.09) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: hasPicked ? cat.bg : const Color(0xFFFAFBFC),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasPicked ? cat.color : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.title, style: AppText.heading(size: 14)),
                      Text(cat.description,
                          style: AppText.body(size: 11, color: AppColors.textGrey, weight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (hasPicked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(50)),
                    child: Text('${picked.length}',
                        style: AppText.heading(size: 11, color: Colors.white)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in cat.chips)
                  SelectableChip(
                    label: chip['label']!,
                    icon: chip['icon'],
                    active: picked.contains(chip['label']),
                    activeColor: cat.color,
                    activeBg: cat.bg,
                    onTap: () => _toggle(cat.key, chip['label']!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
