import 'package:flutter/foundation.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';

/// Shared active-order badge count for radial menu and order list.
class ActiveOrderCountNotifier extends ChangeNotifier {
  ActiveOrderCountNotifier(this._orders);

  final OrderRemoteDataSource _orders;
  int _count = 0;
  bool _loading = false;

  int get count => _count;
  bool get isLoading => _loading;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      _count = await _orders.getActiveOrderCount();
      notifyListeners();
    } catch (_) {
      // Keep last known count on transient failures.
    } finally {
      _loading = false;
    }
  }
}
