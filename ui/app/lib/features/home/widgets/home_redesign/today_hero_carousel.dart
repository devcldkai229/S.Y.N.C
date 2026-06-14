import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/data/home_assets.dart';
import 'package:sync_app/features/home/data/home_display_helpers.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';
import 'package:video_player/video_player.dart';

class TodayHeroCarousel extends StatefulWidget {
  const TodayHeroCarousel({super.key, required this.data});

  final HomeDashboardData data;

  @override
  State<TodayHeroCarousel> createState() => _TodayHeroCarouselState();
}

class _TodayHeroCarouselState extends State<TodayHeroCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final duration = HomeDisplayHelpers.durationLabel(
      d.todaySessionMeta,
      d.todaySessionDurationMinutes,
    );
    final intensity = HomeDisplayHelpers.intensityLabel(d.sessionIntensityBars);
    final exerciseLabel = d.todaySessionExerciseCount > 0
        ? '${d.todaySessionExerciseCount} bài'
        : 'AI gợi ý';

    final slides = [
      _HeroSlide(
        kind: _HeroSlideKind.workout,
        eyebrow: 'Hôm nay',
        title: d.todaySessionTitle ?? 'Buổi tập hôm nay',
        chips: [duration, exerciseLabel, intensity],
        assetPath: HomeAssets.todayBg,
        fallbackAsset: HomeAssets.todayBgFallback,
        ctaLabel: 'Bắt đầu',
        onCta: () {
          final id = d.todaySessionId;
          if (id != null && id.isNotEmpty) {
            context.push(AppRoutes.customSessionDetail(id));
          } else {
            context.go(AppRoutes.workouts);
          }
        },
      ),
      _HeroSlide(
        kind: _HeroSlideKind.promo,
        eyebrow: 'SYNC Foods',
        title: 'Giao healthy trong 30 phút',
        chips: const ['Ưu đãi', 'Gần bạn'],
        assetPath: HomeAssets.marketplacePromo1,
        fallbackAsset: HomeAssets.bannerFallbackAlt,
        ctaLabel: 'Đặt ngay',
        onCta: () => context.go(AppRoutes.marketplaceHome),
      ),
      _HeroSlide(
        kind: _HeroSlideKind.tip,
        eyebrow: 'Mẹo hôm nay',
        title: d.recoveryHint ?? 'Giữ nhịp đều — mỗi buổi đều đếm!',
        chips: const ['SYNC Coach'],
        assetPath: HomeAssets.banner2Jpg,
        fallbackAsset: HomeAssets.banner2JpgFallback,
        ctaLabel: 'Xem lộ trình',
        onCta: () => context.go(AppRoutes.workouts),
      ),
    ];

    const height = 220.0;

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: slides.length,
          options: CarouselOptions(
            height: height,
            viewportFraction: 1,
            autoPlay: slides.length > 1,
            autoPlayInterval: const Duration(seconds: 6),
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          itemBuilder: (context, index, _) => _TodayHeroCard(slide: slides[index]),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index
                      ? HomeBentoColors.primaryGreen
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

enum _HeroSlideKind { workout, promo, tip }

class _HeroSlide {
  const _HeroSlide({
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.chips,
    required this.assetPath,
    required this.fallbackAsset,
    required this.ctaLabel,
    required this.onCta,
  });

  final _HeroSlideKind kind;
  final String eyebrow;
  final String title;
  final List<String> chips;
  final String assetPath;
  final String fallbackAsset;
  final String ctaLabel;
  final VoidCallback onCta;
}

class _TodayHeroCard extends StatefulWidget {
  const _TodayHeroCard({required this.slide});

  final _HeroSlide slide;

  @override
  State<_TodayHeroCard> createState() => _TodayHeroCardState();
}

class _TodayHeroCardState extends State<_TodayHeroCard> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroBackground(
            primary: widget.slide.assetPath,
            fallback: widget.slide.fallbackAsset,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: HomeBentoColors.limeChip,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.slide.eyebrow,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: HomeBentoColors.forestGreen,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.slide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.slide.chips
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.slide.onCta,
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeBentoColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.slide.ctaLabel,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatefulWidget {
  const _HeroBackground({required this.primary, required this.fallback});

  final String primary;
  final String fallback;

  @override
  State<_HeroBackground> createState() => _HeroBackgroundState();
}

class _HeroBackgroundState extends State<_HeroBackground> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _useFallback = false;

  bool get _isVideo => widget.primary.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(widget.primary);
    _controller = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) setState(() => _useFallback = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo && !_useFallback && _controller != null && _videoReady) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    final path = _useFallback || _isVideo ? widget.fallback : widget.primary;
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        widget.fallback,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HomeBentoColors.forestGreen, HomeBentoColors.primaryGreen],
            ),
          ),
        ),
      ),
    );
  }
}
