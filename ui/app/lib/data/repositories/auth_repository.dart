import 'package:sync_app/features/auth/models/auth_models.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

class AuthRepository {
  AuthRepository(this._auth, this._profileApi);

  final AuthService _auth;
  final ProfileApiService _profileApi;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _auth.login(email: email, password: password);

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
  }) => _auth.register(fullName: fullName, email: email, password: password);

  Future<RegisterResult> resendVerificationCode({required String email}) =>
      _auth.resendVerificationCode(email: email);

  Future<VerifyEmailResult> verifyEmail(String token) =>
      _auth.verifyEmail(token);

  Future<AuthSession> signInWithGoogle() => _auth.loginWithGoogle();

  Future<bool> isLoggedIn() => _auth.isLoggedIn();

  Future<void> logout() => _auth.logout();

  /// Returns true when user should complete profile onboarding (Side A + B).
  Future<bool> needsOnboarding() async {
    try {
      final settings = await _profileApi.getProfileSettings();
      final fitnessReady =
          settings.fitness.isConfigured &&
          (settings.fitness.fitnessGoal ?? '').isNotEmpty &&
          (settings.fitness.activityLevel ?? '').isNotEmpty;
      final prefsReady = settings.preferences.isConfigured;
      return !fitnessReady || !prefsReady;
    } catch (_) {
      return false;
    }
  }
}
