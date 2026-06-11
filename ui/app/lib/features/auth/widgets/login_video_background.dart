import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen looping muted video background for the login screen.
class LoginVideoBackground extends StatefulWidget {
  const LoginVideoBackground({
    super.key,
    this.assetPath = 'assets/background_login.mp4',
  });

  final String assetPath;

  @override
  State<LoginVideoBackground> createState() => _LoginVideoBackgroundState();
}

class _LoginVideoBackgroundState extends State<LoginVideoBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      await controller.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _LoginGradientFallback(),
        if (_ready && _controller != null)
          _CoverVideo(controller: _controller!),
        const _LoginScrim(),
      ],
    );
  }
}

class _CoverVideo extends StatelessWidget {
  const _CoverVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    if (size.width == 0 || size.height == 0) {
      return const SizedBox.expand();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _LoginGradientFallback extends StatelessWidget {
  const _LoginGradientFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2918),
            Color(0xFF1A3D24),
            Color(0xFF0D1F14),
          ],
        ),
      ),
    );
  }
}

class _LoginScrim extends StatelessWidget {
  const _LoginScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
    );
  }
}
