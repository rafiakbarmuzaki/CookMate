/// Model bahan masakan (dipakai untuk "bahan yang sudah ada" & "bahan yang perlu dibeli").
class RecipeIngredient {
  final String name;
  final String amount;

  const RecipeIngredient({required this.name, required this.amount});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: (json['nama'] ?? json['name'] ?? '').toString(),
      amount: (json['jumlah'] ?? json['amount'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
      };
}

/// Ringkasan nilai gizi per porsi.
class NutritionInfo {
  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  const NutritionInfo({
    this.calories = '-',
    this.protein = '-',
    this.carbs = '-',
    this.fat = '-',
  });

  factory NutritionInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NutritionInfo();
    return NutritionInfo(
      calories: (json['kalori'] ?? json['calories'] ?? '-').toString(),
      protein: (json['protein'] ?? '-').toString(),
      carbs: (json['karbo'] ?? json['carbs'] ?? '-').toString(),
      fat: (json['lemak'] ?? json['fat'] ?? '-').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

/// Model resep utama — dihasilkan oleh Gemini API berdasarkan bahan & preferensi pengguna.
/// Menggantikan data statis di RecipeResults.tsx & RecipeDetail.tsx.
class Recipe {
  final String id;
  final String title;
  final String description;
  final String difficulty; // Mudah / Sedang / Sulit
  final String time; // "20 menit"
  final String servings; // "2 Porsi"
  final List<String> tags;
  final int matchPercent;
  final List<RecipeIngredient> ingredientsOwned;
  final List<RecipeIngredient> ingredientsToBuy;
  final List<String> steps;
  final NutritionInfo nutrition;
  final List<String> aiTips;
  final String? healthWarning;

  /// Kata kunci pencarian gambar (Gemini tidak menghasilkan gambar asli,
  /// jadi kita pakai ini sebagai query untuk sumber gambar/placeholder).
  final String imageQuery;

  bool isSaved;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.time,
    required this.servings,
    required this.tags,
    required this.matchPercent,
    required this.ingredientsOwned,
    required this.ingredientsToBuy,
    required this.steps,
    required this.nutrition,
    required this.aiTips,
    this.healthWarning,
    this.isSaved = false,
    String? imageQuery,
  }) : imageQuery = imageQuery ?? title;

  factory Recipe.fromJson(Map<String, dynamic> json, {int fallbackIndex = 0}) {
    return Recipe(
      id: (json['id'] ?? 'recipe_$fallbackIndex').toString(),
      title: (json['title'] ?? json['judul'] ?? 'Resep Tanpa Nama').toString(),
      description: (json['description'] ?? json['deskripsi'] ?? '').toString(),
      difficulty: (json['difficulty'] ?? json['tingkat_kesulitan'] ?? 'Mudah').toString(),
      time: (json['time'] ?? json['waktu'] ?? '-').toString(),
      servings: (json['servings'] ?? json['porsi'] ?? '-').toString(),
      tags: _stringList(json['tags']),
      matchPercent: _asInt(json['matchPercent'] ?? json['match_percent'] ?? json['kecocokan']) ?? 90,
      ingredientsOwned: _ingredientList(json['ingredientsOwned'] ?? json['bahan_ada']),
      ingredientsToBuy: _ingredientList(json['ingredientsToBuy'] ?? json['bahan_beli']),
      steps: _stringList(json['steps'] ?? json['langkah']),
      nutrition: NutritionInfo.fromJson(
        (json['nutrition'] ?? json['nutrisi']) as Map<String, dynamic>?,
      ),
      aiTips: _stringList(json['aiTips'] ?? json['tips_ai'] ?? json['tips']),
      healthWarning: (json['healthWarning'] ?? json['peringatan_kesehatan'])?.toString(),
      imageQuery: (json['imageQuery'] ?? json['title'] ?? json['judul'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'time': time,
        'servings': servings,
        'tags': tags,
        'matchPercent': matchPercent,
        'ingredientsOwned': ingredientsOwned.map((item) => item.toJson()).toList(),
        'ingredientsToBuy': ingredientsToBuy.map((item) => item.toJson()).toList(),
        'steps': steps,
        'nutrition': nutrition.toJson(),
        'aiTips': aiTips,
        'healthWarning': healthWarning,
        'imageQuery': imageQuery,
      };

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static List<RecipeIngredient> _ingredientList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

enum ChatRole { user, bot }

/// Model pesan chat untuk CookMate Bot (didukung Gemini API).
class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
