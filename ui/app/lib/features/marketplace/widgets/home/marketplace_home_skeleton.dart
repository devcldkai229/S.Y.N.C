import 'package:flutter/material.dart';

class MarketplaceHomeSkeleton extends StatelessWidget {
  const MarketplaceHomeSkeleton({super.key});

  static const _placeholder = Color(0xFFE2EAE4);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 36, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SkeletonBox(height: 88, borderRadius: 16),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 96,
            child: Row(
              children: [
                SizedBox(width: 16),
                _SkeletonBox(height: 72, width: 72, borderRadius: 36),
                SizedBox(width: 14),
                _SkeletonBox(height: 72, width: 72, borderRadius: 36),
                SizedBox(width: 14),
                _SkeletonBox(height: 72, width: 72, borderRadius: 36),
                SizedBox(width: 14),
                _SkeletonBox(height: 72, width: 72, borderRadius: 36),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 118,
            child: Row(
              children: [
                SizedBox(width: 16),
                _SkeletonBox(height: 118, width: 156, borderRadius: 16),
                SizedBox(width: 12),
                _SkeletonBox(height: 118, width: 156, borderRadius: 16),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SkeletonBox(height: 20, width: 160),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 228,
            child: Row(
              children: [
                SizedBox(width: 16),
                _SkeletonBox(height: 228, width: 168, borderRadius: 18),
                SizedBox(width: 12),
                _SkeletonBox(height: 228, width: 168, borderRadius: 18),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SkeletonBox(height: 20, width: 140),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SkeletonBox(height: 220, borderRadius: 18),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SkeletonBox(height: 220, borderRadius: 18),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: MarketplaceHomeSkeleton._placeholder,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
