import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';

class SocialFeedSkeletonList extends StatelessWidget {
  const SocialFeedSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const SocialFeedPostSkeleton(),
    );
  }
}

class SocialFeedPostSkeleton extends StatefulWidget {
  const SocialFeedPostSkeleton({super.key});

  @override
  State<SocialFeedPostSkeleton> createState() => _SocialFeedPostSkeletonState();
}

class _SocialFeedPostSkeletonState extends State<SocialFeedPostSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
        return Opacity(opacity: 0.45 + _controller.value * 0.55, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(44, 44, radius: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(double.infinity, 14),
                      const SizedBox(height: 8),
                      _box(120, 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _box(double.infinity, 14),
            const SizedBox(height: 6),
            _box(double.infinity, 14),
            const SizedBox(height: 10),
            _box(double.infinity, 180, radius: 8),
          ],
        ),
      ),
    );
  }

  Widget _box(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
