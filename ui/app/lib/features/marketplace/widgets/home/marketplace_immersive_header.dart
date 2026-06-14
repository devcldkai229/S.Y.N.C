import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_home_cubit.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_wave_clipper.dart';
import 'package:sync_app/shared/widgets/notification_bell_button.dart';

class MarketplaceImmersiveHeader extends StatelessWidget {
  const MarketplaceImmersiveHeader({
    super.key,
    required this.locationStatus,
    required this.deliveryLabel,
    required this.onLocationTap,
    required this.onSearchTap,
    this.cartItemCount = 0,
    this.onCartTap,
  });

  final MarketplaceLocationStatus locationStatus;
  final String deliveryLabel;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;
  final int cartItemCount;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    const waveHeight = 132.0;
    const searchOverlap = 20.0;

    return Material(
      color: MarketplaceTheme.background,
      child: SizedBox(
        height: waveHeight + topPad + searchOverlap + 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: MarketplaceWaveClipper(),
                child: Container(
                  height: waveHeight + topPad,
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: MarketplaceTheme.headerGradient),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, topPad + 4, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go(AppRoutes.home),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              tooltip: 'Quay lại',
                            ),
                            const Spacer(),
                            if (cartItemCount > 0 && onCartTap != null)
                              _CartHeaderButton(count: cartItemCount, onTap: onCartTap!),
                            const NotificationBellButton(
                              iconColor: Colors.white,
                              iconSize: 22,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onLocationTap,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'GIAO ĐẾN',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white.withValues(alpha: 0.85),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          size: 18,
                                        ),
                                        if (locationStatus == MarketplaceLocationStatus.resolving) ...[
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      deliveryLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    decoration: MarketplaceTheme.searchDecoration(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: MarketplaceTheme.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hôm nay ăn gì healthy? 🥗',
                            style: TextStyle(
                              fontSize: 15,
                              color: MarketplaceTheme.textMuted.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartHeaderButton extends StatelessWidget {
  const _CartHeaderButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Giỏ hàng',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_bag_outlined, color: Colors.white),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: MarketplaceTheme.limeChip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: MarketplaceTheme.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
