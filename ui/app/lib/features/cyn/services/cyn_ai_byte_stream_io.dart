import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

  // Buffer chunks first so OkHttp/Dio "connection closed" after SSE done
  // does not surface as an empty stream to the parser.
  final safeStream = _collectThenReplay(streamBody.stream);
  return CynAiChatStreamResponse.ok(safeStream);
}

Stream<Uint8List> _collectThenReplay(Stream<Uint8List> source) async* {
  final chunks = <Uint8List>[];
  try {
    await for (final chunk in source) {
      if (chunk.isNotEmpty) chunks.add(chunk);
    }
  } catch (error) {
    final msg = error.toString().toLowerCase();
    final isNormalClose = msg.contains('connection closed') ||
        msg.contains('connection reset') ||
        msg.contains('software caused connection abort') ||
        msg.contains('broken pipe') ||
        msg.contains('stream has already been listened') ||
        msg.contains('http exception');
    if (!isNormalClose) rethrow;
  }

  for (final chunk in chunks) {
    yield chunk;
  }
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
