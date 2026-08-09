import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart' as http;

import 'cyn_ai_byte_stream.dart';

Future<CynAiChatStreamResponse> openChatSseByteStreamImpl({
  required Dio dio,
  required String url,
  required String token,
  required Map<String, dynamic> body,
  CancelToken? cancelToken,
}) async {
  final client = FetchClient(mode: RequestMode.cors);
  final request = http.Request('POST', Uri.parse(url))
    ..headers['Accept'] = 'text/event-stream'
    ..headers['Authorization'] = 'Bearer $token'
    ..headers['Content-Type'] = 'application/json'
    ..body = jsonEncode(body);

  final http.StreamedResponse streamed;
  try {
    streamed = await client.send(request);
  } catch (_) {
    client.close();
    rethrow;
  }

  if (streamed.statusCode >= 400) {
    try {
      final detail = await streamed.stream.bytesToString();
      var message = detail.trim().isEmpty ? 'HTTP ${streamed.statusCode}' : detail.trim();
      try {
        final json = jsonDecode(detail);
        if (json is Map) {
          message = (json['detail'] ?? json['message'] ?? detail).toString();
        }
      } catch (_) {}
      return CynAiChatStreamResponse.fail(streamed.statusCode, message);
    } finally {
      client.close();
    }
  }

  // Wrap the stream so the client is closed when the stream ends or errors.
  final wrappedStream = streamed.stream.handleError(
    (Object e) { client.close(); throw e; },
  ).transform(
    StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleDone: (sink) { client.close(); sink.close(); },
    ),
  );
  return CynAiChatStreamResponse.ok(wrappedStream);
}
