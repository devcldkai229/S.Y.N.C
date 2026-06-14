import 'package:flutter/material.dart';

/// Catalog asset paths — safe fallbacks when files are missing.
abstract final class CatalogAssets {
  static const bannerFallback = 'assets/catalog/banners/banner_fallback.jpg';
  static const banner1CatalogMp4 = 'assets/workouts/exercises/banner_1_catalog.mp4';
  static const banner2CatalogMp4 = 'assets/workouts/exercises/banner_2_catalog.mp4';
  static const banner3CatalogMp4 = 'assets/workouts/exercises/banner_3_catalog.mp4';
  static const banner1Mp4 = 'assets/catalog/banners/banner_1.mp4';
  static const banner2 = 'assets/catalog/banners/banner_2.jpg';
  static const banner3 = 'assets/catalog/banners/banner_3.jpg';
  static const defaultExercise = 'assets/catalog/exercises/default_exercise.png';

  static const categoryStrength = 'assets/catalog/categories/strength.jpg';
  static const categoryCardio = 'assets/catalog/categories/cardio.jpg';
  static const categoryFlexibility = 'assets/catalog/categories/flexibility.jpg';
  static const categoryMobility = 'assets/catalog/categories/mobility.jpg';

  static const bodyFront = 'assets/catalog/muscles/body_front.png';
  static const bodyBack = 'assets/catalog/muscles/body_back.png';

  static String? localGifFor(String name) => null;

  static String categoryImage(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return categoryCardio;
      case 'flexibility':
        return categoryFlexibility;
      case 'mobility':
        return categoryMobility;
      default:
        return categoryStrength;
    }
  }
}

/// Muscle browse groups (VN label → filter keyword → icon).
abstract final class CatalogMuscleGroups {
  static const items = [
    (label: 'Ngực', keyword: 'chest', icon: Icons.fitness_center_rounded),
    (label: 'Lưng', keyword: 'back', icon: Icons.self_improvement_rounded),
    (label: 'Chân', keyword: 'leg', icon: Icons.directions_run_rounded),
    (label: 'Vai', keyword: 'shoulder', icon: Icons.open_in_full_rounded),
    (label: 'Tay', keyword: 'arm', icon: Icons.pan_tool_alt_rounded),
    (label: 'Core', keyword: 'core', icon: Icons.center_focus_strong_rounded),
  ];
}
