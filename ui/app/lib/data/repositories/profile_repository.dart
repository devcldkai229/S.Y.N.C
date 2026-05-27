import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ProfileApiService _api;

  Future<({ProfileSettings settings, UserInventory? inventory})> load() async {
    final settings = await _api.getProfileSettings();
    UserInventory? inventory;
    try {
      inventory = await _api.getInventory();
    } catch (_) {}
    return (settings: settings, inventory: inventory);
  }

  Future<ProfileSettings> save({
    required String fullName,
    required FitnessProfile fitness,
  }) async {
    await _api.updateBasicProfile(fullName: fullName);
    return _api.updateFitnessProfile(fitness);
  }
}
