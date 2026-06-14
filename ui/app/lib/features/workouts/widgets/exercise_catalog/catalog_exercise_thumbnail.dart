import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/catalog_assets.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';

/// Thumbnail with fallback chain: network → local gif → default png → brand (never grey box).
class CatalogExerciseThumbnail extends StatelessWidget {
  const CatalogExerciseThumbnail({
    super.key,
    this.exercise,
    this.networkUrl,
    this.exerciseName,
    this.width = 72,
    this.height = 72,
    this.borderRadius = 12,
    this.fill = false,
  });

  final ExerciseCatalogItem? exercise;
  final String? networkUrl;
  final String? exerciseName;
  final double width;
  final double height;
  final double borderRadius;
  /// When true, expands to fill the parent (use inside Stack/Expanded, not with infinity dimensions).
  final bool fill;

  String get _name =>
      exerciseName ??
      (exercise?.nameVi.isNotEmpty == true ? exercise!.nameVi : exercise?.nameEn ?? '');

  String? get _network {
    if (networkUrl != null && networkUrl!.isNotEmpty) return networkUrl;
    final t = exercise?.thumbnailUrl;
    if (t != null && t.isNotEmpty) return t;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (fill) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return SizedBox(width: w, height: h, child: _build(w, h));
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: _build(width, height)),
    );
  }

  Widget _build(double w, double h) {
    final net = _network;
    if (net != null) {
      return CachedNetworkImage(
        imageUrl: net,
        fit: BoxFit.cover,
        width: w,
        height: h,
        placeholder: (_, _) => _localOrDefault(w, h, showLoader: true),
        errorWidget: (_, _, _) => _localOrDefault(w, h),
      );
    }
    return _localOrDefault(w, h);
  }

  Widget _localOrDefault(double w, double h, {bool showLoader = false}) {
    final gif = CatalogAssets.localGifFor(_name);
    if (gif != null) {
      return Image.asset(
        gif,
        fit: BoxFit.cover,
        width: w,
        height: h,
        errorBuilder: (_, _, _) => _defaultAsset(w, h, showLoader: showLoader),
      );
    }
    return _defaultAsset(w, h, showLoader: showLoader);
  }

  Widget _defaultAsset(double w, double h, {bool showLoader = false}) {
    return Image.asset(
      CatalogAssets.defaultExercise,
      fit: BoxFit.cover,
      width: w,
      height: h,
      errorBuilder: (_, _, _) => _brandFallback(w, h, showLoader: showLoader),
    );
  }

  Widget _brandFallback(double w, double h, {bool showLoader = false}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ExerciseCatalogTheme.syncLime.withValues(alpha: 0.45),
            ExerciseCatalogTheme.slateDark.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: showLoader
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: ExerciseCatalogTheme.slateDark),
              ),
            )
          : Center(
              child: Icon(Icons.fitness_center_rounded, size: w * 0.38, color: ExerciseCatalogTheme.slateDark),
            ),
    );
  }
}
