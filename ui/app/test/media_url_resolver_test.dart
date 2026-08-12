import 'package:flutter_test/flutter_test.dart';
import 'package:sync_app/core/utils/exercise_media_url_resolver.dart';
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

  test('public S3 URL rewrites to CDN not S3', () {
    const s3 =
        'https://sync-pub-assets.s3.ap-southeast-1.amazonaws.com/prod/3-4-sit-up/0.webp';
    expect(
      MediaUrlResolver.resolve(s3),
      'https://cdn.synctis.in/prod/3-4-sit-up/0.webp',
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

  test('exercise prod key resolves to CDN', () {
    expect(
      ExerciseMediaUrlResolver.resolve('prod/90-90-hamstring/0.webp'),
      'https://cdn.synctis.in/prod/90-90-hamstring/0.webp',
    );
  });

  test('exercise localhost media proxy path rewrites prod key to CDN', () {
    expect(
      ExerciseMediaUrlResolver.resolve(
        'http://localhost:5057/api/v1/exercise/exercises/media/prod/3-4-sit-up/0.webp',
      ),
      'https://cdn.synctis.in/prod/3-4-sit-up/0.webp',
    );
  });

  test('exercise CDN url stays CDN', () {
    const cdn = 'https://cdn.synctis.in/prod/ab-crunch-machine/0.webp';
    expect(ExerciseMediaUrlResolver.resolve(cdn), cdn);
  });

  test('legacy catalog key uses gateway media proxy', () {
    final resolved = ExerciseMediaUrlResolver.resolve('exercises_catalog/foo/0.webp')!;
    expect(resolved.contains('/api/v1/exercise/exercises/media/exercises_catalog/foo/0.webp'), isTrue);
    expect(resolved.startsWith('http'), isTrue);
  });
}
