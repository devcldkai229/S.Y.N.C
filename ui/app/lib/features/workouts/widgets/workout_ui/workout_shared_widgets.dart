import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/exercise_media_url_resolver.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/utils/workout_assets.dart';

// ─── Stat chip ───────────────────────────────────────────────────────────────

class WorkoutStatChip extends StatelessWidget {
  const WorkoutStatChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WorkoutTheme.card,
        borderRadius: WorkoutTheme.radiusMd,
        border: Border.all(color: WorkoutTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: WorkoutTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WorkoutTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Tag chip ────────────────────────────────────────────────────────────────

class WorkoutTagChip extends StatelessWidget {
  const WorkoutTagChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? WorkoutTheme.sage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class WorkoutEmptyState extends StatelessWidget {
  const WorkoutEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.fitness_center_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: WorkoutTheme.card,
        borderRadius: WorkoutTheme.radiusLg,
        border: Border.all(color: WorkoutTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: WorkoutTheme.lime.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: WorkoutTheme.forest),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: WorkoutTheme.textMuted, height: 1.4)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: WorkoutTheme.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Cover image ─────────────────────────────────────────────────────────────

class WorkoutCoverImage extends StatelessWidget {
  const WorkoutCoverImage({super.key, required this.assetPath, this.networkUrl, this.height = 160});

  final String assetPath;
  final String? networkUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: WorkoutTheme.radiusLg,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: networkUrl != null && networkUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: MediaUrlResolver.resolve(networkUrl) ?? networkUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _assetImage(),
              )
            : _assetImage(),
      ),
    );
  }

  Widget _assetImage() {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: height,
      errorBuilder: (_, _, _) => Image.asset(
        WorkoutAssets.defaultCover,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        errorBuilder: (_, _, _) => _brandCoverFallback(),
      ),
    );
  }

  Widget _brandCoverFallback() {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WorkoutTheme.lime.withValues(alpha: 0.55),
            WorkoutTheme.sage.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, size: 44, color: WorkoutTheme.forest),
      ),
    );
  }
}

// ─── Exercise thumbnail ──────────────────────────────────────────────────────

class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({super.key, required this.exerciseName, this.networkUrl, this.size = 56});

  final String exerciseName;
  final String? networkUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final localGif = WorkoutAssets.localGifForExercise(exerciseName);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildContent(localGif),
      ),
    );
  }

  Widget _buildContent(String? localGif) {
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      final resolved = ExerciseMediaUrlResolver.resolve(networkUrl);
      return CachedNetworkImage(
        imageUrl: resolved ?? networkUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _localOrBrand(localGif),
      );
    }
    return _localOrBrand(localGif);
  }

  Widget _localOrBrand(String? localGif) {
    if (localGif != null) {
      return Image.asset(
        localGif,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultExerciseImage(),
      );
    }
    return _defaultExerciseImage();
  }

  Widget _defaultExerciseImage() {
    return Image.asset(
      WorkoutAssets.defaultExercise,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _brandPlaceholder(),
    );
  }

  Widget _brandPlaceholder() {
    return Container(
      color: WorkoutTheme.lime.withValues(alpha: 0.2),
      child: const Center(child: Icon(Icons.fitness_center_rounded, color: WorkoutTheme.forest, size: 26)),
    );
  }
}

// ─── Workout card (My Workouts list) ─────────────────────────────────────────

class WorkoutListCard extends StatelessWidget {
  const WorkoutListCard({
    super.key,
    required this.workout,
    required this.sessions,
    required this.onTap,
    this.onDelete,
  });

  final UserCustomWorkout workout;
  final List<RoadmapSession> sessions;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final totalExercises = sessions.fold(0, (sum, s) => sum + s.exerciseCount);
    final cover = WorkoutAssets.coverForWorkout(workout.workoutName);
    final coverUrl = workout.coverRoadmapImageUrl;

    return Material(
      color: WorkoutTheme.card,
      borderRadius: WorkoutTheme.radiusLg,
      elevation: 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: WorkoutTheme.radiusLg,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: WorkoutTheme.radiusLg,
            border: Border.all(color: WorkoutTheme.border),
            boxShadow: WorkoutTheme.cardShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkoutCoverImage(assetPath: cover, networkUrl: coverUrl, height: 140),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workout.workoutName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary),
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: WorkoutTheme.textMuted, size: 20),
                            onPressed: () => _showMenu(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        WorkoutTagChip(label: workout.scheduleMode.isNotEmpty ? workout.scheduleMode : 'Manual'),
                        if (workout.allowAiOptimization) const WorkoutTagChip(label: 'AI On', color: WorkoutTheme.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: WorkoutTheme.textMuted),
                        const SizedBox(width: 4),
                        Text('${sessions.length} buổi', style: _statStyle),
                        const SizedBox(width: 14),
                        const Icon(Icons.fitness_center_outlined, size: 14, color: WorkoutTheme.textMuted),
                        const SizedBox(width: 4),
                        Text('$totalExercises bài', style: _statStyle),
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

  static const _statStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WorkoutTheme.textMuted);

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Xóa lộ trình', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Session card ────────────────────────────────────────────────────────────

class SessionListCard extends StatelessWidget {
  const SessionListCard({
    super.key,
    required this.title,
    required this.exerciseCount,
    required this.setCount,
    required this.onTap,
    this.thumbnailExerciseName,
  });

  final String title;
  final int exerciseCount;
  final int setCount;
  final VoidCallback onTap;
  final String? thumbnailExerciseName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WorkoutTheme.card,
      borderRadius: WorkoutTheme.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: WorkoutTheme.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: WorkoutTheme.radiusMd,
            border: Border.all(color: WorkoutTheme.border),
          ),
          child: Row(
            children: [
              ExerciseThumbnail(exerciseName: thumbnailExerciseName ?? title, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('$exerciseCount bài · $setCount sets', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WorkoutTheme.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: WorkoutTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Exercise row (session detail) ───────────────────────────────────────────

class ExerciseListRow extends StatelessWidget {
  const ExerciseListRow({
    super.key,
    required this.index,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
    required this.onTap,
    this.thumbnailUrl,
  });

  final int index;
  final String name;
  final int sets;
  final int reps;
  final double weightKg;
  final int restSeconds;
  final VoidCallback onTap;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final w = weightKg > 0 ? '${weightKg.toStringAsFixed(weightKg.truncateToDouble() == weightKg ? 0 : 1)} kg · ' : '';
    return Material(
      color: WorkoutTheme.card,
      borderRadius: WorkoutTheme.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: WorkoutTheme.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: WorkoutTheme.radiusMd,
            border: Border.all(color: WorkoutTheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: WorkoutTheme.primary,
                child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              ExerciseThumbnail(exerciseName: name, networkUrl: thumbnailUrl, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: WorkoutTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('$sets × $reps · $w nghỉ ${restSeconds}s', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: WorkoutTheme.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: WorkoutTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sticky bottom actions ───────────────────────────────────────────────────

class WorkoutStickyActions extends StatelessWidget {
  const WorkoutStickyActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryEnabled = true,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.paddingOf(context).bottom + 16),
      decoration: BoxDecoration(
        color: WorkoutTheme.card,
        border: Border(top: BorderSide(color: WorkoutTheme.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secondaryLabel != null && onSecondary != null) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: WorkoutTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(secondaryLabel!, style: const TextStyle(fontWeight: FontWeight.w800, color: WorkoutTheme.textPrimary)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: WorkoutTheme.minTouch,
            child: FilledButton(
              onPressed: primaryEnabled ? onPrimary : null,
              style: FilledButton.styleFrom(
                backgroundColor: WorkoutTheme.primary,
                disabledBackgroundColor: WorkoutTheme.border,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero header (workout / session detail) ──────────────────────────────────

class WorkoutHeroHeader extends StatelessWidget {
  const WorkoutHeroHeader({
    super.key,
    required this.title,
    required this.coverAsset,
    this.networkCoverUrl,
    this.subtitle,
    this.tags = const [],
  });

  final String title;
  final String coverAsset;
  final String? networkCoverUrl;
  final String? subtitle;
  final List<Widget> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkoutCoverImage(
          assetPath: coverAsset,
          networkUrl: networkCoverUrl,
          height: 180,
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 13, color: WorkoutTheme.textMuted, fontWeight: FontWeight.w600)),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: tags),
        ],
      ],
    );
  }
}
