import 'dart:convert';

import 'package:sync_app/features/cyn/models/cyn_chat_models.dart';

/// Parses Server-Sent Events from the SYNC AI chat endpoint.
Stream<CynAiStreamEvent> parseAiSseBytes(Stream<List<int>> byteStream) async* {
  var buffer = '';
  try {
    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer += chunk;
      while (true) {
        final sep = _nextEventSeparator(buffer);
        if (sep < 0) break;
        final block = buffer.substring(0, sep);
        buffer = buffer.substring(sep);
        if (buffer.startsWith('\r\n')) {
          buffer = buffer.substring(2);
        } else if (buffer.startsWith('\n')) {
          buffer = buffer.substring(1);
        }
        final event = _parseSseBlock(block);
        if (event != null) yield event;
      }
    }
  } catch (_) {
    // Stream may close with an error (connection reset, etc.)
    // — process any leftover buffer and finish gracefully.
  }
  if (buffer.trim().isNotEmpty) {
    final event = _parseSseBlock(buffer);
    if (event != null) yield event;
  }
}

int _nextEventSeparator(String buffer) {
  final lf = buffer.indexOf('\n\n');
  final crlf = buffer.indexOf('\r\n\r\n');
  if (lf < 0) return crlf;
  if (crlf < 0) return lf;
  return lf < crlf ? lf : crlf;
}

CynAiStreamEvent? _parseSseBlock(String block) {
  final trimmed = block.trim();
  if (trimmed.isEmpty) return null;

  String? eventName;
  final dataLines = <String>[];

  for (final rawLine in trimmed.split('\n')) {
    final line = rawLine.trimRight();
    if (line.isEmpty || line.startsWith(':')) continue;
    if (line.startsWith('event:')) {
      eventName = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      dataLines.add(line.substring(5).trimLeft());
    }
  }

  final data = dataLines.join('\n');

  // Unnamed/default SSE is not display text. Only accept as `final` when JSON
  // explicitly carries type=final (legacy server duplicate). Otherwise ignore.
  if (eventName == null || eventName.isEmpty) {
    final asFinal = _tryFinalEvent(data, requireTypeFinal: true);
    return asFinal;
  }

  switch (eventName) {
    case 'token':
      return CynAiStreamEvent.token(data);
    case 'done':
      return CynAiStreamEvent.done();
    case 'error':
      return CynAiStreamEvent.error(data);
    case 'final':
      return CynAiStreamEvent.finalPayload(data);
    case 'display_payload':
      return CynAiStreamEvent.displayPayload(data);
    default:
      return CynAiStreamEvent.raw(eventName, data);
  }
}

CynAiStreamEvent? _tryFinalEvent(String data, {bool requireTypeFinal = false}) {
  if (data.isEmpty) return null;
  try {
    final decoded = jsonDecode(data);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    final kind = map['type']?.toString();
    if (requireTypeFinal) {
      if (kind == 'final') return CynAiStreamEvent.finalPayload(data);
      return null;
    }
    if (kind == 'final' || map.containsKey('text')) {
      return CynAiStreamEvent.finalPayload(data);
    }
  } catch (_) {}
  return null;
}
