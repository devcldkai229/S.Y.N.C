import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/data/models/onboarding_models.dart';

class OnboardingRemoteDataSource {
  OnboardingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> saveBasic(OnboardingStep1Request request) async {
    await _post(ApiPaths.onboardingBasic, request.toJson());
  }

  Future<void> saveGoals(OnboardingStep2Request request) async {
    await _post(ApiPaths.onboardingGoals, request.toJson());
  }

  Future<void> saveComposition(OnboardingStep3Request request) async {
    await _post(ApiPaths.onboardingComposition, request.toJson());
  }

  Future<void> saveSafeguards(OnboardingStep4Request request) async {
    await _post(ApiPaths.onboardingSafeguards, request.toJson());
  }

  Future<void> saveAccountPreferences(OnboardingAccountPreferencesRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.meAccountPreferences,
      data: request.toJson(),
    );
    final success = response.data?['success'] == true;
    if (!success) {
      throw Exception(response.data?['message']?.toString() ?? 'Failed to save preferences.');
    }
  }

  Future<void> completeOnboarding() async {
    await _post(ApiPaths.onboardingComplete, {});
  }

  Future<void> _post(String path, Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: data);
    final success = response.data?['success'] == true;
    if (!success) {
      throw Exception(response.data?['message']?.toString() ?? 'Onboarding save failed.');
    }
  }
}
