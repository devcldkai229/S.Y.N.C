import 'package:dio/dio.dart';
import 'package:sync_app/l10n/app_localizations.dart';

/// Maps IAM auth API errors to localized user-facing messages.
String mapAuthError(Object error, AppLocalizations l10n) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        if (message == 'An unexpected error occurred.') {
          return l10n.authErrorServer;
        }
        if (message.toLowerCase().contains('email has not been verified')) {
          return l10n.authErrorEmailNotVerified;
        }
        if (message.toLowerCase().contains('invalid email or password')) {
          return l10n.authErrorInvalidCredentials;
        }
        if (message.toLowerCase().contains('already exists')) {
          return l10n.authErrorEmailExists;
        }
        if (message.toLowerCase().contains('verification token')) {
          return l10n.authErrorInvalidToken;
        }
        return message;
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return l10n.authErrorConnection(error.requestOptions.uri.toString());
    }
    return error.message ?? l10n.authErrorGeneric;
  }
  return error.toString().replaceFirst('Exception: ', '');
}
