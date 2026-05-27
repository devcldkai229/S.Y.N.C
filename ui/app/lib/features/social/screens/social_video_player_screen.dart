import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

class SocialVideoPlayerScreen extends StatefulWidget {
  const SocialVideoPlayerScreen({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<SocialVideoPlayerScreen> createState() => _SocialVideoPlayerScreenState();
}

class _SocialVideoPlayerScreenState extends State<SocialVideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.play();
      }).catchError((Object e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Workout Video'),
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.white70)),
              )
            : !_initialized
                ? const CircularProgressIndicator(color: AppColors.primaryGreen)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _initialized
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryGreen,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
