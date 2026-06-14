import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';

/// Static category/shortcut definitions (categories use [iconForCategoryId] in UI).
abstract final class MarketplaceCatalog {
  static const categories = <CategoryItem>[
    CategoryItem(id: 'healthy', label: 'Healthy'),
    CategoryItem(id: 'eat-clean', label: 'Eat Clean'),
    CategoryItem(id: 'high-protein', label: 'High-Protein'),
    CategoryItem(id: 'salad', label: 'Salad'),
    CategoryItem(id: 'com', label: 'Cơm'),
    CategoryItem(id: 'combo', label: 'Combo'),
    CategoryItem(id: 'drinks', label: 'Đồ uống'),
  ];

  static const allCategoryIcon = Icons.apps_rounded;

  static IconData iconForCategoryId(String id) => switch (id) {
        'healthy' => Icons.favorite_rounded,
        'eat-clean' => Icons.eco_rounded,
        'high-protein' => Icons.fitness_center_rounded,
        'salad' => Icons.grass_rounded,
        'com' => Icons.rice_bowl_rounded,
        'combo' => Icons.set_meal_rounded,
        'drinks' => Icons.local_cafe_rounded,
        'low-carb' => Icons.speed_rounded,
        _ => Icons.restaurant_rounded,
      };

  static const shortcuts = <ShortcutItem>[
    ShortcutItem(
      id: 'nearby',
      title: 'Gần đây',
      subtitle: '',
      imageUrl: 'assets/marketplace/shortcuts/near_you.jpg',
      filterTag: 'nearby',
    ),
    ShortcutItem(
      id: 'macro',
      title: 'Đủ dinh dưỡng',
      subtitle: '',
      imageUrl: 'assets/marketplace/shortcuts/macro_today.png',
      filterTag: 'macro',
    ),
    ShortcutItem(
      id: 'protein',
      title: 'Protein cao',
      subtitle: '',
      imageUrl: 'assets/marketplace/shortcuts/high_protein.jpg',
      filterTag: 'high-protein',
    ),
  ];

  static const allCategoryAsset = 'assets/marketplace/categories/all.png';
  static const heroVideo = 'assets/marketplace/empty/an_healthy_giao_nhanh.mp4';
  static const heroFallback = 'assets/marketplace/hero/hero_fallback.png';
  static const promoBanner1 = 'assets/marketplace/banners/banner_sf_1.png';
  static const promoBanner2 = 'assets/marketplace/banners/banner_sf_2.png';
  static const promoBanner3 = 'assets/marketplace/banners/banner_sf_3.png';
  static const dishPlaceholder = 'assets/marketplace/placeholders/dish_placeholder.png';
  static const kitchenPlaceholder = 'assets/marketplace/placeholders/kitchen_placeholder.png';
  static const emptyFood = 'assets/marketplace/empty/empty_food.png';

  static Map<String, dynamic>? searchParamsForCategory(String? categoryId) {
    if (categoryId == null) return null;
    return switch (categoryId) {
      'healthy' => {'dietaryTags': ['LowFat']},
      'eat-clean' => {'dietaryTags': ['Vegetarian']},
      'high-protein' => {'dietaryTags': ['HighProtein']},
      'salad' => {'category': 'Vegetable'},
      'com' => {'category': 'PreparedMeal'},
      'combo' => {'category': 'PreparedMeal'},
      'drinks' => {'category': 'Beverage'},
      'macro' => {'macroBalanced': true},
      _ => null,
    };
  }

  static String labelForCategoryId(String? categoryId) {
    if (categoryId == null) return 'Tất cả';
    for (final c in categories) {
      if (c.id == categoryId) return c.label;
    }
    return switch (categoryId) {
      'nearby' => 'Gần bạn',
      'macro' => 'Đủ dinh dưỡng',
      _ => categoryId,
    };
  }
}
