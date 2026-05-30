import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

part 'achievements_state.dart';

class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit(this._profileApi) : super(const AchievementsState());

  final ProfileApiService _profileApi;

  Future<void> load() async {
    emit(state.copyWith(status: AchievementsStatus.loading, clearError: true));
    try {
      final inventory = await _profileApi.getInventory();
      emit(state.copyWith(status: AchievementsStatus.success, inventory: inventory));
    } catch (e) {
      emit(state.copyWith(status: AchievementsStatus.failure, error: mapApiError(e)));
    }
  }
}
