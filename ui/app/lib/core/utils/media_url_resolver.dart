import 'package:sync_app/core/config/app_config.dart';

/// Rewrites S3 / MinIO / legacy CDN media URLs to the Gateway media proxy.
abstract final class MediaUrlResolver {
  static const publicBucket = 'sync-public-assets';
  static const privateBucket = 'sync-private-assets';
  static const _legacyBuckets = ['social-assets', 'sync-objs'];
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
    if (trimmed.startsWith(proxiedPrefix)) return trimmed;

    final objectPath = _extractObjectPath(trimmed);
    if (objectPath != null) {
      return '$proxiedPrefix$objectPath';
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return '$proxiedPrefix$publicBucket/${trimmed.replaceFirst(RegExp(r'^/+'), '')}';
    }

    return trimmed;
  }

  static String _gatewayOrigin() {
    final base = AppConfig.baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  static String? _extractObjectPath(String url) {
    for (final bucket in [publicBucket, privateBucket]) {
      final bucketSegment = '/$bucket/';
      final bucketIndex = url.indexOf(bucketSegment);
      if (bucketIndex >= 0) {
        return '$bucket/${url.substring(bucketIndex + bucketSegment.length)}';
      }
    }

    for (final legacy in _legacyBuckets) {
      final bucketSegment = '/$legacy/';
      final bucketIndex = url.indexOf(bucketSegment);
      if (bucketIndex >= 0) {
        final suffix = url.substring(bucketIndex + bucketSegment.length);
        return '$publicBucket/$suffix';
      }
    }

    final legacyMarker = '$_legacyCdnHost/';
    final legacyIndex = url.indexOf(legacyMarker);
    if (legacyIndex >= 0) {
      final key = url.substring(legacyIndex + legacyMarker.length);
      return '$publicBucket/$key';
    }

    return null;
  }
}
