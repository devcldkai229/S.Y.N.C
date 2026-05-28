import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

/// Supported app UI languages (synced with IAM `preferredLanguage`: `vi` | `en`).
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(Locale(normalizeCode(_prefs.getString(_storageKey))));

  static const _storageKey = 'app_locale';
  static const supportedCodes = ['vi', 'en'];

  final SharedPreferences _prefs;

  static String normalizeCode(String? code) {
    final raw = (code ?? 'vi').trim().toLowerCase();
    if (raw.startsWith('en')) return 'en';
    return 'vi';
  }

  /// Syncs locale from IAM when logged in. Call after first frame (non-blocking startup).
  Future<void> bootstrap() async {
    var code = state.languageCode;

    if (getIt.isRegistered<AuthRepository>()) {
      final loggedIn = await getIt<AuthRepository>().isLoggedIn();
      if (loggedIn && getIt.isRegistered<ProfileApiService>()) {
        try {
          final settings = await getIt<ProfileApiService>().getProfileSettings();
          code = normalizeCode(settings.basic.preferredLanguage);
          await _prefs.setString(_storageKey, code);
        } catch (_) {
          // Keep local preference when offline.
        }
      }
    }

    emit(Locale(code));
  }

  /// Changes UI language, persists locally, and syncs IAM when authenticated.
  Future<void> changeLanguage(String languageCode) async {
    final code = normalizeCode(languageCode);
    if (state.languageCode == code) return;

    emit(Locale(code));
    await _prefs.setString(_storageKey, code);

    if (getIt.isRegistered<AuthRepository>() && getIt.isRegistered<ProfileApiService>()) {
      try {
        final loggedIn = await getIt<AuthRepository>().isLoggedIn();
        if (loggedIn) {
          await getIt<ProfileApiService>().updateBasicProfile(preferredLanguage: code);
        }
      } catch (_) {
        // UI still switches; profile sync can retry from Profile screen.
      }
    }
  }

  String get currentCode => state.languageCode;
}
