/// Maps API order/delivery statuses to tracking UI stepper labels.
abstract final class TrackingStatusMapper {
  static String displayOrderStatus({
    String? orderStatus,
    required String deliveryStatus,
  }) {
    final normalized = _normalizeOrderStatus(orderStatus);
    if (normalized != 'Confirmed' && normalized != 'Pending') {
      return normalized;
    }
    return _fromDelivery(deliveryStatus);
  }

  static String statusMessage({
    String? orderStatus,
    required String deliveryStatus,
    String? apiMessage,
  }) {
    if (apiMessage != null && apiMessage.isNotEmpty) return apiMessage;
    final display = displayOrderStatus(
      orderStatus: orderStatus,
      deliveryStatus: deliveryStatus,
    );
    return _messageFor(display, deliveryStatus);
  }

  static bool isActiveDelivery(String? deliveryStatus) {
    if (deliveryStatus == null || deliveryStatus.isEmpty) return false;
    return !const {
      'Pending',
      'Completed',
      'Cancelled',
      'Failed',
    }.contains(deliveryStatus);
  }

  static String _normalizeOrderStatus(String? raw) {
    if (raw == null || raw.isEmpty) return 'Confirmed';
    if (raw == 'ReadyForPickup') return 'Preparing';
    if (raw == 'Completed') return 'Delivered';
    return raw;
  }

  static String _fromDelivery(String delivery) => switch (delivery) {
        'Assigned' || 'HeadingToPickup' || 'ArrivedAtPickup' => 'Preparing',
        'PickedUp' => 'PickedUp',
        'Delivering' || 'Arrived' => 'Delivering',
        'Completed' => 'Delivered',
        'Cancelled' || 'Failed' => 'Cancelled',
        _ => 'Confirmed',
      };

  static String _messageFor(String displayStatus, String deliveryStatus) =>
      switch (displayStatus) {
        'Confirmed' => 'Đơn hàng đã được xác nhận',
        'Preparing' => deliveryStatus == 'ArrivedAtPickup'
            ? 'Tài xế đã đến quán lấy hàng'
            : deliveryStatus == 'HeadingToPickup'
                ? 'Tài xế đang đến quán'
                : 'Bếp đang chuẩn bị món của bạn',
        'PickedUp' => 'Shipper đã lấy hàng, đang đến chỗ bạn',
        'Delivering' => deliveryStatus == 'Arrived'
            ? 'Tài xế đã đến gần địa chỉ giao hàng'
            : 'Đơn đang trên đường tới bạn',
        'Delivered' => 'Đã giao thành công',
        'Cancelled' => 'Đơn đã bị huỷ',
        _ => 'Đang cập nhật trạng thái giao hàng',
      };
}
