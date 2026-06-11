import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/order/models/order_models.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final OrderSummary order;

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
              const Text('Đặt đơn thành công!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Mã đơn: ${order.orderCode}', style: const TextStyle(color: MarketplaceTheme.textMuted)),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoutes.orderDetail(order.id)),
                style: FilledButton.styleFrom(
                  backgroundColor: MarketplaceTheme.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Theo dõi đơn'),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.orderList),
                child: const Text('Xem đơn của tôi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
