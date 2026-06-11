import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/app_location_resolver.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/widgets/price_breakdown.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _api = getIt<OrderRemoteDataSource>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final _voucher = TextEditingController();
  bool _placing = false;
  double? _lat;
  double? _lng;
  static const _deliveryFee = 25000.0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await AppLocationResolver.resolve();
    if (!mounted || loc.lat == null) return;
    setState(() {
      _lat = loc.lat;
      _lng = loc.lng;
    });
  }

  Future<void> _placeOrder() async {
    final cart = context.read<MarketplaceCartCubit>().state;
    if (cart.partnerId == null || cart.items.isEmpty) return;

    setState(() => _placing = true);
    try {
      final order = await _api.placeOrder({
        'partnerId': cart.partnerId,
        'items': cart.items
            .map((i) => {
                  'foodMenuItemId': i.foodMenuItemId,
                  'quantity': i.quantity,
                  if (i.notes != null) 'notes': i.notes,
                })
            .toList(),
        if (_voucher.text.isNotEmpty) 'voucherId': _voucher.text.trim(),
        'deliveryAddress': _address.text.trim(),
        'deliveryLat': _lat,
        'deliveryLng': _lng,
        'recipientName': _name.text.trim(),
        'recipientPhone': _phone.text.trim(),
        'notes': _notes.text.trim(),
        'clientRequestKey': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      context.read<MarketplaceCartCubit>().clear();
      if (mounted) {
        context.go(AppRoutes.orderSuccess, extra: order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<MarketplaceCartCubit>().state;
    final discount = 0.0;
    final total = cart.subtotal + _deliveryFee - discount;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Địa chỉ giao', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _address, decoration: const InputDecoration(hintText: 'Địa chỉ giao hàng')),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên người nhận')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
          const SizedBox(height: 16),
          TextField(controller: _voucher, decoration: const InputDecoration(labelText: 'Mã voucher (tùy chọn)')),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: MarketplaceTheme.cardDecoration(),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: MarketplaceTheme.primary),
                SizedBox(width: 12),
                Expanded(child: Text('Ví SYNC (thanh toán tự động)')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Ghi chú đơn')),
          const SizedBox(height: 16),
          PriceBreakdown(
            subtotal: cart.subtotal,
            deliveryFee: _deliveryFee,
            discount: discount,
            total: total,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _placing ? null : _placeOrder,
            style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
            child: _placing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Đặt đơn'),
          ),
        ),
      ),
    );
  }
}
