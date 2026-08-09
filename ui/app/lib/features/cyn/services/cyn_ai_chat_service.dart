import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/cyn/models/cyn_chat_models.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_byte_stream.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_chat_urls.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_sse_parser.dart';

class CynAiChatService {
  CynAiChatService(this._dio, this._auth);

  final Dio _dio;
  final AuthService _auth;

  /// Stream SSE events from AI chat (`Gateway` hoặc trực tiếp `:8088` nếu có `AI_BASE_URL`).
  Stream<CynAiStreamEvent> streamChat({
    required String message,
    required String sessionId,
    String locale = 'vi',
    double? latitude,
    double? longitude,
    String? timezone,
    CancelToken? cancelToken,
  }) async* {
    final token = await _auth.getValidAccessToken();
    if (token == null || token.isEmpty) {
      yield CynAiStreamEvent.error('Bạn cần đăng nhập để chat với CYN.');
      return;
    }

    final payload = <String, dynamic>{
      'message': message,
      'session_id': sessionId,
      'locale': locale,
      'client_platform': AppConfig.clientPlatform,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
    };

    final CynAiChatStreamResponse httpResult;
    try {
      httpResult = await openChatSseByteStream(
        dio: _dio,
        url: buildFullChatUrl(),
        token: token,
        body: payload,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      yield CynAiStreamEvent.error(await _describeDioError(e));
      return;
    } catch (e) {
      yield CynAiStreamEvent.error('Không kết nối được CYN AI: $e');
      return;
    }

    if (!httpResult.isOk) {
      yield CynAiStreamEvent.error(
        _formatHttpError(httpResult.statusCode, httpResult.errorBody ?? 'HTTP ${httpResult.statusCode}'),
      );
      return;
    }

    yield* parseAiSseBytes(httpResult.byteStream!);
  }

  Future<Map<String, dynamic>> confirmAction({
    required String sessionId,
    required String actionId,
    bool confirmed = true,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _requestConfirmUrl(),
      data: {
        'session_id': sessionId,
        'action_id': actionId,
        'confirmed': confirmed,
        'client_platform': AppConfig.clientPlatform,
      },
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  String _requestConfirmUrl() => AppConfig.aiUsesDirectService
      ? '${AppConfig.aiBaseUrl}${AppConfig.aiChatConfirmPath}'
      : AppConfig.aiChatConfirmPath;

  Future<String> _describeDioError(DioException error) async {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (data is ResponseBody) {
      final chunks = await data.stream.toList();
      final text = String.fromCharCodes(chunks.expand((c) => c));
      if (text.isNotEmpty) return _formatHttpError(status, text);
    }

    if (data is Map) {
      final detail = data['detail'] ?? data['message'] ?? data.toString();
      return _formatHttpError(status, detail.toString());
    }

    if (data != null) {
      return _formatHttpError(status, data.toString());
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      final target = AppConfig.aiUsesDirectService
          ? 'AI service (${AppConfig.aiBaseUrl})'
          : 'Gateway (${AppConfig.baseUrl})';
      return 'Không kết nối được $target. Kiểm tra máy dev đang chạy service và IP LAN đúng.';
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return 'CYN phản hồi quá lâu. Thử lại hoặc kiểm tra Ollama/LLM backend.';
    }

    return error.message ?? 'Không kết nối được CYN AI';
  }

  String _formatHttpError(int? status, String detail) {
    if (status == 401) return 'Phiên đăng nhập hết hạn. Đăng nhập lại để chat với CYN.';
    if (status == 404) {
      return AppConfig.aiUsesDirectService
          ? 'Không tìm thấy endpoint AI ($detail).'
          : 'Gateway chưa route /v1/ai → sync-agent-service. Kiểm tra appsettings.json (ai-route).';
    }
    if (status == 502 || status == 503) {
      return 'AI service chưa sẵn sàng (HTTP $status). Chạy sync-agent-service trên :8088.';
    }
    if (status != null) return 'HTTP $status: $detail';
    return detail;
  }
}
