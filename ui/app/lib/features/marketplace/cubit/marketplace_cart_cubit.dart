import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/safe_emit.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';

part 'marketplace_cart_state.dart';

class MarketplaceCartCubit extends Cubit<MarketplaceCartState> with SafeEmitMixin<MarketplaceCartState> {
  MarketplaceCartCubit(this._checkout) : super(const MarketplaceCartState());

  final CheckoutRemoteDataSource _checkout;

  Future<void> hydrate() async {
    try {
      final cart = await _checkout.getCart();
      _applyRemoteCart(cart);
    } catch (_) {}
  }

  Future<bool> addItem({
    required FoodMenuItem item,
    required String partnerName,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      final cart = await _checkout.addCartItem(
        partnerId: item.partnerId,
        foodMenuItemId: item.id,
        quantity: quantity,
        notes: notes,
      );
      _applyRemoteCart(cart);
      return true;
    } on CartPartnerConflict catch (e) {
      safeEmit(state.copyWith(conflictMessage: e.message));
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addItemAfterClear({
    required FoodMenuItem item,
    required String partnerName,
    int quantity = 1,
    String? notes,
  }) async {
    await _checkout.clearCart();
    safeEmit(const MarketplaceCartState());
    return addItem(item: item, partnerName: partnerName, quantity: quantity, notes: notes);
  }

  Future<void> updateQuantity(String foodMenuItemId, int quantity) async {
    try {
      final cart = await _checkout.updateCartItemQuantity(foodMenuItemId, quantity);
      _applyRemoteCart(cart);
    } catch (_) {}
  }

  Future<void> removeItem(String foodMenuItemId) async {
    await updateQuantity(foodMenuItemId, 0);
  }

  Future<void> clear() async {
    try {
      await _checkout.clearCart();
      safeEmit(const MarketplaceCartState());
    } catch (_) {}
  }

  void clearConflictMessage() => safeEmit(state.copyWith(conflictMessage: null));

  void _applyRemoteCart(RemoteCart cart) {
    safeEmit(MarketplaceCartState(
      items: cart.items
          .map((i) => CartLine(
                foodMenuItemId: i.foodMenuItemId,
                partnerId: cart.partnerId ?? '',
                partnerName: cart.partnerName ?? 'Bếp',
                name: i.nameSnapshot,
                imageUrl: i.imageUrlSnapshot,
                unitPrice: i.unitPrice,
                quantity: i.quantity,
                notes: i.notes,
              ))
          .toList(),
      partnerId: cart.partnerId,
      partnerName: cart.partnerName,
      subtotal: cart.subtotal,
    ));
  }
}
