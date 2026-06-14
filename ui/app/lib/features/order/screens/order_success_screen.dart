import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/order/models/order_models.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order, this.navigateToOrders = false});

  final OrderSummary order;
  final bool navigateToOrders;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.navigateToOrders) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('${AppRoutes.orderList}?tab=active');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.check_circle, color: MarketplaceTheme.primary, size: 88),
              const SizedBox(height: 16),
              const Text('Đặt hàng thành công!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Mã đơn: ${widget.order.orderCode}', style: const TextStyle(color: MarketplaceTheme.textMuted)),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('${AppRoutes.orderList}?tab=active'),
                style: FilledButton.styleFrom(
                  backgroundColor: MarketplaceTheme.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Xem đơn đang giao'),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.orderDetail(widget.order.id)),
                child: const Text('Theo dõi đơn này'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
