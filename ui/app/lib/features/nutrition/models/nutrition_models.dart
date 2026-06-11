class DailyNutritionSummary {
  const DailyNutritionSummary({
    required this.date,
    required this.targetCalories,
    required this.consumedCalories,
    required this.targetProteinGram,
    required this.consumedProteinGram,
    required this.targetCarbGram,
    required this.consumedCarbGram,
    required this.targetFatGram,
    required this.consumedFatGram,
    required this.waterIntakeMl,
    required this.mealsLoggedCount,
  });

  final DateTime date;
  final int targetCalories;
  final int consumedCalories;
  final double targetProteinGram;
  final double consumedProteinGram;
  final double targetCarbGram;
  final double consumedCarbGram;
  final double targetFatGram;
  final double consumedFatGram;
  final int waterIntakeMl;
  final int mealsLoggedCount;

  int get remainingCalories => targetCalories - consumedCalories;
  bool get isOverBudget => remainingCalories < 0;

  factory DailyNutritionSummary.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString() ?? '';
    return DailyNutritionSummary(
      date: DateTime.tryParse(dateStr) ?? DateTime.now(),
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 0,
      consumedCalories: (json['consumedCalories'] as num?)?.toInt() ?? 0,
      targetProteinGram: (json['targetProteinGram'] as num?)?.toDouble() ?? 0,
      consumedProteinGram: (json['consumedProteinGram'] as num?)?.toDouble() ?? 0,
      targetCarbGram: (json['targetCarbGram'] as num?)?.toDouble() ?? 0,
      consumedCarbGram: (json['consumedCarbGram'] as num?)?.toDouble() ?? 0,
      targetFatGram: (json['targetFatGram'] as num?)?.toDouble() ?? 0,
      consumedFatGram: (json['consumedFatGram'] as num?)?.toDouble() ?? 0,
      waterIntakeMl: (json['waterIntakeMl'] as num?)?.toInt() ?? 0,
      mealsLoggedCount: (json['mealsLoggedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MealLogItem {
  const MealLogItem({
    this.foodItemId,
    required this.foodNameSnapshot,
    required this.quantityGram,
    required this.calories,
    required this.proteinGram,
    required this.carbGram,
    required this.fatGram,
  });

  final String? foodItemId;
  final String foodNameSnapshot;
  final double quantityGram;
  final int calories;
  final double proteinGram;
  final double carbGram;
  final double fatGram;

  factory MealLogItem.fromJson(Map<String, dynamic> json) => MealLogItem(
        foodItemId: json['foodItemId']?.toString(),
        foodNameSnapshot: json['foodNameSnapshot']?.toString() ?? '',
        quantityGram: (json['quantityGram'] as num?)?.toDouble() ?? 0,
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        proteinGram: (json['proteinGram'] as num?)?.toDouble() ?? 0,
        carbGram: (json['carbGram'] as num?)?.toDouble() ?? 0,
        fatGram: (json['fatGram'] as num?)?.toDouble() ?? 0,
      );
}

class MealLog {
  const MealLog({
    required this.id,
    required this.mealType,
    required this.loggedAt,
    required this.items,
    required this.totalCalories,
    required this.source,
  });

  final String id;
  final String mealType;
  final DateTime loggedAt;
  final List<MealLogItem> items;
  final int totalCalories;
  final String source;

  factory MealLog.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return MealLog(
      id: json['id']?.toString() ?? '',
      mealType: json['mealType']?.toString() ?? 'Snack',
      loggedAt: DateTime.tryParse(json['loggedAt']?.toString() ?? '') ??
          DateTime.now(),
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(MealLogItem.fromJson)
              .toList()
          : const [],
      totalCalories: (json['totalCalories'] as num?)?.toInt() ?? 0,
      source: json['source']?.toString() ?? 'Manual',
    );
  }
}

class FoodItem {
  const FoodItem({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.category,
    this.brand,
    this.barcode,
    required this.servingSizeGram,
    this.servingDescription,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    this.imageUrl,
  });

  final String id;
  final String nameVi;
  final String nameEn;
  final String category;
  final String? brand;
  final String? barcode;
  final double servingSizeGram;
  final String? servingDescription;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final String? imageUrl;

  String displayName(bool isVi) => isVi ? nameVi : (nameEn.isNotEmpty ? nameEn : nameVi);

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id']?.toString() ?? '',
        nameVi: json['nameVi']?.toString() ?? '',
        nameEn: json['nameEn']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Snack',
        brand: json['brand']?.toString(),
        barcode: json['barcode']?.toString(),
        servingSizeGram: (json['servingSizeGram'] as num?)?.toDouble() ?? 100,
        servingDescription: json['servingDescription']?.toString(),
        caloriesPer100g: (json['caloriesPer100g'] as num?)?.toInt() ?? 0,
        proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0,
        carbPer100g: (json['carbPer100g'] as num?)?.toDouble() ?? 0,
        fatPer100g: (json['fatPer100g'] as num?)?.toDouble() ?? 0,
        imageUrl: json['imageUrl']?.toString(),
      );
}

enum MealTypeUi {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const MealTypeUi(this.apiValue);
  final String apiValue;
}
