import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';

/// Cached default delivery fee from Order service (`OrderSettings.DefaultDeliveryFee`).
class DeliveryFeeConfig {
  DeliveryFeeConfig(this._checkout);

  final CheckoutRemoteDataSource _checkout;

  double? _cached;

  Future<double> load() async {
    if (_cached != null) return _cached!;
    try {
      final fees = await _checkout.getCheckoutFees();
      _cached = fees.defaultDeliveryFee;
    } catch (_) {
      _cached = _fallbackFee;
    }
    return _cached!;
  }

  double? get cached => _cached;

  void invalidate() => _cached = null;

  static const double _fallbackFee = 25000;
}
