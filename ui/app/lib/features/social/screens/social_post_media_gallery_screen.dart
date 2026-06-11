import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';
import 'package:sync_app/features/social/utils/social_media_utils.dart';

class SocialPostMediaGalleryScreen extends StatefulWidget {
  const SocialPostMediaGalleryScreen({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<SocialPostMediaGalleryScreen> createState() => _SocialPostMediaGalleryScreenState();
}

class _SocialPostMediaGalleryScreenState extends State<SocialPostMediaGalleryScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    final safe = widget.urls.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.urls.length - 1);
    _index = safe;
    _controller = PageController(initialPage: safe);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.urls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Media'),
        actions: [
          if (count > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_index + 1}/$count',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: count == 0
          ? const Center(child: Text('Không có media', style: TextStyle(color: Colors.white70)))
          : PageView.builder(
              controller: _controller,
              itemCount: count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = widget.urls[i];
                if (SocialMediaUtils.isVideoUrl(url)) {
                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SocialVideoPlayerScreen(videoUrl: url),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                          ),
                          const SizedBox(height: 12),
                          const Text('Nhấn để phát video', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  );
                }

                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 48),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
