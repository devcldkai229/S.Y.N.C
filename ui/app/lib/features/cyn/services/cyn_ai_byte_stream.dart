import 'package:dio/dio.dart';

import 'cyn_ai_byte_stream_io.dart'
    if (dart.library.js) 'cyn_ai_byte_stream_web.dart';

/// HTTP result for SSE chat — success carries a byte stream; failure carries body text.
class CynAiChatStreamResponse {
  const CynAiChatStreamResponse.ok(this.byteStream)
      : statusCode = 200,
        errorBody = null;

  const CynAiChatStreamResponse.fail(this.statusCode, this.errorBody)
      : byteStream = null;

  final int statusCode;
  final Stream<List<int>>? byteStream;
  final String? errorBody;

  bool get isOk => statusCode >= 200 && statusCode < 400 && byteStream != null;
}

Future<CynAiChatStreamResponse> openChatSseByteStream({
  required Dio dio,
  required String url,
  required String token,
  required Map<String, dynamic> body,
  CancelToken? cancelToken,
}) =>
    openChatSseByteStreamImpl(
      dio: dio,
      url: url,
      token: token,
      body: body,
      cancelToken: cancelToken,
    );
