import 'package:dio/dio.dart';
import 'package:sync_app/core/models/api_models.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';

class ProfileApiService {
  ProfileApiService(this._dio);

  final Dio _dio;

  Future<ProfileSettings> getProfileSettings() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.meProfileSettings);
    return _parseSettings(response.data);
  }

  Future<UserInventory> getInventory() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.meInventory);
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      UserInventory.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Failed to load inventory.' : envelope.message);
    }
    return envelope.data!;
  }

  Future<BiometricProfileDetail> getBiometricProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.biometrics);
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      BiometricProfileDetail.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(
        envelope.message.isEmpty ? 'Failed to load biometric profile.' : envelope.message,
      );
    }
    return envelope.data!;
  }

  Future<PublicProfile> getPublicProfile(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.userPublicProfile(userId));
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      PublicProfile.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(
        envelope.message.isEmpty ? 'Failed to load public profile.' : envelope.message,
      );
    }
    return envelope.data!;
  }

  Future<ProfileSettings> updateBasicProfile({
    String? fullName,
    String? avatarUrl,
    String? preferredLanguage,
    String? timeZone,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.meBasicProfile,
      data: <String, dynamic>{
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'preferredLanguage': preferredLanguage,
        'timeZone': timeZone,
      },
    );
    return _parseSettings(response.data);
  }

  Future<ProfileSettings> updateFitnessProfile(FitnessProfile fitness) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.meFitnessProfile,
      data: fitness.toUpdateJson(),
    );
    return _parseSettings(response.data);
  }

  Future<ProfileSettings> updateAccountPreferences(AccountPreferences preferences) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.meAccountPreferences,
      data: preferences.toUpdateJson(),
    );
    return _parseSettings(response.data);
  }

  Future<BiometricProfileDetail> logWeight(double currentWeightKg) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.biometricsLogWeight,
      data: {'currentWeightKg': currentWeightKg},
    );
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      BiometricProfileDetail.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Failed to log weight.' : envelope.message);
    }
    return envelope.data!;
  }

  Future<LogActivityResult> logActivity() async {
    final response = await _dio.post<Map<String, dynamic>>(ApiPaths.meActivityLog);
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      LogActivityResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Failed to log activity.' : envelope.message);
    }
    return envelope.data!;
  }

  Future<List<ShopItem>> getShop() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.meShop);
    final json = response.data ?? {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load shop.').toString());
    }
    final raw = json['data'];
    return (raw as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ShopItem.fromJson)
        .toList();
  }

  Future<PurchaseResult> purchaseShopItem(String itemCode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.meShopPurchase,
      data: {'itemCode': itemCode},
    );
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      PurchaseResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Purchase failed.' : envelope.message);
    }
    return envelope.data!;
  }

  ProfileSettings _parseSettings(Map<String, dynamic>? data) {
    final envelope = ApiEnvelope.fromJson(data ?? {}, ProfileSettings.fromJson);
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Failed to load profile.' : envelope.message);
    }
    return envelope.data!;
  }
}
