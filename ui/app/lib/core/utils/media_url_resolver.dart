import 'package:sync_app/core/config/app_config.dart';

/// Rewrites S3 / legacy media URLs for the Flutter client.
///
/// - **Private** objects (signed / private bucket) → Gateway `/api/v1/media/...`
/// - **Public** bucket (`sync-pub-assets`) without signature → CDN (`AppConfig.mediaCdnBaseUrl`)
abstract final class MediaUrlResolver {
  static const publicBucket = 'sync-pub-assets';
  static const privateBucket = 'sync-private-assets';
  static const _legacyBuckets = ['social-assets', 'sync-objs', 'sync-public-assets'];
  static const _legacyCdnHost = 'cdn.sync.local';

  /// Returns a client-reachable URL, or [url] unchanged when already external.
  static String? resolve(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('randomavatar:')) return trimmed;
    if (trimmed.startsWith('assets/')) return trimmed;

    // Public CDN — leave alone.
    final cdnBase = AppConfig.mediaCdnBaseUrl;
    if (cdnBase.isNotEmpty) {
      final cdnHost = Uri.tryParse(cdnBase)?.host;
      final uri = Uri.tryParse(trimmed);
      if (cdnHost != null &&
          uri != null &&
          uri.host.toLowerCase() == cdnHost.toLowerCase()) {
        final q = trimmed.indexOf('?');
        return q >= 0 ? trimmed.substring(0, q) : trimmed;
      }
      if (uri != null &&
          (uri.host.toLowerCase() == 'cdn.synctis.in' ||
              uri.host.toLowerCase().endsWith('.cloudfront.net'))) {
        final q = trimmed.indexOf('?');
        return q >= 0 ? trimmed.substring(0, q) : trimmed;
      }
    }

    final origin = _gatewayOrigin();
    final proxiedPrefix = '$origin/api/v1/media/';
    if (trimmed.startsWith(proxiedPrefix)) {
      final q = trimmed.indexOf('?');
      return q >= 0 ? trimmed.substring(0, q) : trimmed;
    }

    // Private-bucket AWS signed URLs → Gateway proxy (CORS + stable Content-Type).
    if (_isAwsPresignedUrl(trimmed)) {
      final objectPath = _extractObjectPath(trimmed);
      if (objectPath != null) {
        // Public bucket signed → strip to CDN when available.
        if (cdnBase.isNotEmpty && objectPath.startsWith('$publicBucket/')) {
          final key = objectPath.substring(publicBucket.length + 1);
          return '$cdnBase/$key';
        }
        return '$proxiedPrefix$objectPath';
      }
      return trimmed;
    }

    final objectPath = _extractObjectPath(trimmed);
    if (objectPath != null) {
      // Public assets serve via CloudFront (S3 direct is 403 with OAC).
      if (cdnBase.isNotEmpty && objectPath.startsWith('$publicBucket/')) {
        final key = objectPath.substring(publicBucket.length + 1);
        return '$cdnBase/$key';
      }
      return '$proxiedPrefix$objectPath';
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final key = trimmed.replaceFirst(RegExp(r'^/+'), '');
      // Bare env-prefixed keys (exercise catalog, marketing banners).
      if (cdnBase.isNotEmpty && (key.startsWith('prod/') || key.startsWith('dev/'))) {
        return '$cdnBase/$key';
      }
      return '$proxiedPrefix$publicBucket/$key';
    }

    return trimmed;
  }

  static bool _isAwsPresignedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('amazonaws.com')) return false;
    final params = uri.queryParameters;
    return params.containsKey('X-Amz-Signature') ||
        params.containsKey('X-Amz-Algorithm') ||
        params.containsKey('X-Amz-Credential');
  }

  static String _gatewayOrigin() {
    final base = AppConfig.baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  /// Returns `{bucket}/{key}` without query string, or null when unknown.
  static String? _extractObjectPath(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.contains('amazonaws.com')) {
      final host = uri.host;
      final objectKey = uri.path.replaceFirst(RegExp(r'^/+'), '');

      final s3Marker = '.s3';
      final s3Index = host.indexOf(s3Marker);
      if (s3Index > 0 && objectKey.isNotEmpty) {
        final bucket = host.substring(0, s3Index);
        return '$bucket/$objectKey';
      }

      if ((host.startsWith('s3.') || host.startsWith('s3-')) && objectKey.contains('/')) {
        return objectKey;
      }
    }

    final withoutQuery = url.split('?').first;

    for (final bucket in [publicBucket, privateBucket]) {
      final bucketSegment = '/$bucket/';
      final bucketIndex = withoutQuery.indexOf(bucketSegment);
      if (bucketIndex >= 0) {
        return '$bucket/${withoutQuery.substring(bucketIndex + bucketSegment.length)}';
      }
    }

    for (final legacy in _legacyBuckets) {
      final bucketSegment = '/$legacy/';
      final bucketIndex = withoutQuery.indexOf(bucketSegment);
      if (bucketIndex >= 0) {
        final suffix = withoutQuery.substring(bucketIndex + bucketSegment.length);
        return '$publicBucket/$suffix';
      }
    }

    final legacyMarker = '$_legacyCdnHost/';
    final legacyIndex = withoutQuery.indexOf(legacyMarker);
    if (legacyIndex >= 0) {
      final key = withoutQuery.substring(legacyIndex + legacyMarker.length);
      return '$publicBucket/$key';
    }

    return null;
  }
}
