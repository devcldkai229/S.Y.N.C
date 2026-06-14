import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/core/utils/currency_formatter.dart';
import 'package:sync_app/features/order/widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCartCubit, MarketplaceCartState>(
      builder: (context, cart) {
        final cubit = context.read<MarketplaceCartCubit>();
        return Scaffold(
          backgroundColor: MarketplaceTheme.background,
          appBar: AppBar(
            backgroundColor: MarketplaceTheme.background,
            title: const Text('Giỏ hàng'),
          ),
          body: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Giỏ trống — khám phá Sync Foods nhé'),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.marketplaceHome),
                        child: const Text('Đến Sync Foods'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(cart.partnerName ?? 'Bếp', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ...cart.items.map((line) => CartItemTile(
                          line: line,
                          onQtyChanged: (q) => cubit.updateQuantity(line.foodMenuItemId, q),
                          onRemove: () => cubit.removeItem(line.foodMenuItemId),
                        )),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính'),
                        Text(
                          CurrencyFormatter.formatVnd(cart.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
          bottomNavigationBar: cart.items.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(
                      onPressed: () => context.push(AppRoutes.orderCheckout),
                      style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
                      child: Text(
                        'Tiến hành thanh toán · ${CurrencyFormatter.formatVnd(cart.subtotal)}',
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
