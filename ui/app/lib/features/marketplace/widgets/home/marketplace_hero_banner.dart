import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/widgets/marketplace_asset_image.dart';

class MarketplaceHeroBanner extends StatefulWidget {
  const MarketplaceHeroBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<MarketplaceHeroBanner> createState() => _MarketplaceHeroBannerState();
}

class _MarketplaceHeroBannerState extends State<MarketplaceHeroBanner> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.asset(MarketplaceCatalog.heroVideo);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 168,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video != null && video.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: video.value.size.width,
                    height: video.value.size.height,
                    child: VideoPlayer(video),
                  ),
                )
              else
                MarketplaceAssetImage(
                  assetPath: MarketplaceCatalog.heroFallback,
                  fit: BoxFit.cover,
                  label: 'SYNC Foods',
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 16,
                bottom: 14,
                child: Text(
                  'Ăn healthy, giao nhanh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
