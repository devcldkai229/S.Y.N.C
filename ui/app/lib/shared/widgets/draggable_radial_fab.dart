import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';

/// A quick-action entry shown when the radial FAB is expanded.
class RadialFabMenuItem {
  const RadialFabMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Docked center FAB (half-submerged in bottom nav) with radial quick-action menu.
class DraggableRadialFab extends StatefulWidget {
  const DraggableRadialFab({
    super.key,
    required this.items,
    this.fabSize = 64,
    this.itemSize = 56,
    this.arcRadius = 135,
  });

  final List<RadialFabMenuItem> items;
  final double fabSize;
  final double itemSize;
  final double arcRadius;

  @override
  State<DraggableRadialFab> createState() => _DraggableRadialFabState();
}

class _DraggableRadialFabState extends State<DraggableRadialFab>
    with TickerProviderStateMixin {
  static const double _navBarHeight = 72;
  static const double _labelWidth = 76;
  /// Lifts the whole arc above the nav bar top edge (circle + label clearance).
  static const double _arcLift = 58;

  static const Duration _openDuration = Duration(milliseconds: 220);
  static const Duration _closeDuration = Duration(milliseconds: 150);
  static const Duration _overlayOpenDuration = Duration(milliseconds: 200);
  static const Duration _overlayCloseDuration = Duration(milliseconds: 150);
  static const Duration _staggerDelay = Duration(milliseconds: 40);

  late final AnimationController _expandController;
  late final AnimationController _overlayController;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: _openDuration,
    );
    _overlayController = AnimationController(
      vsync: this,
      duration: _overlayOpenDuration,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  double _navBarTopFromBottom(EdgeInsets padding) =>
      padding.bottom + _navBarHeight;

  Offset _fabCenter(Size screenSize, EdgeInsets padding) {
    return Offset(
      screenSize.width / 2,
      screenSize.height - _navBarTopFromBottom(padding),
    );
  }

  /// Perfect top half-circle: π (far left) → 0 (far right).
  List<double> _itemAngles(int count) {
    if (count <= 0) return const [];
    if (count == 1) return [math.pi / 2];

    return List<double>.generate(
      count,
      (index) => math.pi - ((math.pi / (count - 1)) * index),
    );
  }

  Offset _polarOffset(double angle, double radius) {
    final dx = radius * math.cos(angle);
    final dy = -radius * math.sin(angle);
    return Offset(dx, dy);
  }

  Future<void> _open() async {
    setState(() => _isOpen = true);
    _expandController.duration = _openDuration;
    _overlayController.duration = _overlayOpenDuration;
    await Future.wait([
      _expandController.forward(),
      _overlayController.forward(),
    ]);
  }

  Future<void> _close() async {
    _expandController.duration = _closeDuration;
    _overlayController.duration = _overlayCloseDuration;
    await Future.wait([
      _expandController.reverse(),
      _overlayController.reverse(),
    ]);
    if (mounted) setState(() => _isOpen = false);
    _expandController.duration = _openDuration;
    _overlayController.duration = _overlayOpenDuration;
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  Future<void> _onItemTap(RadialFabMenuItem item) async {
    await _close();
    // Let pointer/mouse tracker settle before route swap (web/desktop).
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    item.onTap();
  }

  double _itemAnimValue(int index) {
    final stagger =
        index * _staggerDelay.inMilliseconds / _openDuration.inMilliseconds;
    final start = stagger.clamp(0.0, 0.6);
    final end = (start + 0.8).clamp(0.0, 1.0);
    final t = _expandController.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return Curves.easeOutBack.transform((t - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final padding = media.padding;
    final navTopFromBottom = _navBarTopFromBottom(padding);
    final center = _fabCenter(screenSize, padding);
    final angles = _itemAngles(widget.items.length);
    final fabRadius = widget.fabSize / 2;

    return AnimatedBuilder(
      animation: Listenable.merge([_expandController, _overlayController]),
      builder: (context, _) {
        final showOverlay = _isOpen || _overlayController.value > 0.001;
        final showArc = _isOpen || _expandController.value > 0.001;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (showOverlay)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: navTopFromBottom,
                child: IgnorePointer(
                  ignoring: !_isOpen,
                  child: GestureDetector(
                    onTap: _isOpen ? _close : null,
                    behavior: HitTestBehavior.opaque,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _overlayController,
                        curve: Curves.easeOut,
                        reverseCurve: Curves.easeIn,
                      ),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            if (showArc)
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(0, -_arcLift),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(widget.items.length, (index) {
                      final angle = angles[index];
                      final a = _itemAnimValue(index);
                      if (a < 0.05) return const SizedBox.shrink();

                      final o = _polarOffset(angle, widget.arcRadius * a);
                      return Positioned(
                        left: center.dx + o.dx - _labelWidth / 2,
                        top: center.dy + o.dy - widget.itemSize / 2,
                        child: Opacity(
                          opacity: a.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: a,
                            child: _FabMenuItemButton(
                              item: widget.items[index],
                              size: widget.itemSize,
                              onTap: () => _onItemTap(widget.items[index]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            Positioned(
              left: center.dx - fabRadius,
              bottom: navTopFromBottom - fabRadius,
              child: GestureDetector(
                onTap: _toggle,
                child: _DockedFabButton(
                  size: widget.fabSize,
                  isOpen: _isOpen,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DockedFabButton extends StatelessWidget {
  const _DockedFabButton({
    required this.size,
    required this.isOpen,
  });

  final double size;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}

class _FabMenuItemButton extends StatelessWidget {
  const _FabMenuItemButton({
    required this.item,
    required this.size,
    required this.onTap,
  });

  final RadialFabMenuItem item;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.38),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 76,
            child: RichText(
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.54),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
