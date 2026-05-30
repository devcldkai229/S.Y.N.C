import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  ShopCubit(this._profileApi) : super(const ShopState());

  final ProfileApiService _profileApi;

  Future<void> load() async {
    emit(state.copyWith(status: ShopStatus.loading, clearError: true));
    try {
      final items = await _profileApi.getShop();
      emit(state.copyWith(status: ShopStatus.success, items: items));
    } catch (e) {
      emit(state.copyWith(status: ShopStatus.failure, error: mapApiError(e)));
    }
  }

  Future<PurchaseResult?> purchase(String itemCode) async {
    emit(state.copyWith(purchasing: itemCode, clearPurchaseError: true));
    try {
      final result = await _profileApi.purchaseShopItem(itemCode);
      emit(state.copyWith(purchasing: '', lastPurchase: result));
      return result;
    } catch (e) {
      emit(state.copyWith(purchasing: '', purchaseError: mapApiError(e)));
      return null;
    }
  }
}
