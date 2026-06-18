import 'package:sync_app/data/datasources/onboarding_remote_data_source.dart';
import 'package:sync_app/data/models/onboarding_models.dart';

class OnboardingRepository {
  OnboardingRepository(this._remote);

  final OnboardingRemoteDataSource _remote;

  Future<void> submitStep1(OnboardingStep1Request request) => _remote.saveBasic(request);

  Future<void> submitStep2(OnboardingStep2Request request) => _remote.saveGoals(request);

  Future<void> submitStep3(OnboardingStep3Request request) => _remote.saveComposition(request);

  Future<void> submitStep4(OnboardingStep4Request request) => _remote.saveSafeguards(request);

  Future<void> submitAccountPreferences(OnboardingAccountPreferencesRequest request) =>
      _remote.saveAccountPreferences(request);

  Future<void> completeOnboarding() => _remote.completeOnboarding();
}
