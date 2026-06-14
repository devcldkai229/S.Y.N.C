part of 'shop_cubit.dart';

enum ShopStatus { initial, loading, success, failure }

class ShopState extends Equatable {
  const ShopState({
    this.status = ShopStatus.initial,
    this.items = const [],
    this.error,
    this.purchasing = '',
    this.lastPurchase,
    this.purchaseError,
    this.syncCoins = 0.0,
  });

  final ShopStatus status;
  final List<ShopItem> items;
  final String? error;
  final String purchasing;
  final PurchaseResult? lastPurchase;
  final String? purchaseError;
  final double syncCoins;

  bool get isLoading => status == ShopStatus.loading;

  ShopState copyWith({
    ShopStatus? status,
    List<ShopItem>? items,
    String? error,
    bool clearError = false,
    String? purchasing,
    PurchaseResult? lastPurchase,
    bool clearPurchaseSuccess = false,
    String? purchaseError,
    bool clearPurchaseError = false,
    double? syncCoins,
  }) {
    return ShopState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      purchasing: purchasing ?? this.purchasing,
      lastPurchase: clearPurchaseSuccess ? null : (lastPurchase ?? this.lastPurchase),
      purchaseError: clearPurchaseError ? null : (purchaseError ?? this.purchaseError),
      syncCoins: syncCoins ?? this.syncCoins,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        error,
        purchasing,
        lastPurchase,
        purchaseError,
        syncCoins,
      ];
}
