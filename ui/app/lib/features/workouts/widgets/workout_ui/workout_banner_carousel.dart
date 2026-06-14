import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/utils/workout_assets.dart';
import 'package:video_player/video_player.dart';

class WorkoutBannerSlide {
  const WorkoutBannerSlide({this.assetPath, this.networkImageUrl});

  final String? assetPath;
  final String? networkImageUrl;

  bool get isVideo => assetPath != null && assetPath!.toLowerCase().endsWith('.mp4');
}

abstract final class WorkoutBannerSlides {
  static const items = [
    WorkoutBannerSlide(assetPath: WorkoutAssets.banner3Jpg),
    WorkoutBannerSlide(assetPath: WorkoutAssets.banner2Mp4),
    WorkoutBannerSlide(assetPath: WorkoutAssets.banner1Mp4),
  ];
}

/// Landscape 16:9 banner carousel (mp4 or image) for merged Workouts tab.
class WorkoutBannerCarousel extends StatefulWidget {
  const WorkoutBannerCarousel({super.key});

  @override
  State<WorkoutBannerCarousel> createState() => _WorkoutBannerCarouselState();
}

class _WorkoutBannerCarouselState extends State<WorkoutBannerCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 40;
    final height = width * 9 / 16;
    final slides = WorkoutBannerSlides.items;

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: slides.length,
          options: CarouselOptions(
            height: height,
            viewportFraction: 1,
            enlargeCenterPage: false,
            autoPlay: slides.length > 1,
            autoPlayInterval: const Duration(seconds: 6),
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          itemBuilder: (context, index, _) => _SlideCard(slide: slides[index], height: height),
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
                width: i == _index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? WorkoutTheme.lime : WorkoutTheme.border,
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

class _SlideCard extends StatefulWidget {
  const _SlideCard({required this.slide, required this.height});

  final WorkoutBannerSlide slide;
  final double height;

  @override
  State<_SlideCard> createState() => _SlideCardState();
}

class _SlideCardState extends State<_SlideCard> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final slide = widget.slide;
    if (!slide.isVideo || slide.assetPath == null) return;
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final slide = widget.slide;
    if (slide.isVideo && _controller != null && _ready) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    if (slide.assetPath != null && !slide.isVideo) {
      return Image.asset(slide.assetPath!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback());
    }
    if (slide.networkImageUrl != null) {
      return CachedNetworkImage(imageUrl: slide.networkImageUrl!, fit: BoxFit.cover, errorWidget: (_, _, _) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() {
    return Image.asset(
      WorkoutAssets.bannerFallback,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(color: WorkoutTheme.lime.withValues(alpha: 0.35)),
    );
  }
}
