/// Model profil pengguna + profil kesehatan.
/// Menggantikan state yang sebelumnya tersebar di HealthProfile.tsx & ProfilePage.tsx.
class UserProfile {
  final String name;
  final String email;

  // Preferensi umum (diisi di halaman Home / Preferensi)
  final String? gender; // 'Pria' | 'Wanita'
  final int? age;
  final String? customMedicalCondition;
  final String? customAllergy;
  final String? dietGoal;

  // Profil kesehatan (diisi saat onboarding HealthProfile)
  final List<String> medicalConditions; // mis: Hipertensi, Diabetes, Asam Lambung, Kolesterol
  final List<String> foodAllergies; // mis: Seafood, Kacang, Susu, Telur
  final List<String> dietGoals; // mis: Turun Berat Badan, Tinggi Protein, Vegetarian

  const UserProfile({
    this.name = 'Pengguna CookMate',
    this.email = '',
    this.gender,
    this.age,
    this.customMedicalCondition,
    this.customAllergy,
    this.dietGoal,
    this.medicalConditions = const [],
    this.foodAllergies = const [],
    this.dietGoals = const [],
  });

  factory UserProfile.empty() => const UserProfile();

  bool get hasAnyHealthInfo =>
      medicalConditions.isNotEmpty || foodAllergies.isNotEmpty || dietGoals.isNotEmpty;

  /// Ringkasan singkat yang ditampilkan di banner "Profil kesehatan aktif".
  String get shortSummary {
    final parts = <String>[
      ...medicalConditions,
      if (foodAllergies.isNotEmpty) 'Alergi ${foodAllergies.join(' & ')}',
    ];
    if (parts.isEmpty) return 'Belum ada data kesehatan';
    return parts.join(' · ');
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? gender,
    int? age,
    String? customMedicalCondition,
    String? customAllergy,
    String? dietGoal,
    List<String>? medicalConditions,
    List<String>? foodAllergies,
    List<String>? dietGoals,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      customMedicalCondition: customMedicalCondition ?? this.customMedicalCondition,
      customAllergy: customAllergy ?? this.customAllergy,
      dietGoal: dietGoal ?? this.dietGoal,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      dietGoals: dietGoals ?? this.dietGoals,
    );
  }

  /// Representasi ringkas untuk dikirim sebagai konteks ke Gemini API.
  Map<String, dynamic> toPromptContext() {
    return {
      'gender': gender,
      'umur': age,
      'kondisi_medis': [
        ...medicalConditions,
        if (customMedicalCondition != null && customMedicalCondition!.trim().isNotEmpty)
          customMedicalCondition,
      ],
      'alergi_makanan': [
        ...foodAllergies,
        if (customAllergy != null && customAllergy!.trim().isNotEmpty) customAllergy,
      ],
      'tujuan_diet': [
        ...dietGoals,
        if (dietGoal != null && dietGoal!.trim().isNotEmpty) dietGoal,
      ],
    };
  }
}
