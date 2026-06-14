import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/safe_emit.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

part 'achievements_state.dart';

class AchievementsCubit extends Cubit<AchievementsState> with SafeEmitMixin<AchievementsState> {
  AchievementsCubit(this._profileApi) : super(const AchievementsState());

  final ProfileApiService _profileApi;

  Future<void> load() async {
    safeEmit(state.copyWith(status: AchievementsStatus.loading, clearError: true));
    try {
      final inventory = await _profileApi.getInventory();
      safeEmit(state.copyWith(status: AchievementsStatus.success, inventory: inventory));
    } catch (e) {
      // Backend down / timeout — still show demo achievements instead of a blank error screen.
      safeEmit(state.copyWith(
        status: AchievementsStatus.success,
        inventory: null,
        error: mapApiError(e),
      ));
    }
  }
}
