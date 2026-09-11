import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';

/// Halaman detail resep — menggantikan RecipeDetail.tsx.
/// Semua data (bahan, langkah, nutrisi, tips AI, peringatan kesehatan)
/// berasal dari objek [Recipe] yang dihasilkan Gemini API.
class RecipeDetail extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetail({super.key, required this.recipe});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

String _foodImageUrl(String query) {
  final normalized = query.toLowerCase();
  if (normalized.contains('nasi') || normalized.contains('goreng')) {
    return 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=1200&q=85';
  }
  if (normalized.contains('pasta') || normalized.contains('spaghetti')) {
    return 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=1200&q=85';
  }
  if (normalized.contains('salad') || normalized.contains('sayur')) {
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=85';
  }
  if (normalized.contains('ayam') || normalized.contains('chicken')) {
    return 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=1200&q=85';
  }
  return 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=85';
}

class _RecipeDetailState extends State<RecipeDetail> {
  bool bahanTab = true;
  bool showChecklist = false;
  bool showCookingSteps = false;
  int _checklistIndex = 0;
  int _stepIndex = 0;
  final Set<String> _checkedIngredients = {};
  late bool saved;

  @override
  void initState() {
    super.initState();
    saved = widget.recipe.isSaved;
  }

  List<RecipeIngredient> get _prepChecklistItems {
    final list = <RecipeIngredient>[];
    for (final item in widget.recipe.ingredientsOwned) {
      if (!list.any((it) => it.name == item.name)) {
        list.add(item);
      }
    }
    for (final item in widget.recipe.ingredientsToBuy) {
      if (!list.any((it) => it.name == item.name)) {
        list.add(item);
      }
    }
    return list;
  }

  RecipeIngredient? get _currentChecklistItem {
    final items = _prepChecklistItems;
    if (items.isEmpty || _checklistIndex >= items.length) return null;
    return items[_checklistIndex];
  }

  void _toggleChecklistItem(String name) {
    setState(() {
      if (_checkedIngredients.contains(name)) {
        _checkedIngredients.remove(name);
      } else {
        _checkedIngredients.add(name);
      }
    });
  }

  void _startChecklist() {
    setState(() {
      showChecklist = true;
      showCookingSteps = false;
      bahanTab = true;
      _checklistIndex = 0;
    });
  }

  void _advanceChecklist() {
    final item = _currentChecklistItem;
    if (item != null) {
      _checkedIngredients.add(item.name);
    }

    setState(() {
      final items = _prepChecklistItems;
      if (_checklistIndex < items.length - 1) {
        _checklistIndex += 1;
      } else {
        showChecklist = false;
        bahanTab = false;
        showCookingSteps = true;
        _stepIndex = 0;
        _checklistIndex = 0;
      }
    });
  }

  void _goToCookingSteps() {
    setState(() {
      showChecklist = false;
      bahanTab = false;
      showCookingSteps = true;
      _stepIndex = 0;
      _checklistIndex = 0;
    });
  }

  void _advanceCookingStep(Recipe recipe) {
    setState(() {
      if (_stepIndex < recipe.steps.length - 1) {
        _stepIndex += 1;
      } else {
        showCookingSteps = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Image.network(
                  _foodImageUrl(recipe.imageQuery),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A2330),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant, color: Colors.white70, size: 48),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(recipe.title,
                                textAlign: TextAlign.center,
                                style: AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0, 0.4, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('Kembali', style: AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => saved = !saved),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: saved ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(saved ? '❤️' : '🤍', style: const TextStyle(fontSize: 16))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: AppText.heading(size: 24, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _badge('⚡', recipe.difficulty),
                        _badge('⏱', recipe.time),
                        _badge('🍽', recipe.servings),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (recipe.healthWarning != null && recipe.healthWarning!.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                border: Border.all(color: AppColors.redBorder, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD12929), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Peringatan Kesehatan',
                            style: AppText.heading(size: 13, color: const Color(0xFFC0151A))),
                        const SizedBox(height: 4),
                        Text(recipe.healthWarning!,
                            style: AppText.body(size: 12, weight: FontWeight.w600, color: const Color(0xFFA03030), height: 1.55)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.fieldBg, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(child: _tabButton('🛒 Bahan', bahanTab, () => setState(() {
                    bahanTab = true;
                    showCookingSteps = false;
                  }))),
                  Expanded(child: _tabButton('👨‍🍳 Langkah', !bahanTab, _goToCookingSteps)),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: showChecklist
                  ? _prepChecklistContent(recipe)
                  : (bahanTab ? _bahanContent(recipe) : (showCookingSteps ? _cookingStepContent(recipe) : _langkahContent(recipe))),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: showChecklist
                  ? (_currentChecklistItem == null ? _goToCookingSteps : _advanceChecklist)
                  : (showCookingSteps ? () => _advanceCookingStep(recipe) : _startChecklist),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👨‍🍳', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(
                        showChecklist
                          ? (_currentChecklistItem == null ? 'Lanjut ke Langkah Memasak' : 'Lanjut')
                          : (showCookingSteps
                            ? (_stepIndex == recipe.steps.length - 1 ? 'Selesai Memasak' : 'Lanjut')
                            : 'Mulai Memasak'),
                      style: AppText.heading(size: 15, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label, style: AppText.body(size: 11, weight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)] : null,
        ),
        child: Center(
          child: Text(label,
              style: AppText.heading(size: 13, color: active ? AppColors.primaryDarker : AppColors.textGrey)),
        ),
      ),
    );
  }

  Widget _prepChecklistContent(Recipe recipe) {
    final items = _prepChecklistItems;
    final currentItem = _currentChecklistItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('✅', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Cek bahan sebelum mulai masak', style: AppText.heading(size: 17)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text('${_checklistIndex + 1}', style: AppText.heading(size: 14, color: AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'dari ${items.length}',
                    style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.textGrey),
                  ),
                ),
                Container(
                  width: 100,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: items.isEmpty ? 0 : ((_checklistIndex + 1) / items.length),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('Tidak ada bahan yang perlu diceklist.', style: AppText.body(size: 13, color: AppColors.textGrey)),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.18, 0), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Container(
              key: ValueKey(currentItem?.name ?? 'done'),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _checkedIngredients.contains(currentItem?.name) ? const Color(0xFFF7FFF9) : Colors.white,
                border: Border.all(
                  color: _checkedIngredients.contains(currentItem?.name) ? const Color(0xFFC8F0DA) : AppColors.border,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: currentItem == null
                  ? const SizedBox.shrink()
                  : CheckboxListTile(
                      value: _checkedIngredients.contains(currentItem.name),
                      onChanged: (_) => _toggleChecklistItem(currentItem.name),
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(currentItem.name, style: AppText.body(size: 15, weight: FontWeight.w700)),
                      subtitle: currentItem.amount.isEmpty
                          ? null
                          : Text(currentItem.amount, style: AppText.body(size: 12, color: AppColors.textGrey)),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _bahanContent(Recipe recipe) {
    final n = recipe.nutrition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _nutriBox('Kalori', n.calories),
            const SizedBox(width: 8),
            _nutriBox('Protein', n.protein),
            const SizedBox(width: 8),
            _nutriBox('Karbo', n.carbs),
            const SizedBox(width: 8),
            _nutriBox('Lemak', n.fat),
          ],
        ),
        const SizedBox(height: 20),
        _sectionHeader('✅', 'Bahan yang Sudah Ada', '${recipe.ingredientsOwned.length} bahan', AppColors.primarySoft, AppColors.primary),
        const SizedBox(height: 12),
        for (final b in recipe.ingredientsOwned) _ownedIngredientTile(b),
        const SizedBox(height: 20),
        _sectionHeader('🛒', 'Bahan yang Perlu Dibeli', '${recipe.ingredientsToBuy.length} bahan', AppColors.amberBg, AppColors.amber),
        const SizedBox(height: 12),
        for (final b in recipe.ingredientsToBuy) _toBuyIngredientTile(b),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppColors.primary, width: 2, style: BorderStyle.solid),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('+  Tambah ke Daftar Belanja',
              style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _nutriBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(label.toUpperCase(), style: AppText.body(size: 10, weight: FontWeight.w700, color: AppColors.textGrey)),
            const SizedBox(height: 3),
            Text(value, style: AppText.heading(size: 15), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String icon, String title, String badge, Color bg, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppText.heading(size: 15))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
          child: Text(badge, style: AppText.body(size: 11, weight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }

  Widget _ownedIngredientTile(RecipeIngredient b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FFF9),
        border: Border.all(color: const Color(0xFFC8F0DA), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(b.name, style: AppText.body(size: 14, weight: FontWeight.w600))),
          Text(b.amount, style: AppText.body(size: 12, weight: FontWeight.w600, color: const Color(0xFF5CAF88))),
        ],
      ),
    );
  }

  Widget _toBuyIngredientTile(RecipeIngredient b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        border: Border.all(color: const Color(0xFFFFE5B8), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFFD166), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(b.name, style: AppText.body(size: 14, weight: FontWeight.w600))),
          Text(b.amount, style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.amber)),
        ],
      ),
    );
  }

  Widget _cookingStepContent(Recipe recipe) {
    if (recipe.steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(14)),
        child: Text('Belum ada langkah memasak dari resep ini.', style: AppText.body(size: 13, color: AppColors.textGrey)),
      );
    }

    final currentStep = recipe.steps[_stepIndex];
    final progress = (_stepIndex + 1) / recipe.steps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('👨‍🍳', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('Ikuti langkah memasak', style: AppText.heading(size: 17))),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Text('${_stepIndex + 1}', style: AppText.heading(size: 14, color: AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: Text('dari ${recipe.steps.length}', style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.textGrey))),
              SizedBox(
                width: 100,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(animation);
            return SlideTransition(position: slide, child: FadeTransition(opacity: animation, child: child));
          },
          child: Container(
            key: ValueKey(_stepIndex),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primarySoftBorder, width: 1.5),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LANGKAH ${_stepIndex + 1}', style: AppText.body(size: 11, weight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 10),
                Text(currentStep, style: AppText.body(size: 16, weight: FontWeight.w600, height: 1.6)),
              ],
            ),
          ),
        ),
        if (recipe.aiTips.isNotEmpty && _stepIndex == recipe.steps.length - 1) ...[
          const SizedBox(height: 18),
          _aiTipsCard(recipe.aiTips),
        ],
      ],
    );
  }

  Widget _langkahContent(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('📋', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
            Text('Langkah Memasak', style: AppText.heading(size: 15)),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < recipe.steps.length; i++) _stepTile(i, recipe.steps[i], i == recipe.steps.length - 1),
        const SizedBox(height: 8),
        if (recipe.aiTips.isNotEmpty) _aiTipsCard(recipe.aiTips),
      ],
    );
  }

  Widget _stepTile(int index, String step, bool isLast) {
    final first = index == 0;
    return IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: first ? AppColors.primary : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: AppText.heading(size: 14, color: first ? Colors.white : AppColors.primary)),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.primarySoft)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: first ? const Color(0xFFF7FFF9) : const Color(0xFFFAFBFC),
                  border: Border.all(color: first ? const Color(0xFFC8F0DA) : AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(step, style: AppText.body(size: 13, weight: FontWeight.w600, height: 1.55)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiTipsCard(List<String> tips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradientDeep,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tips AI', style: AppText.heading(size: 13, color: Colors.white)),
                    Text('dari CookMate Bot', style: AppText.body(size: 11, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(50)),
                child: const Text('✨ AI Insight', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tip in tips)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(tip, style: AppText.body(size: 12, weight: FontWeight.w600, color: Colors.white, height: 1.5)),
            ),
        ],
      ),
    );
  }
}
