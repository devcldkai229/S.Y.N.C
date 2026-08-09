import 'package:flutter_test/flutter_test.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';

void main() {
  test('AWS signed private story URL rewrites to Gateway media proxy', () {
    const signed =
        'https://sync-private-assets.s3.ap-southeast-1.amazonaws.com/stories/abc123.jpg'
        '?X-Amz-Algorithm=AWS4-HMAC-SHA256'
        '&X-Amz-Credential=AKIA%2F20260101%2Fapsoutheast1%2Fs3%2Faws4_request'
        '&X-Amz-Date=20260101T000000Z'
        '&X-Amz-Expires=3600'
        '&X-Amz-SignedHeaders=host'
        '&X-Amz-Signature=deadbeef';

    final resolved = MediaUrlResolver.resolve(signed);
    expect(resolved, isNotNull);
    expect(resolved!.contains('amazonaws.com'), isFalse);
    expect(resolved.contains('X-Amz-Signature'), isFalse);
    expect(
      resolved.endsWith('/api/v1/media/sync-private-assets/stories/abc123.jpg'),
      isTrue,
    );
  });

  test('randomavatar and unsplash stay unchanged', () {
    expect(
      MediaUrlResolver.resolve('randomavatar:user@example.com'),
      'randomavatar:user@example.com',
    );
    const unsplash = 'https://images.unsplash.com/photo-1?w=800';
    expect(MediaUrlResolver.resolve(unsplash), unsplash);
  });

  test('path-style S3 signed URL extracts bucket/key', () {
    const signed =
        'https://s3.ap-southeast-1.amazonaws.com/sync-private-assets/stories/vid.mp4'
        '?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=abc';

    final resolved = MediaUrlResolver.resolve(signed)!;
    expect(
      resolved.endsWith('/api/v1/media/sync-private-assets/stories/vid.mp4'),
      isTrue,
    );
  });
}
