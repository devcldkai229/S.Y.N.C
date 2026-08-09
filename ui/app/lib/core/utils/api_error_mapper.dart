import 'package:dio/dio.dart';
import 'package:sync_app/core/network/dio_errors.dart';

String mapApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final path = error.requestOptions.path;
    final bodyMessage = _bodyMessage(error);

    if (status == 404) {
      if (_isAiPath(path)) {
        return bodyMessage ??
            'Không tìm thấy API AI. Kiểm tra Gateway đã route /ai/workout → sync-rcm-service (:5300) và service đang chạy.';
      }
      if (_isProfilePath(path)) {
        return bodyMessage ??
            'Không tìm thấy dữ liệu hồ sơ. Hãy hoàn tất onboarding hoặc thử lại sau.';
      }
      return bodyMessage ?? 'Không tìm thấy tài nguyên (404).';
    }
    if (status == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (status == 502 || status == 503) {
      if (_isAiPath(path)) {
        return bodyMessage ??
            'sync-rcm-service chưa sẵn sàng. Chạy .\\scripts\\run-all.ps1 --rcm (port 5300).';
      }
      return 'Không thể tải dữ liệu. Một số dịch vụ backend chưa chạy — hãy chạy run-all.ps1.';
    }
    if (isConnectivityDioError(error)) {
      return 'Không kết nối được server hoặc phản hồi quá chậm. Hãy chạy backend (Gateway :5057).';
    }
    if (bodyMessage != null) return bodyMessage;
    return error.message ?? 'Request failed.';
  }
  return error.toString().replaceFirst('Exception: ', '');
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
