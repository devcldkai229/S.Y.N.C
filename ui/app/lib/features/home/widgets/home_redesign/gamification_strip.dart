import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class GamificationStrip extends StatelessWidget {
  const GamificationStrip({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final level = data.currentLevel;
    final streak = data.currentStreak;
    final coins = data.syncCoins.round();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _StripPill(
            onTap: () => context.push(AppRoutes.achievements),
            child: Row(
              children: [
                _XpRing(progress: data.xpProgress),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cấp $level',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: HomeBentoColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${data.xpInLevel} XP',
                      style: const TextStyle(
                        fontSize: 11,
                        color: HomeBentoColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StripPill(
          onTap: () => context.push(AppRoutes.achievements),
          child: _AnimatedStreak(streak: streak),
        ),
        const SizedBox(width: 8),
        _StripPill(
          onTap: () => context.push(AppRoutes.shop),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: HomeBentoColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StripPill extends StatelessWidget {
  const _StripPill({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeBentoColors.card,
      borderRadius: BorderRadius.circular(999),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _XpRing extends StatelessWidget {
  const _XpRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 3.5,
                backgroundColor: const Color(0xFFE5E7EB),
                color: HomeBentoColors.primaryGreen,
              ),
              const Icon(
                Icons.military_tech_rounded,
                size: 14,
                color: HomeBentoColors.primaryGreen,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedStreak extends StatefulWidget {
  const _AnimatedStreak({required this.streak});

  final int streak;

  @override
  State<_AnimatedStreak> createState() => _AnimatedStreakState();
}

class _AnimatedStreakState extends State<_AnimatedStreak>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: widget.streak > 0 ? _scale : const AlwaysStoppedAnimation(1),
          child: const Text('🔥', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.streak}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: HomeBentoColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
