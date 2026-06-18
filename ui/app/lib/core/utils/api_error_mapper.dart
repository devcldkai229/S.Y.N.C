import 'package:dio/dio.dart';
import 'package:sync_app/core/network/dio_errors.dart';

String mapApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 404) {
      return 'Không tìm thấy dữ liệu hồ sơ. Hãy hoàn tất onboarding hoặc thử lại sau.';
    }
    if (status == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (status == 502 || status == 503) {
      return 'Không thể tải dữ liệu. Một số dịch vụ backend chưa chạy — hãy chạy run-all.ps1.';
    }
    if (isConnectivityDioError(error)) {
      return 'Không kết nối được server hoặc phản hồi quá chậm. Hãy chạy backend (Gateway :5057).';
    }
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return error.message ?? 'Request failed.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
