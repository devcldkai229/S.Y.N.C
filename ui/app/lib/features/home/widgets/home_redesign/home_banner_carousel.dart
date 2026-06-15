import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/home/data/home_assets.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';
import 'package:video_player/video_player.dart';

class HomeBannerSlide {
  const HomeBannerSlide({
    required this.assetPath,
    required this.fallbackPath,
    this.title,
    this.route,
  });

  final String assetPath;
  final String fallbackPath;
  final String? title;
  final String? route;

  bool get isVideo => assetPath.toLowerCase().endsWith('.mp4');
}

abstract final class HomeBannerSlides {
  static const items = [
    HomeBannerSlide(
      assetPath: HomeAssets.bannerNguoiSongVuiVe,
      fallbackPath: HomeAssets.bannerFallback,
      route: AppRoutes.challengesMap,
    ),
    HomeBannerSlide(
      assetPath: HomeAssets.bannerTieuHoaNhanh,
      fallbackPath: HomeAssets.bannerFallback,
      route: AppRoutes.marketplaceHome,
    ),
    HomeBannerSlide(
      assetPath: HomeAssets.bannerThuocGym,
      fallbackPath: HomeAssets.bannerFallback,
      route: AppRoutes.marketplaceHome,
    ),
  ];
}

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final slides = HomeBannerSlides.items;
    const aspect = 16 / 9;
    final width = MediaQuery.sizeOf(context).width - 32;
    final height = width / aspect;

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: slides.length,
          options: CarouselOptions(
            height: height,
            viewportFraction: 1,
            autoPlay: slides.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          itemBuilder: (context, index, _) {
            final slide = slides[index];
            return GestureDetector(
              onTap: () {
                final route = slide.route;
                if (route != null) context.push(route);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _BannerMedia(slide: slide),
              ),
            );
          },
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 8),
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

class _BannerMedia extends StatefulWidget {
  const _BannerMedia({required this.slide});

  final HomeBannerSlide slide;

  @override
  State<_BannerMedia> createState() => _BannerMediaState();
}

class _BannerMediaState extends State<_BannerMedia> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.slide.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(widget.slide.assetPath);
    _controller = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (slide.isVideo && !_failed && _controller != null && _ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          Image.asset(
            _failed || slide.isVideo ? slide.fallbackPath : slide.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              HomeAssets.bannerFallbackAlt,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientFallback(slide.title),
            ),
          ),
        if (slide.title != null)
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                slide.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _gradientFallback(String? title) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [HomeBentoColors.forestGreen, HomeBentoColors.primaryGreen],
        ),
      ),
      child: Text(
        title ?? 'SYNC',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
