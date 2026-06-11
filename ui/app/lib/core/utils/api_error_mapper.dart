import 'package:dio/dio.dart';

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
      return 'Không thể tải dữ liệu. Dịch vụ Roadmap chưa chạy — hãy khởi động backend (run-all.ps1).';
    }
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Không kết nối được server. Hãy chạy backend (Gateway :5057).';
    }
    return error.message ?? 'Request failed.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
