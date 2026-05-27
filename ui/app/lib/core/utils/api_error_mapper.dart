import 'package:dio/dio.dart';

String mapApiError(Object error) {
  if (error is DioException) {
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
