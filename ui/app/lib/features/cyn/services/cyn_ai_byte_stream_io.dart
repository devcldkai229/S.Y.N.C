import 'dart:convert';

import 'package:dio/dio.dart';

import 'cyn_ai_byte_stream.dart';

Future<CynAiChatStreamResponse> openChatSseByteStreamImpl({
  required Dio dio,
  required String url,
  required String token,
  required Map<String, dynamic> body,
  CancelToken? cancelToken,
}) async {
  final response = await dio.post<ResponseBody>(
    url,
    data: body,
    cancelToken: cancelToken,
    options: Options(
      responseType: ResponseType.stream,
      headers: {
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $token',
      },
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  final status = response.statusCode ?? 0;
  if (status >= 400) {
    final detail = await _readStreamError(response.data);
    return CynAiChatStreamResponse.fail(status, detail ?? 'HTTP $status');
  }

  final streamBody = response.data;
  if (streamBody == null) {
    return const CynAiChatStreamResponse.fail(502, 'Phản hồi trống từ máy chủ AI.');
  }

  // Wrap the stream to gracefully handle the server closing the connection
  // after the SSE stream is done (HttpException / SocketException).
  final safeStream = streamBody.stream.handleError(
    (Object error) {
      // Connection-closed errors are normal SSE termination — swallow them.
      final msg = error.toString().toLowerCase();
      if (msg.contains('connection closed') ||
          msg.contains('connection reset') ||
          msg.contains('software caused connection abort') ||
          msg.contains('broken pipe') ||
          msg.contains('stream has already been listened')) {
        return;
      }
      throw error;
    },
  );
  return CynAiChatStreamResponse.ok(safeStream);
}

Future<String?> _readStreamError(ResponseBody? body) async {
  if (body == null) return null;
  try {
    final chunks = await body.stream.toList();
    final text = utf8.decode(chunks.expand((c) => c).toList(), allowMalformed: true).trim();
    if (text.isEmpty) return null;
    try {
      final json = jsonDecode(text);
      if (json is Map) {
        return (json['detail'] ?? json['message'] ?? text).toString();
      }
    } catch (_) {}
    return text;
  } catch (_) {
    return null;
  }
}
