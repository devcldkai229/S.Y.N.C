class AppConfig {
  static const String appName = 'Sync Lifestyle';
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:5000',
  );
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}
