import 'package:flutter_test/flutter_test.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_chat_urls.dart';

void main() {
  test('buildFullChatUrl joins baseUrl and ai chat path', () {
    expect(
      buildFullChatUrl(),
      anyOf(
        contains('/v1/ai/chat'),
        contains('/ai/chat'),
      ),
    );
    expect(buildFullChatUrl(), startsWith('http'));
  });
}
