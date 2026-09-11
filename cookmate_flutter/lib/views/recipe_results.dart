import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import 'recipe_detail.dart';

enum _SortKey { match, rating, time }

/// Halaman daftar hasil rekomendasi resep — menggantikan RecipeResults.tsx.
/// Data resep berasal dari Gemini API (dipanggil di HomePage sebelum navigasi ke sini).
class RecipeResults extends StatefulWidget {
  final List<Recipe> recipes;
  final String ingredientsSummary;

  const RecipeResults({super.key, required this.recipes, required this.ingredientsSummary});

  @override
  State<RecipeResults> createState() => _RecipeResultsState();
}

class _RecipeResultsState extends State<RecipeResults> {
  _SortKey sort = _SortKey.match;
  late List<Recipe> recipes;

  @override
  void initState() {
    super.initState();
    recipes = List.of(widget.recipes);
  }

  List<Recipe> get _sorted {
    final list = List.of(recipes);
    switch (sort) {
      case _SortKey.match:
        list.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
        break;
      case _SortKey.rating:
        // Tidak ada data rating asli dari Gemini, gunakan matchPercent sbg proxy.
        list.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
        break;
      case _SortKey.time:
        list.sort((a, b) => _timeMinutes(a.time).compareTo(_timeMinutes(b.time)));
        break;
    }
    return list;
  }

  int _timeMinutes(String time) {
    final match = RegExp(r'\d+').firstMatch(time);
    return match != null ? int.parse(match.group(0)!) : 999;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 20, 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hasil Rekomendasi', style: AppText.heading(size: 17)),
                              Text('${recipes.length} resep ditemukan untuk kamu',
                                  style: AppText.body(size: 12, color: AppColors.textGrey, weight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            border: Border.all(color: AppColors.primarySoftBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('🤖 AI', style: AppText.body(size: 11, weight: FontWeight.w800, color: AppColors.primaryDarker)),
                        ),
                      ],
                    ),
                  ),
                  if (widget.ingredientsSummary.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FFF9),
                        border: Border.all(color: const Color(0xFFC0EDCF), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('🥘', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.primaryDarker),
                                children: [
                                  const TextSpan(text: 'Berdasarkan: '),
                                  TextSpan(
                                    text: widget.ingredientsSummary,
                                    style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.primaryDarker),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Row(
                      children: [
                        _sortChip('Cocok', _SortKey.match),
                        const SizedBox(width: 8),
                        _sortChip('Rating', _SortKey.rating),
                        const SizedBox(width: 8),
                        _sortChip('Tercepat', _SortKey.time),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: recipes.isEmpty
                  ? Center(
                      child: Text('Belum ada resep untuk ditampilkan.',
                          style: AppText.body(color: AppColors.textGrey)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => _recipeCard(sorted[i], i == 0),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label, _SortKey key) {
    final active = sort == key;
    return GestureDetector(
      onTap: () => setState(() => sort = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.fieldBg,
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          (active ? '✓ ' : '') + label,
          style: AppText.body(size: 12, weight: active ? FontWeight.w800 : FontWeight.w600, color: active ? AppColors.primaryDarker : AppColors.textGrey),
        ),
      ),
    );
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

  Widget _recipeCard(Recipe recipe, bool featured) {
    final matchColor = recipe.matchPercent >= 95
        ? AppColors.primary
        : recipe.matchPercent >= 88
            ? AppColors.amber
            : AppColors.textGrey;
    final matchBg = recipe.matchPercent >= 95
        ? AppColors.primarySoft
        : recipe.matchPercent >= 88
            ? AppColors.amberBg
            : AppColors.fieldBg;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: featured ? 3 : 1,
      shadowColor: featured ? AppColors.primary.withValues(alpha: 0.2) : Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RecipeDetail(recipe: recipe)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 170,
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
                              const Icon(Icons.restaurant, color: Colors.white70, size: 36),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(recipe.title,
                                    textAlign: TextAlign.center,
                                    style: AppText.body(size: 12, weight: FontWeight.w700, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: matchBg,
                        border: Border.all(color: matchColor.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text('${recipe.matchPercent}% cocok',
                          style: AppText.body(size: 11, weight: FontWeight.w800, color: matchColor)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => recipe.isSaved = !recipe.isSaved),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(recipe.isSaved ? '❤️' : '🤍', style: const TextStyle(fontSize: 15))),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(50)),
                      child: Text('⚡ ${recipe.difficulty}', style: AppText.body(size: 11, weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: AppText.heading(size: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 13, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(recipe.time, style: AppText.body(size: 12, color: AppColors.textGrey)),
                        const SizedBox(width: 14),
                        const Icon(Icons.people_outline, size: 13, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(recipe.servings, style: AppText.body(size: 12, color: AppColors.textGrey)),
                      ],
                    ),
                    if (recipe.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(recipe.description,
                          style: AppText.body(size: 12, weight: FontWeight.w500, color: const Color(0xFF5A6A7A), height: 1.5)),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 5,
                            children: [
                              for (final t in recipe.tags)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(50)),
                                  child: Text(t, style: AppText.body(size: 10, weight: FontWeight.w700, color: AppColors.primary)),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(50)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lihat Resep', style: AppText.body(size: 12, weight: FontWeight.w800, color: Colors.white)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
