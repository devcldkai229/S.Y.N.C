/// Hero carousel slides for the exercise catalog (MP4 / image ready).
class ExerciseCatalogHeroSlide {
  const ExerciseCatalogHeroSlide({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.videoUrl,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? videoUrl;
}

abstract final class ExerciseCatalogPromos {
  static const slides = [
    ExerciseCatalogHeroSlide(
      eyebrow: 'MEMBER EXCLUSIVE',
      title: 'Chinh phục sức mạnh',
      subtitle: 'Chương trình AI tuần này dành cho bạn',
      imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a55?w=1200&q=80',
    ),
    ExerciseCatalogHeroSlide(
      eyebrow: 'SYNC TRAINING',
      title: 'Đốt mỡ nhanh chóng',
      subtitle: 'Đốt mỡ hiệu quả với MET tối ưu',
      imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80',
    ),
    ExerciseCatalogHeroSlide(
      eyebrow: 'RECOVERY',
      title: 'Cân chỉnh & Phục hồi',
      subtitle: 'Phục hồi nhanh, tập bền hơn',
      imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=1200&q=80',
    ),
  ];
}

/// Filter chips mapped to [ExerciseCategory] enum values from backend.
abstract final class ExerciseCatalogCategories {
  static const all = 'All';
  static const options = [
  all,
  'Strength',
  'Cardio',
  'Flexibility',
  'Mobility',
];
}
