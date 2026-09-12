import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'recipe_results.dart';

const _kAllIngredients = ['Telur', 'Sosis', 'Nasi', 'Ayam', 'Bawang', 'Tahu', 'Tempe', 'Wortel'];
const _kPortionOptions = ['1 Porsi', '2 Porsi', '3-4 Porsi', '5+ Porsi'];
const _kTimeOptions = ['< 15 menit', '15–30 menit', '30–60 menit', '> 60 menit'];
const _kDietGoalOptions = [
  'Turun Berat Badan',
  'Tinggi Protein',
  'Vegetarian',
  'Rendah Gula',
  'Rendah Garam',
];

/// Halaman utama (Beranda) — menggantikan bagian utama App.tsx:
/// pemilihan bahan, preferensi porsi/waktu/gender/medis/alergi/diet,
/// tombol "Cari Resep" (memanggil Gemini API), dan FAB chatbot.
class HomePage extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onOpenProfilePage;
  final String? userToken;

  const HomePage({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.onOpenProfilePage,
    this.userToken,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GeminiService _gemini = GeminiService();
  final ImagePicker _imagePicker = ImagePicker();

  List<String> selectedIngredients = ['Telur', 'Nasi', 'Sosis', 'Ayam'];
  final customIngredientCtrl = TextEditingController();
  String portion = '2 Porsi';
  String cookTime = '15–30 menit';
  bool followHealth = false;
  bool searching = false;
  bool detectingIngredients = false;
  String? searchError;
  final List<String> _recipeHistory = [];

  int _bottomNavIndex = 0; // 0 = home, 1 = riwayat, 2 = profil

  @override
  void dispose() {
    customIngredientCtrl.dispose();
    super.dispose();
  }

  void _toggleIngredient(String item) {
    setState(() {
      if (selectedIngredients.contains(item)) {
        selectedIngredients.remove(item);
      } else {
        selectedIngredients.add(item);
      }
    });
  }

  void _addCustomIngredient(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    setState(() {
      if (!selectedIngredients.contains(v)) selectedIngredients.add(v);
      customIngredientCtrl.clear();
    });
  }

  Future<void> _detectIngredientsFromCamera() async {
    if (detectingIngredients) return;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;

      setState(() => detectingIngredients = true);
      final detected = await _gemini.detectIngredients(
        imageBytes: await image.readAsBytes(),
        mimeType: image.mimeType ?? 'image/jpeg',
      );
      if (!mounted) return;

      final newIngredients = detected.where((item) => !selectedIngredients.any((selected) => selected.toLowerCase() == item.toLowerCase())).toList();
      setState(() {
        selectedIngredients.addAll(newIngredients);
        detectingIngredients = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newIngredients.isEmpty
              ? 'Tidak ada bahan baru yang terdeteksi.'
              : 'Bahan terdeteksi: ${newIngredients.join(', ')}'),
        ),
      );
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => detectingIngredients = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => detectingIngredients = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera atau deteksi bahan gagal: $e')),
      );
    }
  }

  Future<void> _searchRecipes() async {
    if (selectedIngredients.isEmpty) {
      setState(() => searchError = 'Pilih minimal 1 bahan terlebih dahulu.');
      return;
    }
    setState(() {
      searching = true;
      searchError = null;
    });
    try {
      final recipes = await _gemini.generateRecipes(
        ingredients: selectedIngredients,
        portion: portion,
        cookTime: cookTime,
        profile: widget.profile,
        followHealthProfile: followHealth,
        userToken: widget.userToken,
      );
      if (!mounted) return;
      setState(() {
        searching = false;
        final historyEntry = '${selectedIngredients.join(', ')} • $portion • $cookTime';
        if (!_recipeHistory.contains(historyEntry)) {
          _recipeHistory.insert(0, historyEntry);
        } else {
          _recipeHistory.remove(historyEntry);
          _recipeHistory.insert(0, historyEntry);
        }
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeResults(
            recipes: recipes,
            ingredientsSummary: selectedIngredients.join(', '),
          ),
        ),
      );
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        searching = false;
        searchError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        searching = false;
        searchError = 'Terjadi kesalahan: $e';
      });
    }
  }

  void _openHistorySheet() {
    setState(() => _bottomNavIndex = 1);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final items = _recipeHistory.isEmpty
            ? ['Belum ada riwayat pencarian resep.']
            : _recipeHistory;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Riwayat Pencarian', style: AppText.heading(size: 20)),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history, color: AppColors.primary),
                          title: Text(item, style: AppText.body(weight: FontWeight.w600)),
                          onTap: () {
                            if (item == 'Belum ada riwayat pencarian resep.') return;
                            final parts = item.split(' • ');
                            if (parts.length >= 3) {
                              final ingredients = parts[0].split(', ');
                              final portion = parts[1];
                              final cookTime = parts[2];
                              setState(() {
                                selectedIngredients = ingredients;
                                this.portion = portion;
                                this.cookTime = cookTime;
                              });
                            }
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatSheet(
        gemini: _gemini,
        contextIngredients: selectedIngredients,
        userToken: widget.userToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _banner()),
                SliverToBoxAdapter(child: _ingredientSection()),
                SliverToBoxAdapter(child: _preferenceSection()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      children: [
                        if (searchError != null) ...[
                          InlineErrorBox(message: searchError!, onRetry: _searchRecipes),
                          const SizedBox(height: 8),
                        ],
                        PrimaryGradientButton(
                          label: 'Cari Resep',
                          emoji: '🔍',
                          loading: searching,
                          onPressed: _searchRecipes,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChat,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat pagi 👋',
                    style: AppText.body(size: 13, color: AppColors.textGrey, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Hai! Mau masak\napa hari ini?', style: AppText.heading(size: 22, height: 1.25)),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              border: Border.all(color: AppColors.primarySoftBorder, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('🍳', style: TextStyle(fontSize: 24))),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 168,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2DBB6A), Color(0xFF1A2330)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  'https://images.unsplash.com/photo-1504632236107-4ae29a44f388?w=800&h=336&fit=crop&auto=format',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.78),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: Text('✨ Populer', style: AppText.body(size: 11, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESEP HARI INI',
                        style: AppText.body(
                            size: 11, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 3),
                    Text('Sosis Ayam Bakar →', style: AppText.heading(size: 18, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingredientSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pilih Bahan', style: AppText.heading(size: 16)),
              Text('${selectedIngredients.length} dipilih',
                  style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _kAllIngredients)
                SelectableChip(
                  label: item,
                  active: selectedIngredients.contains(item),
                  onTap: () => _toggleIngredient(item),
                ),
              for (final item in selectedIngredients)
                if (!_kAllIngredients.contains(item))
                  SelectableChip(
                    label: item,
                    active: true,
                    onTap: () => _toggleIngredient(item),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('➕', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: customIngredientCtrl,
                    onSubmitted: (value) {
                      _addCustomIngredient(value);
                      FocusScope.of(context).unfocus();
                    },
                    textInputAction: TextInputAction.done,
                    style: AppText.body(size: 13),
                    decoration: InputDecoration(
                      hintText: 'Tambah bahan lainnya...',
                      hintStyle: AppText.body(size: 13, color: AppColors.textMutedGrey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Deteksi bahan dengan kamera',
                  onPressed: detectingIngredients ? null : _detectIngredientsFromCamera,
                  icon: detectingIngredients
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _addCustomIngredient(customIngredientCtrl.text);
                    FocusScope.of(context).unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Tambah', style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferenceSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferensi', style: AppText.heading(size: 16)),
          const SizedBox(height: 12),
          _healthToggle(),
          if (followHealth) ...[
            const SizedBox(height: 14),
            _healthActiveBanner(),
          ],
          const SizedBox(height: 14),
          Opacity(
            opacity: followHealth ? 0.45 : 1,
            child: IgnorePointer(
              ignoring: followHealth,
              child: _customizationCard(),
            ),
          ),
          if (followHealth) ...[
            const SizedBox(height: 8),
            Center(
              child: Text('🔒 Preferensi dikunci oleh profil kesehatan',
                  style: AppText.body(size: 11, color: AppColors.textGrey)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _healthToggle() {
    return GestureDetector(
      onTap: () => setState(() => followHealth = !followHealth),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: followHealth ? AppColors.primarySoft : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: followHealth ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: followHealth ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: followHealth ? AppColors.primary : const Color(0xFFC8D4DF), width: 2),
              ),
              child: followHealth ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ikuti Profil Kesehatan Saya',
                      style: AppText.heading(
                          size: 13, color: followHealth ? AppColors.primaryDarker : AppColors.textDark)),
                  Text(
                    followHealth
                        ? 'Resep disesuaikan dengan kondisi kesehatanmu'
                        : 'Sesuaikan resep dengan kondisi kesehatanmu',
                    style: AppText.body(
                        size: 11, weight: FontWeight.w500, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthActiveBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC0EDCF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🩺', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profil kesehatan aktif',
                    style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.primaryDarker)),
                Text(widget.profile.shortSummary,
                    style: AppText.body(size: 11, color: const Color(0xFF5CAF88))),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onOpenProfilePage,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: Text('Edit', style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _customizationCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _dropdownField('Porsi', portion, _kPortionOptions, (v) => setState(() => portion = v))),
              const SizedBox(width: 10),
              Expanded(child: _ageInputField()),
              const SizedBox(width: 10),
              Expanded(child: _dropdownField('Waktu Memasak', cookTime, _kTimeOptions, (v) => setState(() => cookTime = v))),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF0F4F8), height: 1),
          const SizedBox(height: 14),
          _fieldLabel('Gender'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final g in ['Pria', 'Wanita'])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: g == 'Pria' ? 8 : 0),
                    child: _genderButton(g),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel('Kondisi Medis'),
          const SizedBox(height: 6),
          _textInputField(hint: 'Ketik penyakit (opsional)...', onChanged: (v) {
            widget.onProfileChanged(widget.profile.copyWith(customMedicalCondition: v));
          }),
          const SizedBox(height: 14),
          _fieldLabel('Alergi Makanan'),
          const SizedBox(height: 6),
          _textInputField(hint: 'Ketik alergi (opsional)...', onChanged: (v) {
            widget.onProfileChanged(widget.profile.copyWith(customAllergy: v));
          }),
          const SizedBox(height: 14),
          _fieldLabel('Tujuan Diet'),
          const SizedBox(height: 6),
          _dropdownField(
            null,
            widget.profile.dietGoal ?? 'Pilih tujuan diet...',
            _kDietGoalOptions,
            (v) => widget.onProfileChanged(widget.profile.copyWith(dietGoal: v)),
            placeholder: widget.profile.dietGoal == null,
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text.toUpperCase(),
        style: AppText.body(size: 10, weight: FontWeight.w700, color: AppColors.textGrey),
      );

  Widget _ageInputField() {
    final ageText = widget.profile.age == null ? '' : widget.profile.age.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Umur'),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: ageText,
                selection: TextSelection.collapsed(offset: ageText.length),
              ),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              widget.onProfileChanged(widget.profile.copyWith(age: parsed));
            },
            style: AppText.body(size: 13, weight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Umur',
              hintStyle: AppText.body(size: 13, color: AppColors.textMutedGrey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixText: 'th',
              suffixStyle: AppText.body(size: 12, color: AppColors.textGrey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderButton(String g) {
    final active = widget.profile.gender == g;
    return GestureDetector(
      onTap: () => widget.onProfileChanged(
        widget.profile.copyWith(gender: active ? null : g),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(
            '${g == 'Pria' ? '👨' : '👩'} $g',
            style: AppText.body(
                size: 13, weight: active ? FontWeight.w800 : FontWeight.w600, color: active ? AppColors.primaryDarker : AppColors.textGrey),
          ),
        ),
      ),
    );
  }

  Widget _textInputField({required String hint, required ValueChanged<String> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppText.body(size: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body(size: 13, color: AppColors.textMutedGrey),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String? label,
    String value,
    List<String> options,
    ValueChanged<String> onSelect, {
    bool placeholder = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[_fieldLabel(label), const SizedBox(height: 5)],
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    for (final opt in options)
                      ListTile(
                        title: Text(opt, style: AppText.body(weight: FontWeight.w600)),
                        trailing: opt == value ? const Icon(Icons.check, color: AppColors.primary) : null,
                        onTap: () => Navigator.pop(context, opt),
                      ),
                  ],
                ),
              ),
            );
            if (selected != null) onSelect(selected);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 13,
                      weight: placeholder ? FontWeight.w500 : FontWeight.w700,
                      color: placeholder ? AppColors.textMutedGrey : AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textGrey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomNav() {
    return BottomAppBar(
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, '🏠', 'Beranda'),
            _navItem(1, '📖', 'Riwayat'),
            _navItem(2, '👤', 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, String icon, String label) {
    final active = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          _openHistorySheet();
          return;
        }

        setState(() => _bottomNavIndex = index);
        if (index == 2) widget.onOpenProfilePage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 21)),
            const SizedBox(height: 3),
            Text(label,
                style: AppText.body(
                    size: 10, weight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppColors.primary : AppColors.textMutedGrey)),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet chatbot "CookMate Bot" — terhubung langsung ke Gemini API.
class _ChatSheet extends StatefulWidget {
  final GeminiService gemini;
  final List<String> contextIngredients;
  final String? userToken;

  const _ChatSheet({
    required this.gemini,
    required this.contextIngredients,
    this.userToken,
  });

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      role: ChatRole.bot,
      text: 'Halo! Aku CookMate Bot 🤖\nAda yang bisa aku bantu seputar resep atau bahan masakan hari ini?',
    ),
  ];
  final inputCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  bool botTyping = false;

  @override
  void dispose() {
    inputCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? inputCtrl.text).trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(ChatMessage(id: DateTime.now().toIso8601String(), role: ChatRole.user, text: text));
      inputCtrl.clear();
      botTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await widget.gemini.sendChatMessage(
        message: text,
        history: messages,
        contextIngredients: widget.contextIngredients,
        userToken: widget.userToken,
      );
      if (!mounted) return;
      setState(() {
        messages.add(ChatMessage(id: '${DateTime.now().millisecondsSinceEpoch}', role: ChatRole.bot, text: reply));
        botTyping = false;
      });
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add(ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.bot,
          text: '⚠️ ${e.message}',
        ));
        botTyping = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDE3EC), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(gradient: AppColors.primaryGradientDeep, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CookMate Bot', style: AppText.heading(size: 15)),
                          Row(
                            children: [
                              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text('Online · Gemini AI', style: AppText.body(size: 11, weight: FontWeight.w600, color: const Color(0xFF5CAF88))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F4F8)),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  itemCount: messages.length + (botTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) return _typingBubble();
                    final m = messages[index];
                    return _bubble(m);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final q in ['Rekomendasikan resep 🍽', 'Berapa kalorinya?', 'Bahan apa yang kurang?'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () => _send(q),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF0FBF5),
                              side: const BorderSide(color: Color(0xFFC0EDCF), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.symmetric(horizontal: 13),
                            ),
                            child: Text(q, style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.primaryDarker)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.fieldBg,
                          border: Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: TextField(
                          controller: inputCtrl,
                          onSubmitted: (_) => _send(),
                          style: AppText.body(size: 13),
                          decoration: InputDecoration(
                            hintText: 'Tanya sesuatu tentang resep...',
                            hintStyle: AppText.body(size: 13, color: AppColors.textMutedGrey),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _send(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble(ChatMessage m) {
    final isUser = m.role == ChatRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(gradient: AppColors.primaryGradientDeep, borderRadius: BorderRadius.circular(9)),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : AppColors.primarySoft,
                border: isUser ? null : Border.all(color: const Color(0xFFC0EDCF)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                m.text,
                style: AppText.body(size: 13, weight: FontWeight.w600, color: isUser ? Colors.white : AppColors.textDark, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(gradient: AppColors.primaryGradientDeep, borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              border: Border.all(color: const Color(0xFFC0EDCF)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 30,
              height: 12,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
