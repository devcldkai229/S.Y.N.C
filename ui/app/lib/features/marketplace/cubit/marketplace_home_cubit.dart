import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/safe_emit.dart';
import 'package:sync_app/features/marketplace/data/marketplace_repository.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/services/marketplace_location_service.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';

part 'marketplace_home_state.dart';

class MarketplaceHomeCubit extends Cubit<MarketplaceHomeState> with SafeEmitMixin<MarketplaceHomeState> {
  MarketplaceHomeCubit(this._repository, this._checkout) : super(const MarketplaceHomeState());

  final MarketplaceRepository _repository;
  final CheckoutRemoteDataSource _checkout;

  Future<void> init() async {
    safeEmit(state.copyWith(status: MarketplaceHomeStatus.loading, clearError: true));
    await _loadSavedAddress();
    await _loadCatalog();
  }

  Future<void> refresh() async {
    safeEmit(state.copyWith(status: MarketplaceHomeStatus.loading, clearError: true));
    await _loadSavedAddress();
    await _loadCatalog();
  }

  Future<void> _loadSavedAddress() async {
    try {
      final saved = await _checkout.getCurrentAddress();
      if (saved == null || isClosed) return;
      safeEmit(state.copyWith(
        delivery: DeliveryLocation(
          lat: saved.lat,
          lng: saved.lng,
          shortLabel: MarketplaceLocationService.shortenAddress(saved.label),
          fullAddress: saved.label,
        ),
        locationStatus: MarketplaceLocationStatus.ready,
      ));
    } catch (_) {}
  }

  Future<void> _loadCatalog() async {
    try {
      final data = await _repository.loadHome(
        lat: state.delivery?.lat,
        lng: state.delivery?.lng,
        categoryId: state.selectedCategoryId,
      );
      if (isClosed) return;
      safeEmit(state.copyWith(
        status: MarketplaceHomeStatus.success,
        data: data,
      ));
    } catch (e) {
      if (isClosed) return;
      safeEmit(state.copyWith(
        status: MarketplaceHomeStatus.failure,
        error: _friendlyLoadError(e),
      ));
    }
  }

  static String _friendlyLoadError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 401) return 'Phiên đăng nhập hết hạn — hãy đăng nhập lại.';
      if (code == 404) return 'Không tìm thấy API Sync Foods. Kiểm tra Gateway và Marketplace API.';
      if (code != null) return 'Lỗi tải Sync Foods (HTTP $code).';
    }
    return 'Không tải được Sync Foods. Vui lòng thử lại.';
  }

  Future<void> selectCategory(String? categoryId) async {
    if (state.selectedCategoryId == categoryId) return;
    safeEmit(state.copyWith(
      selectedCategoryId: categoryId,
      status: MarketplaceHomeStatus.loading,
    ));
    await _loadCatalog();
  }

  Future<void> setDeliveryLocation(DeliveryLocation location) async {
    safeEmit(state.copyWith(
      delivery: location,
      locationStatus: MarketplaceLocationStatus.ready,
      status: MarketplaceHomeStatus.loading,
    ));
    await _loadCatalog();
  }

  Future<void> trackAffiliateClick(String productId) =>
      _repository.trackAffiliateClick(productId);
}
