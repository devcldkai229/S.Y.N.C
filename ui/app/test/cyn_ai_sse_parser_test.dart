import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sync_app/features/cyn/models/cyn_chat_models.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_sse_parser.dart';

void main() {
  test('parse unnamed SSE final JSON as final event', () async {
    const block = 'data: {"type":"final","text":"Xin chào"}\n\n';
    final events = await parseAiSseBytes(Stream.value(utf8.encode(block))).toList();

    expect(events, hasLength(1));
    expect(events.first.type, 'final');
    expect(events.first.finalText, 'Xin chào');
  });

  test('parse event final with JSON payload', () async {
    const block = 'event: final\ndata: {"type":"final","text":"Coach reply"}\n\n';
    final events = await parseAiSseBytes(Stream.value(utf8.encode(block))).toList();

    expect(events, hasLength(1));
    expect(events.first.type, 'final');
    expect(events.first.finalText, 'Coach reply');
  });

  test('parse event token chunk', () async {
    const block = 'event: token\ndata: Chào \n\n';
    final events = await parseAiSseBytes(Stream.value(utf8.encode(block))).toList();

    expect(events, hasLength(1));
    expect(events.first.type, 'token');
    expect(events.first.data, 'Chào');
  });

  test('parse plain-text message as token fallback', () async {
    const block = 'data: Xin chào\n\n';
    final events = await parseAiSseBytes(Stream.value(utf8.encode(block))).toList();

    expect(events, hasLength(1));
    expect(events.first.type, 'token');
    expect(events.first.data, 'Xin chào');
  });

  test('parse token stream then final and done', () async {
    const streamBody =
        'event: token\ndata: Chào \n\n'
        'event: token\ndata: bạn!\n\n'
        'event: final\ndata: {"type":"final","text":"Chào bạn!"}\n\n'
        'event: done\ndata: [DONE]\n\n';
    final events = await parseAiSseBytes(Stream.value(utf8.encode(streamBody))).toList();

    expect(events, hasLength(4));
    expect(events[0].type, 'token');
    expect(events[0].data, 'Chào');
    expect(events[1].type, 'token');
    expect(events[1].data, 'bạn!');
    expect(events[2].type, 'final');
    expect(events[2].finalText, 'Chào bạn!');
    expect(events[3].type, 'done');
  });

  test('displayText extracts body from display_payload', () {
    final ev = CynAiStreamEvent.raw(
      'display_payload',
      '{"body":"Hi there","kind":"card"}',
    );
    expect(ev.displayText, 'Hi there');
  });
}
