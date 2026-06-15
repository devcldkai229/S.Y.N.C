import 'package:sync_app/features/order/utils/tracking_status_mapper.dart';

abstract final class OrderDisplayStatus {
  static String code({
    required String orderStatus,
    String? deliveryStatus,
  }) =>
      TrackingStatusMapper.displayOrderStatus(
        orderStatus: orderStatus,
        deliveryStatus: deliveryStatus ?? 'Pending',
      );

  static String label(String statusCode) => switch (statusCode) {
        'Delivering' => 'Đang giao',
        'Delivered' => 'Đã giao',
        'Completed' => 'Hoàn tất',
        'Confirmed' => 'Đã xác nhận',
        'Preparing' => 'Đang chuẩn bị',
        'PickedUp' => 'Đã lấy hàng',
        'Cancelled' => 'Đã hủy',
        'Refunded' => 'Đã hoàn tiền',
        _ => statusCode,
      };

  static bool isActiveCode(String statusCode) =>
      !const {'Delivered', 'Completed', 'Cancelled', 'Refunded'}.contains(statusCode);
}
