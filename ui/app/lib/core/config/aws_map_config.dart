/// AWS Location Service map configuration.
///
/// Grab / named maps (v0): MapLibre + style-descriptor URL.
/// AWS standard styles (v2): MapLibre + /v2/styles/{style}/descriptor
///
/// **Important:** use `--dart-define=AWS_MAP_API_KEY=...` or
/// `--dart-define-from-file=dart_defines.aws.json` (see scripts/run-chrome.ps1).
///
/// API key must be associated with **Map resource** `sync-map` on AWS Console
/// (actions: GetStyleDescriptor + GetTile). Route-calculator keys will not work.
abstract final class AwsMapConfig {
  static const String region = String.fromEnvironment(
    'AWS_MAP_REGION',
    defaultValue: 'ap-southeast-1',
  );

  static const String apiKey = String.fromEnvironment(
    'AWS_MAP_API_KEY',
    defaultValue: '',
  );

  /// Named Grab/custom map (v0). Leave empty to use [style] v2 instead.
  static const String mapName = String.fromEnvironment(
    'AWS_MAP_NAME',
    defaultValue: 'sync-map',
  );

  /// v2 style when [mapName] is empty: Standard, Hybrid, Satellite, Monochrome.
  static const String style = String.fromEnvironment(
    'AWS_MAP_STYLE',
    defaultValue: 'Hybrid',
  );

  static bool get isConfigured => apiKey.isNotEmpty;

  /// MapLibre vector map via AWS (Grab named map or v2 style).
  static bool get usesVectorMap =>
      isConfigured && (mapName.isNotEmpty || style.isNotEmpty);

  /// MapLibre style URL — matches AWS console HTML sample.
  static String? get styleDescriptorUrl {
    if (!isConfigured) return null;

    if (mapName.isNotEmpty) {
      return 'https://maps.geo.$region.amazonaws.com/maps/v0/maps/$mapName/style-descriptor?key=$apiKey';
    }

    return 'https://maps.geo.$region.amazonaws.com/v2/styles/$style/descriptor?key=$apiKey';
  }

  /// Raster Esri tiles (legacy flutter_map only — not for Grab maps).
  static String? get rasterTileUrlTemplate {
    if (!isConfigured || usesVectorMap) return null;
    return 'https://maps.geo.$region.amazonaws.com/v2/styles/$style/tiles/{z}/{x}/{y}?key=$apiKey';
  }

  static const String fallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const double defaultLat = 10.7769;
  static const double defaultLng = 106.7009;
  static const double defaultZoom = 12;
}
