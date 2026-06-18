class ApiEnvelope<T> {
  ApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiEnvelope<T>(
      success: (json['success'] ?? false) as bool,
      message: (json['message'] ?? '').toString(),
      data: rawData is Map<String, dynamic> ? fromJsonT(rawData) : null,
      errors: json['errors'],
    );
  }
}

class AuthSession {
  AuthSession({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String userId;
  final String email;
  final String fullName;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: (json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      expiresIn: (json['expiresIn'] ?? 0) as int,
    );
  }
}

class RegisterResult {
  RegisterResult({
    required this.userId,
    required this.email,
    required this.message,
  });

  final String userId;
  final String email;
  final String message;

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    return RegisterResult(
      userId: (json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }

  /// Combines envelope-level [apiMessage] with optional [data].message from IAM.
  factory RegisterResult.fromEnvelope(
    ApiEnvelope<RegisterResult> envelope,
  ) {
    final data = envelope.data;
    final dataMessage = data?.message ?? '';
    final apiMessage = envelope.message;
    final combined = apiMessage.isNotEmpty
        ? apiMessage
        : (dataMessage.isNotEmpty
            ? dataMessage
            : 'Đăng ký thành công. Vui lòng xác minh email trước khi đăng nhập.');
    return RegisterResult(
      userId: data?.userId ?? '',
      email: data?.email ?? '',
      message: combined,
    );
  }
}

class VerifyEmailResult {
  VerifyEmailResult({
    required this.userId,
    required this.email,
    required this.emailVerified,
  });

  final String userId;
  final String email;
  final bool emailVerified;

  factory VerifyEmailResult.fromJson(Map<String, dynamic> json) {
    return VerifyEmailResult(
      userId: (json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      emailVerified: json['emailVerified'] == true,
    );
  }
}
