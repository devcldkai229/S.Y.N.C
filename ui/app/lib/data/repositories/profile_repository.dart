import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

class ProfileLoadResult {
  ProfileLoadResult({
    required this.settings,
    this.inventory,
    this.biometric,
    this.publicProfile,
  });

  final ProfileSettings settings;
  final UserInventory? inventory;
  final BiometricProfileDetail? biometric;
  final PublicProfile? publicProfile;
}

class ProfileRepository {
  ProfileRepository(this._api);

  final ProfileApiService _api;

  Future<ProfileLoadResult> load() async {
    final settings = await _api.getProfileSettings();

    UserInventory? inventory;
    try {
      inventory = await _api.getInventory();
    } catch (_) {}

    BiometricProfileDetail? biometric;
    if (settings.fitness.isConfigured) {
      try {
        biometric = await _api.getBiometricProfile();
      } catch (_) {}
    }

    PublicProfile? publicProfile;
    if (settings.userId.isNotEmpty) {
      try {
        publicProfile = await _api.getPublicProfile(settings.userId);
      } catch (_) {}
    }

    return ProfileLoadResult(
      settings: settings,
      inventory: inventory,
      biometric: biometric,
      publicProfile: publicProfile,
    );
  }

  Future<ProfileSettings> updateBasic({
    String? fullName,
    String? avatarUrl,
    String? preferredLanguage,
    String? timeZone,
  }) =>
      _api.updateBasicProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        preferredLanguage: preferredLanguage,
        timeZone: timeZone,
      );

  Future<ProfileSettings> updateFitness(FitnessProfile fitness) =>
      _api.updateFitnessProfile(fitness);

  Future<ProfileSettings> updatePreferences(AccountPreferences preferences) =>
      _api.updateAccountPreferences(preferences);

  Future<void> logWeight(double kg) async {
    await _api.logWeight(kg);
  }
}
