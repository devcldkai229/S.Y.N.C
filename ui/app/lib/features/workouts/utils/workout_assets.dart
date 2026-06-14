/// Workout asset paths with safe fallbacks when files are missing.
abstract final class WorkoutAssets {
  static const defaultCover = 'assets/workouts/covers/default_cover.jpg';
  static const defaultExercise = 'assets/catalog/exercises/default_exercise.png';
  static const restBackground = 'assets/workouts/banners/banner_fallback.jpg';

  static const bannerFallback = 'assets/workouts/banners/banner_fallback.jpg';
  static const banner1Mp4 = 'assets/workouts/banners/banner_1.mp4';
  static const banner2Mp4 = 'assets/workouts/banners/banner_2.mp4';
  static const banner3Jpg = 'assets/workouts/banners/banner_3.jpg';

  static const celebrateLottie = 'assets/workouts/completion/celebrate.json';

  static String coverForWorkout(String name) {
    // Per-workout covers can be added later; always use a real asset (no salmon placeholder).
    return defaultCover;
  }

  /// Local demo media for exercises (no bundled gifs — use network/catalog API instead).
  static String? localGifForExercise(String name) => null;
}
