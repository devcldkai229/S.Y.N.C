import 'package:dio/dio.dart';
import 'package:sync_app/core/network/dio_errors.dart';

/// Maps API / network errors to short, user-facing Vietnamese messages.
String mapApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final path = error.requestOptions.path;
    final bodyMessage = _bodyMessage(error);

    if (status == 404) {
      if (_isAiPath(path)) {
        return sanitizeUserFacingMessage(
          bodyMessage ?? 'Gợi ý bài tập AI chưa sẵn sàng. Vui lòng thử lại sau.',
        );
      }
      if (_isProfilePath(path)) {
        return sanitizeUserFacingMessage(
          bodyMessage ??
              'Không tìm thấy dữ liệu hồ sơ. Hãy hoàn tất onboarding hoặc thử lại sau.',
        );
      }
      return sanitizeUserFacingMessage(
        bodyMessage ?? 'Không tìm thấy dữ liệu yêu cầu.',
      );
    }
    if (status == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (status == 409) {
      return sanitizeUserFacingMessage(
        bodyMessage ?? 'Dữ liệu đang được đồng bộ. Vui lòng thử lại sau.',
      );
    }
    if (status == 502 || status == 503) {
      if (_isAiPath(path)) {
        return sanitizeUserFacingMessage(
          bodyMessage ??
              'Gợi ý bài tập AI tạm thời không khả dụng. Vui lòng thử lại sau.',
        );
      }
      return sanitizeUserFacingMessage(
        bodyMessage ?? 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.',
      );
    }
    if (isConnectivityDioError(error)) {
      return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    }
    if (bodyMessage != null) return sanitizeUserFacingMessage(bodyMessage);
    return sanitizeUserFacingMessage(error.message ?? 'Yêu cầu thất bại.');
  }
  return sanitizeUserFacingMessage(
    error.toString().replaceFirst('Exception: ', ''),
  );
}

/// Strips dev-only or backend technical details from messages shown in UI.
String sanitizeUserFacingMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';

  final lower = trimmed.toLowerCase();
  if (lower.contains('reindex') ||
      lower.contains('admin chạy') ||
      lower.contains('chưa có dữ liệu bài tập')) {
    return 'Gợi ý bài tập AI tạm thời chưa sẵn sàng. Vui lòng thử lại sau.';
  }
  if (lower.contains('play console') ||
      lower.contains('sync_premium') ||
      lower.contains('productid') ||
      lower.contains('purchase token')) {
    return 'Gói Premium tạm thời chưa khả dụng trên cửa hàng. Vui lòng thử lại sau.';
  }
  if (lower.contains('run-all') ||
      lower.contains('sync-rcm') ||
      lower.contains(':5300') ||
      lower.contains(':5057') ||
      lower.contains('gateway')) {
    return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
  }
  if (lower.contains('mongodb') ||
      lower.contains('duplicate key') ||
      lower.contains('e11000') ||
      lower.contains('bulk write') ||
      lower.contains('writeerror')) {
    return 'Dữ liệu đang được đồng bộ. Vui lòng thử lại sau.';
  }
  if (lower.contains('brevo') ||
      lower.contains('email:brevo') ||
      lower.contains('smtp')) {
    return 'Không thể gửi email xác minh lúc này. Vui lòng thử lại sau.';
  }
  if (lower.contains('stack trace') ||
      lower.contains(' at ') ||
      trimmed.length > 280) {
    return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
  }
  return trimmed;
}

String? _bodyMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) return message;
  }
  return null;
}

bool _isAiPath(String path) {
  final p = path.toLowerCase();
  return p.contains('/v1/ai/') || p.contains('/api/v1/ai/');
}

bool _isProfilePath(String path) {
  final p = path.toLowerCase();
  return p.contains('profile') ||
      p.contains('biometrics') ||
      p.contains('onboarding') ||
      p.contains('/me/');
}
