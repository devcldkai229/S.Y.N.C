import 'package:flutter/material.dart';

/// Temporary product flags while Sync Foods / Challenges have no real partners.
abstract final class FeatureTrialFlags {
  /// When true: show Sync Foods trial notice and block placing orders.
  static const syncFoodsOrderingDisabled = true;

  /// When true: show Challenges trial notice and block joining.
  static const challengesJoinDisabled = true;
}

/// Persistent amber info strip for demo / trial-phase features.
class FeatureTrialBanner extends StatelessWidget {
  const FeatureTrialBanner({
    super.key,
    required this.message,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  final String message;
  final EdgeInsetsGeometry margin;

  /// Sync Foods — dữ liệu demo, không phát sinh đơn thật.
  static const syncFoodsMessage =
      'Hiện tại Sync Foods đang trong giai đoạn thử nghiệm, dữ liệu hiện tại '
      'là không có thật nên sẽ không có bất kì đơn hàng nào xảy ra.';

  /// Thử thách cộng đồng — dữ liệu demo, chưa mở đăng ký thật.
  static const challengesMessage =
      'Hiện tại Thử thách cộng đồng đang trong giai đoạn thử nghiệm, dữ liệu '
      'hiện tại là không có thật nên sẽ không có bất kì đăng ký tham gia nào xảy ra.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB45309)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF78350F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
