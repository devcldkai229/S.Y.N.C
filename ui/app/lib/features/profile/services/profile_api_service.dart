import 'package:dio/dio.dart';
import 'package:sync_app/core/models/api_models.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';

class ProfileApiService {
  ProfileApiService(this._dio);

  final Dio _dio;

  Future<ProfileSettings> getProfileSettings() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.meProfileSettings);
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      ProfileSettings.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Failed to load profile.' : envelope.message);
    }
    return envelope.data!;
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
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      ProfileSettings.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Failed to update profile.' : envelope.message);
    }
    return envelope.data!;
  }

  Future<ProfileSettings> updateFitnessProfile(FitnessProfile fitness) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.meFitnessProfile,
      data: fitness.toUpdateJson(),
    );
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      ProfileSettings.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Failed to update fitness profile.' : envelope.message);
    }
    return envelope.data!;
  }
}
