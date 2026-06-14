import 'package:flutter/material.dart';

/// Simple skeleton placeholder (no extra shimmer package).
class SyncShimmerBox extends StatefulWidget {
  const SyncShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 12,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  State<SyncShimmerBox> createState() => _SyncShimmerBoxState();
}

class _SyncShimmerBoxState extends State<SyncShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: const [
                Color(0xFFE8EEE4),
                Color(0xFFF4F8F2),
                Color(0xFFE8EEE4),
              ],
            ),
          ),
        );
      },
    );
  }
}
