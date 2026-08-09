import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/data/home_assets.dart';
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
    final hasCustom = d.featuredCustomWorkoutId != null &&
        d.featuredCustomWorkoutId!.isNotEmpty;

    final slides = [
      // Banner 1 — Lộ trình cá nhân hóa (full promo art)
      _HeroSlide(
        kind: _HeroSlideKind.workout,
        eyebrow: 'Lộ trình AI',
        title: d.hasActiveRoadmap
            ? [
                if (d.phaseLabel != null) d.phaseLabel!,
                if (d.weekLabel != null) d.weekLabel!,
                if (d.goalLabel != null) d.goalLabel!,
              ].where((e) => e.isNotEmpty).join(' · ').ifEmpty('Lộ trình AI của bạn')
            : 'Tạo lộ trình AI ngay!',
        chips: d.hasActiveRoadmap
            ? [
                if (d.phaseLabel != null) d.phaseLabel!,
                if (d.weekLabel != null) d.weekLabel!,
              ]
            : const ['AI Coach', 'Cá nhân hóa'],
        assetPath: HomeAssets.bannerProgressPerform,
        fallbackAsset: HomeAssets.todayBgFallback,
        ctaLabel: d.hasActiveRoadmap ? 'Xem lộ trình AI' : 'Bắt đầu ngay',
        onCta: () => context.go(AppRoutes.workouts),
        imageOnly: true,
      ),
      // Banner 2 — Sync Food → Marketplace
      _HeroSlide(
        kind: _HeroSlideKind.promo,
        eyebrow: 'SYNC Foods',
        title: 'Muốn healthy? Gọi Sync Food ngay!',
        chips: const ['Đặt ngay', 'Giao nhanh'],
        assetPath: HomeAssets.marketplacePromo1,
        fallbackAsset: HomeAssets.bannerFallbackAlt,
        ctaLabel: 'Đặt ngay',
        onCta: () => context.go(AppRoutes.marketplaceHome),
      ),
      // Banner 3 — UserCustomWorkout hoặc CYN AI intro
      if (hasCustom)
        _HeroSlide(
          kind: _HeroSlideKind.workout,
          eyebrow: 'Lộ trình của bạn',
          title: d.featuredCustomWorkoutName ?? 'Custom Workout',
          chips: const ['User Custom', 'Tập ngay'],
          assetPath: HomeAssets.todayBgFallback,
          fallbackAsset: HomeAssets.todayBgFallback,
          networkImageUrl: d.featuredCustomWorkoutCoverUrl,
          ctaLabel: 'Xem workout',
          onCta: () => context.push(
            AppRoutes.customWorkoutDetail(d.featuredCustomWorkoutId!),
          ),
        )
      else
        _HeroSlide(
          kind: _HeroSlideKind.tip,
          eyebrow: 'CYN AI',
          title: 'Sợ lộ trình không hiệu quả? Gọi CYN AI ngay!',
          chips: const ['Chatbot', 'Tư vấn AI'],
          assetPath: HomeAssets.bannerCynAiIntro,
          fallbackAsset: HomeAssets.banner2JpgFallback,
          ctaLabel: 'Chat với CYN',
          onCta: () => context.push(AppRoutes.cynChat),
          imageOnly: true,
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
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
    this.networkImageUrl,
    this.imageOnly = false,
  });

  final _HeroSlideKind kind;
  final String eyebrow;
  final String title;
  final List<String> chips;
  final String assetPath;
  final String fallbackAsset;
  final String? networkImageUrl;
  final String ctaLabel;
  final VoidCallback onCta;

  /// When true, the asset is a complete promo design — show full-bleed image only.
  final bool imageOnly;
}

class _TodayHeroCard extends StatelessWidget {
  const _TodayHeroCard({required this.slide});

  final _HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    if (slide.imageOnly) {
      return GestureDetector(
        onTap: slide.onCta,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _HeroBackground(
            primary: slide.assetPath,
            fallback: slide.fallbackAsset,
            networkImageUrl: slide.networkImageUrl,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroBackground(
            primary: slide.assetPath,
            fallback: slide.fallbackAsset,
            networkImageUrl: slide.networkImageUrl,
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
                    slide.eyebrow,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: HomeBentoColors.forestGreen,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  slide.title,
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
                  children: slide.chips
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
                    onPressed: slide.onCta,
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeBentoColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      slide.ctaLabel,
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
  const _HeroBackground({
    required this.primary,
    required this.fallback,
    this.networkImageUrl,
  });

  final String primary;
  final String fallback;
  final String? networkImageUrl;

  @override
  State<_HeroBackground> createState() => _HeroBackgroundState();
}

class _HeroBackgroundState extends State<_HeroBackground> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _useFallback = false;

  bool get _isVideo => widget.primary.toLowerCase().endsWith('.mp4');

  String? get _resolvedNetworkUrl {
    final raw = widget.networkImageUrl;
    if (raw == null || raw.isEmpty) return null;
    return MediaUrlResolver.resolve(raw) ?? raw;
  }

  @override
  void initState() {
    super.initState();
    if (_resolvedNetworkUrl == null && _isVideo) _initVideo();
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
    final networkUrl = _resolvedNetworkUrl;
    if (networkUrl != null) {
      return CachedNetworkImage(
        imageUrl: networkUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Image.asset(
          widget.fallback,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gradientFallback(),
        ),
      );
    }

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
        errorBuilder: (_, __, ___) => _gradientFallback(),
      ),
    );
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeBentoColors.forestGreen, HomeBentoColors.primaryGreen],
        ),
      ),
    );
  }
}
