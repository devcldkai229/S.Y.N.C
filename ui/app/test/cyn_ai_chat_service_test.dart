import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sync_app/features/cyn/models/cyn_chat_models.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_sse_parser.dart';

void main() {
  test('parseAiSseBytes yields token and final from mock byte stream', () async {
    const body =
        'event: token\ndata: Xin \n\n'
        'event: token\ndata: chào\n\n'
        'event: final\ndata: {"type":"final","text":"Xin chào"}\n\n'
        'event: done\ndata: [DONE]\n\n';

    final events = await parseAiSseBytes(
      Stream.value(utf8.encode(body)),
    ).toList();

    expect(events.where((e) => e.type == 'token').length, 2);
    expect(events.where((e) => e.type == 'final').single.finalText, 'Xin chào');
    expect(events.where((e) => e.type == 'done').length, 1);
  });

  test('CynAiStreamEvent.finalText parses backend payload', () {
    final ev = CynAiStreamEvent.finalPayload(
      '{"type":"final","text":"Coach reply","intent":"coach"}',
    );
    expect(ev.finalText, 'Coach reply');
  });
}
