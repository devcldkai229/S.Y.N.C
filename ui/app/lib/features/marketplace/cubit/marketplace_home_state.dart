part of 'marketplace_home_cubit.dart';

enum MarketplaceHomeStatus { initial, loading, success, failure }

enum MarketplaceLocationStatus {
  initial,
  resolving,
  ready,
  pickRequired,
  serviceOff,
  denied,
  deniedForever,
}

class MarketplaceHomeState extends Equatable {
  const MarketplaceHomeState({
    this.status = MarketplaceHomeStatus.initial,
    this.locationStatus = MarketplaceLocationStatus.initial,
    this.data,
    this.delivery,
    this.selectedCategoryId,
    this.error,
  });

  final MarketplaceHomeStatus status;
  final MarketplaceLocationStatus locationStatus;
  final MarketplaceHomeData? data;
  final DeliveryLocation? delivery;
  final String? selectedCategoryId;
  final String? error;

  bool get isLoading => status == MarketplaceHomeStatus.loading && data == null;

  MarketplaceHomeState copyWith({
    MarketplaceHomeStatus? status,
    MarketplaceLocationStatus? locationStatus,
    MarketplaceHomeData? data,
    DeliveryLocation? delivery,
    String? selectedCategoryId,
    String? error,
    bool clearError = false,
  }) =>
      MarketplaceHomeState(
        status: status ?? this.status,
        locationStatus: locationStatus ?? this.locationStatus,
        data: data ?? this.data,
        delivery: delivery ?? this.delivery,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        status,
        locationStatus,
        data,
        delivery,
        selectedCategoryId,
        error,
      ];
}
