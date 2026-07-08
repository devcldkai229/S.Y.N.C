import 'dart:convert';

enum CynMessageRole { user, cyn, system }

class CynChatMessage {
  const CynChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.time,
    this.isStreaming = false,
    this.read = false,
    this.pendingAction,
    this.handoffLabel,
    this.error = false,
  });

  final String id;
  final CynMessageRole role;
  final String text;
  final String? time;
  final bool isStreaming;
  final bool read;
  final Map<String, dynamic>? pendingAction;
  final String? handoffLabel;
  final bool error;

  CynChatMessage copyWith({
    String? id,
    CynMessageRole? role,
    String? text,
    String? time,
    bool? isStreaming,
    bool? read,
    Map<String, dynamic>? pendingAction,
    String? handoffLabel,
    bool? error,
    bool clearPendingAction = false,
    bool clearHandoff = false,
  }) {
    return CynChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      time: time ?? this.time,
      isStreaming: isStreaming ?? this.isStreaming,
      read: read ?? this.read,
      pendingAction: clearPendingAction ? null : (pendingAction ?? this.pendingAction),
      handoffLabel: clearHandoff ? null : (handoffLabel ?? this.handoffLabel),
      error: error ?? this.error,
    );
  }
}

class CynAiStreamEvent {
  const CynAiStreamEvent._(this.type, this.data);

  final String type;
  final String data;

  factory CynAiStreamEvent.token(String chunk) => CynAiStreamEvent._('token', chunk);
  factory CynAiStreamEvent.done() => const CynAiStreamEvent._('done', '[DONE]');
  factory CynAiStreamEvent.error(String message) => CynAiStreamEvent._('error', message);
  factory CynAiStreamEvent.finalPayload(String json) => CynAiStreamEvent._('final', json);
  factory CynAiStreamEvent.raw(String event, String data) => CynAiStreamEvent._(event, data);

  Map<String, dynamic>? get jsonData {
    if (data.isEmpty) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  /// Full reply text from `event: final` or unnamed SSE JSON `{"type":"final","text":...}`.
  String? get finalText {
    final json = jsonData;
    if (json == null) return null;
    final kind = json['type']?.toString();
    if (kind != null && kind != 'final' && !json.containsKey('text')) return null;
    final text = json['text'];
    if (text == null) return null;
    final s = text.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Optional display text from `display_payload` events.
  String? get displayText {
    final json = jsonData;
    if (json == null) return null;
    for (final key in ['text', 'body', 'markdown', 'content', 'message']) {
      final v = json[key];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }
}
