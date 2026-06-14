import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';

Future<void> _showAddedToCartDialog(BuildContext context, {required int quantity}) {
  final message = quantity == 1
      ? 'Đã thêm 1 món ăn vào giỏ hàng'
      : 'Đã thêm $quantity món ăn vào giỏ hàng';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.shopping_cart_outlined, color: MarketplaceTheme.primary, size: 44),
      title: const Text('Đã thêm vào giỏ'),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

Future<bool> marketplaceAddToCart(
  BuildContext context, {
  required FoodMenuItem item,
  required String partnerName,
  int quantity = 1,
  String? notes,
}) async {
  final cubit = context.read<MarketplaceCartCubit>();
  final ok = await cubit.addItem(
    item: item,
    partnerName: partnerName,
    quantity: quantity,
    notes: notes,
  );
  if (!context.mounted) return ok;

  final conflict = cubit.state.conflictMessage;
  if (conflict != null) {
    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi bếp?'),
        content: const Text(
          'Giỏ đang có món từ bếp khác. Xoá giỏ để đặt món từ bếp này?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá & thêm')),
        ],
      ),
    );
    cubit.clearConflictMessage();
    if (clear == true) {
      final cleared = await cubit.addItemAfterClear(
        item: item,
        partnerName: partnerName,
        quantity: quantity,
        notes: notes,
      );
      if (cleared && context.mounted) {
        await _showAddedToCartDialog(context, quantity: quantity);
      }
      return cleared;
    }
    return false;
  }

  if (ok && context.mounted) {
    await _showAddedToCartDialog(context, quantity: quantity);
  }
  return ok;
}
