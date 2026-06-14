part of 'marketplace_cart_cubit.dart';

class MarketplaceCartState extends Equatable {
  const MarketplaceCartState({
    this.items = const [],
    this.partnerId,
    this.partnerName,
    this.subtotal = 0,
    this.conflictMessage,
  });

  final List<CartLine> items;
  final String? partnerId;
  final String? partnerName;
  final double subtotal;
  final String? conflictMessage;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  MarketplaceCartState copyWith({
    List<CartLine>? items,
    String? partnerId,
    String? partnerName,
    double? subtotal,
    String? conflictMessage,
    bool clearConflict = false,
  }) =>
      MarketplaceCartState(
        items: items ?? this.items,
        partnerId: partnerId ?? this.partnerId,
        partnerName: partnerName ?? this.partnerName,
        subtotal: subtotal ?? this.subtotal,
        conflictMessage: clearConflict ? null : (conflictMessage ?? this.conflictMessage),
      );

  @override
  List<Object?> get props => [items, partnerId, partnerName, subtotal, conflictMessage];
}
