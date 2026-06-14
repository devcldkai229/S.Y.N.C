import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_exercise_thumbnail.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_helpers.dart';
import 'package:sync_app/features/workouts/widgets/exercise_detail/catalog_muscle_map.dart';
import 'package:video_player/video_player.dart';

class ExerciseDetailContent extends StatelessWidget {
  const ExerciseDetailContent({
    super.key,
    required this.detail,
    required this.inlineController,
    required this.inlineReady,
    required this.onFullscreen,
  });

  final ExerciseCatalogDetail detail;
  final VideoPlayerController? inlineController;
  final bool inlineReady;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        _HeroDemoHeader(
          detail: detail,
          controller: inlineController,
          ready: inlineReady,
          onFullscreen: onFullscreen,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.nameVi.isNotEmpty ? detail.nameVi : detail.nameEn,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: ExerciseCatalogTheme.slateDark,
                    height: 1.1,
                  ),
                ),
                if (detail.nameEn.isNotEmpty && detail.nameVi.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail.nameEn,
                    style: const TextStyle(fontSize: 15, color: ExerciseCatalogTheme.slateMuted),
                  ),
                ],
                const SizedBox(height: 14),
                _QuickTags(detail: detail),
                const SizedBox(height: 20),
                _MetricsGrid(detail: detail),
                const SizedBox(height: 20),
                CatalogMuscleMap(
                  primaryMuscles: detail.primaryMuscles,
                  secondaryMuscles: detail.secondaryMuscles,
                ),
                const SizedBox(height: 16),
                _EquipmentSection(equipment: detail.equipmentRequired),
                if (detail.aiCoachingCues.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Hướng dẫn thực hiện',
                    child: Column(
                      children: [
                        for (var i = 0; i < detail.aiCoachingCues.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: i == detail.aiCoachingCues.length - 1 ? 0 : 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: ExerciseCatalogTheme.syncLime,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: ExerciseCatalogTheme.slateDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    detail.aiCoachingCues[i],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: ExerciseCatalogTheme.slateDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (detail.commonMistakes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Lỗi thường gặp',
                    child: Column(
                      children: detail.commonMistakes
                          .map(
                            (m) => _WarningRow(
                              text: m,
                              icon: Icons.warning_amber_rounded,
                              color: ExerciseCatalogTheme.intermediateAmber,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (_hasSafetyNotes(detail)) ...[
                  const SizedBox(height: 16),
                  _SafetySection(detail: detail),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _hasSafetyNotes(ExerciseCatalogDetail d) =>
      d.requiresSpotter || d.contraindications.isNotEmpty;
}

class ExerciseDetailBottomBar extends StatelessWidget {
  const ExerciseDetailBottomBar({
    super.key,
    required this.onAddToWorkout,
    required this.onTryPractice,
  });

  final VoidCallback onAddToWorkout;
  final VoidCallback onTryPractice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ExerciseCatalogTheme.offWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTryPractice,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ExerciseCatalogTheme.slateDark,
                    side: const BorderSide(color: ExerciseCatalogTheme.borderSoft),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Tập thử', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onAddToWorkout,
                  style: FilledButton.styleFrom(
                    backgroundColor: ExerciseCatalogTheme.syncLime,
                    foregroundColor: ExerciseCatalogTheme.slateDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Thêm vào workout', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroDemoHeader extends StatefulWidget {
  const _HeroDemoHeader({
    required this.detail,
    required this.controller,
    required this.ready,
    required this.onFullscreen,
  });

  final ExerciseCatalogDetail detail;
  final VideoPlayerController? controller;
  final bool ready;
  final VoidCallback onFullscreen;

  @override
  State<_HeroDemoHeader> createState() => _HeroDemoHeaderState();
}

class _HeroDemoHeaderState extends State<_HeroDemoHeader> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final hasVideo = detail.videoAssets.isNotEmpty && widget.controller != null && widget.ready;
    final imageUrls = detail.imageUrls;
    final exerciseName = detail.nameVi.isNotEmpty ? detail.nameVi : detail.nameEn;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: ExerciseCatalogTheme.slateDark,
      foregroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const BackButton(color: Colors.white),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
              onPressed: widget.onFullscreen,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasVideo)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: widget.controller!.value.size.width,
                  height: widget.controller!.value.size.height,
                  child: VideoPlayer(widget.controller!),
                ),
              )
            else if (imageUrls.length > 1)
              PageView.builder(
                controller: _pageController,
                itemCount: imageUrls.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) => CatalogExerciseThumbnail(
                  networkUrl: imageUrls[index],
                  exerciseName: exerciseName,
                  fill: true,
                  borderRadius: 0,
                ),
              )
            else
              Positioned.fill(
                child: CatalogExerciseThumbnail(
                  networkUrl: detail.heroThumbnailUrl,
                  exerciseName: exerciseName,
                  fill: true,
                  borderRadius: 0,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            if (!hasVideo && imageUrls.length > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imageUrls.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _pageIndex == index ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _pageIndex == index
                            ? ExerciseCatalogTheme.syncLime
                            : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickTags extends StatelessWidget {
  const _QuickTags({required this.detail});

  final ExerciseCatalogDetail detail;

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      if (detail.category.isNotEmpty) detail.category,
      if (detail.difficulty.isNotEmpty) CatalogHelpers.difficultyLabel(detail.difficulty),
      '${detail.metValue.toStringAsFixed(1)} MET',
      '~${detail.estimatedCaloriesPerMinute} cal/phút',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ExerciseCatalogTheme.syncLime.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ExerciseCatalogTheme.syncLime.withValues(alpha: 0.55)),
              ),
              child: Text(
                t,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ExerciseCatalogTheme.slateDark,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.detail});

  final ExerciseCatalogDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Calo',
            value: '~${detail.estimatedCaloriesPerMinute}',
            unit: '/phút',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'Nghỉ',
            value: '${detail.recommendedRestSeconds}',
            unit: 's',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'MET',
            value: detail.metValue.toStringAsFixed(1),
            unit: '',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: ExerciseCatalogTheme.frostedCard(radius: 14),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: ExerciseCatalogTheme.slateMuted)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: ExerciseCatalogTheme.slateDark,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: const TextStyle(fontSize: 11, color: ExerciseCatalogTheme.slateMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentSection extends StatelessWidget {
  const _EquipmentSection({required this.equipment});

  final List<String> equipment;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Dụng cụ',
      child: equipment.isEmpty
          ? const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 20, color: ExerciseCatalogTheme.beginnerGreen),
                SizedBox(width: 8),
                Text('Không cần dụng cụ', style: TextStyle(color: ExerciseCatalogTheme.slateMuted)),
              ],
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: equipment
                  .map(
                    (e) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center_rounded, size: 18, color: ExerciseCatalogTheme.slateMuted),
                        const SizedBox(width: 6),
                        Text(e, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SafetySection extends StatelessWidget {
  const _SafetySection({required this.detail});

  final ExerciseCatalogDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ExerciseCatalogTheme.intermediateAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ExerciseCatalogTheme.intermediateAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: ExerciseCatalogTheme.intermediateAmber, size: 20),
              SizedBox(width: 8),
              Text('An toàn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          if (detail.requiresSpotter) ...[
            const SizedBox(height: 10),
            const Text('Cần người hỗ trợ (spotter) khi tập.', style: TextStyle(height: 1.4)),
          ],
          if (detail.contraindications.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...detail.contraindications.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: ExerciseCatalogTheme.intermediateAmber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c, style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ExerciseCatalogTheme.frostedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: ExerciseCatalogTheme.slateDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.text, required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
