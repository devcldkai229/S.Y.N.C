import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/order/widgets/cart_item_tile.dart';

class MarketplaceCartSheet extends StatelessWidget {
  const MarketplaceCartSheet({super.key, required this.cart, required this.cubit});

  final MarketplaceCartState cart;
  final MarketplaceCartCubit cubit;

  static void show(BuildContext context) {
    final cart = context.read<MarketplaceCartCubit>().state;
    if (cart.items.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MarketplaceCartSheet(
        cart: cart,
        cubit: context.read<MarketplaceCartCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MarketplaceTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Giỏ hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Material(
              color: MarketplaceTheme.lightGreen,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: cart.partnerId != null
                    ? () {
                        Navigator.pop(context);
                        context.push(AppRoutes.marketplacePartner(cart.partnerId!));
                      }
                    : null,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: MarketplaceTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nhà hàng',
                              style: TextStyle(fontSize: 11, color: MarketplaceTheme.textMuted),
                            ),
                            Text(
                              cart.partnerName ?? 'Bếp',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: MarketplaceTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...cart.items.map(
              (line) => CartItemTile(
                line: line,
                onQtyChanged: (q) => cubit.updateQuantity(line.foodMenuItemId, q),
                onRemove: () => cubit.removeItem(line.foodMenuItemId),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  MarketplaceFormatters.formatVnd(cart.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.orderCheckout);
              },
              style: FilledButton.styleFrom(
                backgroundColor: MarketplaceTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tiếp tục thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}
