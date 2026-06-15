import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';

/// Rewrites exercise S3/MinIO URLs to Gateway proxies the Flutter client can load.
abstract final class ExerciseMediaUrlResolver {
  static String? resolve(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    final viaMedia = MediaUrlResolver.resolve(trimmed);
    if (viaMedia != null && viaMedia != trimmed) return viaMedia;

    final key = _extractExerciseObjectKey(trimmed);
    if (key != null) {
      return '${_gatewayOrigin()}/api/v1/exercise/exercises/media/$key';
    }

    return trimmed;
  }

  static String? _extractExerciseObjectKey(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return url.replaceFirst(RegExp(r'^/+'), '');
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final path = uri.path.replaceFirst(RegExp(r'^/+'), '');
    var catalogIdx = path.indexOf('exercises_catalog/');
    if (catalogIdx >= 0) {
      return path.substring(catalogIdx);
    }

    catalogIdx = path.indexOf('exercises/');
    if (catalogIdx >= 0) {
      return path.substring(catalogIdx);
    }

    return null;
  }

  static String _gatewayOrigin() {
    final base = AppConfig.baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }
}
