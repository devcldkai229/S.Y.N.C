import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';

/// Resolves exercise image/video URLs for Flutter (Play + local).
///
/// Prefers public CDN for env-prefixed keys (`prod/`, `dev/`) so clients do not
/// hit S3 (403) or a loopback media proxy. Local-only keys still use Gateway proxy.
abstract final class ExerciseMediaUrlResolver {
  static String? resolve(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    // Already on public CDN — use as-is.
    if (_isPublicCdnUrl(trimmed)) {
      return _stripQuery(trimmed);
    }

    final key = _extractObjectKey(trimmed);
    if (key != null && key.isNotEmpty) {
      if (_useCdnForKey(key)) {
        return '${AppConfig.mediaCdnBaseUrl}/${key.replaceFirst(RegExp(r'^/+'), '')}';
      }
      // Local / unprefixed keys: Gateway exercise media proxy.
      return '${_gatewayOrigin()}/api/v1/exercise/exercises/media/'
          '${key.replaceFirst(RegExp(r'^/+'), '')}';
    }

    // General media resolver (S3 private signed → gateway; public → CDN).
    final viaMedia = MediaUrlResolver.resolve(trimmed);
    if (viaMedia != null && viaMedia != trimmed) return viaMedia;

    // Loopback absolute URL with unknown shape → remap host to current gateway origin.
    final remapped = _remapLoopbackToGateway(trimmed);
    if (remapped != null) return remapped;

    return trimmed;
  }

  static bool _useCdnForKey(String key) {
    final cdn = AppConfig.mediaCdnBaseUrl;
    if (cdn.isEmpty) return false;
    final k = key.replaceFirst(RegExp(r'^/+'), '');
    // Deployed env prefixes live on CDN (sync-pub-assets + CloudFront).
    return k.startsWith('prod/') || k.startsWith('dev/');
  }

  static bool _isPublicCdnUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    final host = uri.host.toLowerCase();
    final cdnHost = Uri.tryParse(AppConfig.mediaCdnBaseUrl)?.host.toLowerCase();
    if (cdnHost != null && cdnHost.isNotEmpty && host == cdnHost) return true;
    if (host == 'cdn.synctis.in') return true;
    if (host.endsWith('.cloudfront.net')) return true;
    return false;
  }

  /// Prefer full object key (`prod/slug/0.webp`), not nested path noise.
  static String? _extractObjectKey(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return url.replaceFirst(RegExp(r'^/+'), '');
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final path = uri.path.replaceFirst(RegExp(r'^/+'), '');

    // .../exercise/exercises/media/{key} or .../exercises/media/{key}
    final mediaMarkers = <String>[
      'exercise/exercises/media/',
      'exercises/media/',
      'api/v1/media/${MediaUrlResolver.publicBucket}/',
      'api/v1/media/',
    ];
    for (final marker in mediaMarkers) {
      final idx = path.indexOf(marker);
      if (idx >= 0) {
        var key = path.substring(idx + marker.length);
        if (marker == 'api/v1/media/' &&
            key.startsWith('${MediaUrlResolver.publicBucket}/')) {
          key = key.substring(MediaUrlResolver.publicBucket.length + 1);
        }
        if (key.isNotEmpty) return key;
      }
    }

    // S3 virtual-hosted: bucket.s3.region.amazonaws.com/{key}
    if (uri.host.contains('amazonaws.com')) {
      final objectKey = path;
      if (objectKey.isEmpty) return null;
      if (uri.host.startsWith('${MediaUrlResolver.publicBucket}.')) {
        return objectKey;
      }
      // path-style s3.region.amazonaws.com/bucket/key
      if (objectKey.startsWith('${MediaUrlResolver.publicBucket}/')) {
        return objectKey.substring(MediaUrlResolver.publicBucket.length + 1);
      }
    }

    // Legacy catalog prefix somewhere in path
    final catalogIdx = path.indexOf('exercises_catalog/');
    if (catalogIdx >= 0) return path.substring(catalogIdx);

    // Env-prefixed keys exposed as first path segment
    if (path.startsWith('prod/') || path.startsWith('dev/')) {
      return path;
    }

    return null;
  }

  static String? _remapLoopbackToGateway(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;
    if (!_isLoopbackHost(uri.host)) return null;
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    return '${_gatewayOrigin()}$path${uri.hasQuery ? '?${uri.query}' : ''}';
  }

  static bool _isLoopbackHost(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '::1' ||
        h == '0.0.0.0' ||
        h == 'host.docker.internal' ||
        h.startsWith('10.0.2.2'); // Android emulator → host
  }

  static String _stripQuery(String url) {
    final q = url.indexOf('?');
    return q >= 0 ? url.substring(0, q) : url;
  }

  static String _gatewayOrigin() {
    final base = AppConfig.baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }
}
