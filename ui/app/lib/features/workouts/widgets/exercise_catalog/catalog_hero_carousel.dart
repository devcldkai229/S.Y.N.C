import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/catalog_assets.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';
import 'package:video_player/video_player.dart';

class CatalogBannerSlide {
  const CatalogBannerSlide({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.assetPath,
    this.networkImageUrl,
    this.networkVideoUrl,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? assetPath;
  final String? networkImageUrl;
  final String? networkVideoUrl;

  bool get isAssetVideo => assetPath != null && assetPath!.toLowerCase().endsWith('.mp4');
}

abstract final class CatalogBannerSlides {
  static List<CatalogBannerSlide> get assetSlides => [
    CatalogBannerSlide(
      eyebrow: 'SYNC TRAINING',
      title: 'Chinh phục sức mạnh',
      subtitle: 'Chương trình tuần này dành cho bạn',
      assetPath: CatalogAssets.banner1CatalogMp4,
    ),
    CatalogBannerSlide(
      eyebrow: 'CARDIO',
      title: 'Đốt mỡ nhanh chóng',
      subtitle: 'MET tối ưu cho mục tiêu của bạn',
      assetPath: CatalogAssets.banner2CatalogMp4,
    ),
    CatalogBannerSlide(
      eyebrow: 'RECOVERY',
      title: 'Cân chỉnh & Phục hồi',
      subtitle: 'Tập bền, ít chấn thương',
      assetPath: CatalogAssets.banner3CatalogMp4,
    ),
  ];

  static List<CatalogBannerSlide> get all => assetSlides;
}

class CatalogHeroCarousel extends StatefulWidget {
  const CatalogHeroCarousel({super.key, this.slides});

  final List<CatalogBannerSlide>? slides;

  @override
  State<CatalogHeroCarousel> createState() => _CatalogHeroCarouselState();
}

class _CatalogHeroCarouselState extends State<CatalogHeroCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides ?? CatalogBannerSlides.all;
    if (slides.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          CatalogAssets.bannerFallback,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: ExerciseCatalogTheme.syncLime.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: slides.length,
          options: CarouselOptions(
            height: 200,
            viewportFraction: 0.94,
            enlargeCenterPage: true,
            enlargeFactor: 0.1,
            autoPlay: slides.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          itemBuilder: (context, index, _) => _BannerSlideCard(slide: slides[index]),
        ),
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
                color: i == _index ? ExerciseCatalogTheme.syncLime : ExerciseCatalogTheme.borderSoft,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerSlideCard extends StatefulWidget {
  const _BannerSlideCard({required this.slide});

  final CatalogBannerSlide slide;

  @override
  State<_BannerSlideCard> createState() => _BannerSlideCardState();
}

class _BannerSlideCardState extends State<_BannerSlideCard> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final slide = widget.slide;
    if (slide.isAssetVideo && slide.assetPath != null) {
      final c = VideoPlayerController.asset(slide.assetPath!);
      _controller = c;
      try {
        await c.initialize();
        await c.setLooping(true);
        await c.setVolume(0);
        await c.play();
        if (mounted) setState(() => _ready = true);
      } catch (_) {
        if (mounted) setState(() => _ready = false);
      }
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildMedia(slide),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.78)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ExerciseCatalogTheme.syncLime,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    slide.eyebrow,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ExerciseCatalogTheme.slateDark),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                ),
                if (slide.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    slide.subtitle!,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.88)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(CatalogBannerSlide slide) {
    if (slide.isAssetVideo && _controller != null && _ready) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    if (slide.assetPath != null && !slide.isAssetVideo) {
      return Image.asset(
        slide.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(slide),
      );
    }
    if (slide.networkImageUrl != null) {
      return CachedNetworkImage(
        imageUrl: slide.networkImageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackImage(slide),
      );
    }
    return _fallbackImage(slide);
  }

  Widget _fallbackImage(CatalogBannerSlide slide) {
    return Image.asset(
      CatalogAssets.bannerFallback,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(color: ExerciseCatalogTheme.slateDark.withValues(alpha: 0.25)),
    );
  }
}
