import 'package:sync_app/core/config/app_config.dart';

/// Rewrites S3 / legacy CDN media URLs to the Gateway media proxy.
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

    final origin = _gatewayOrigin();
    final proxiedPrefix = '$origin/api/v1/media/';
    if (trimmed.startsWith(proxiedPrefix)) {
      // Drop query if any (e.g. accidental signature on gateway URL).
      final q = trimmed.indexOf('?');
      return q >= 0 ? trimmed.substring(0, q) : trimmed;
    }

    // Private-bucket AWS signed URLs → Gateway proxy (CORS + stable Content-Type).
    // Fall back to the signed URL only when the object path cannot be recovered.
    if (_isAwsPresignedUrl(trimmed)) {
      final objectPath = _extractObjectPath(trimmed);
      if (objectPath != null) return '$proxiedPrefix$objectPath';
      return trimmed;
    }

    final objectPath = _extractObjectPath(trimmed);
    if (objectPath != null) {
      return '$proxiedPrefix$objectPath';
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return '$proxiedPrefix$publicBucket/${trimmed.replaceFirst(RegExp(r'^/+'), '')}';
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
      // uri.path excludes query — safe for signed URLs.
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
