class AppConfig {
  static const String productionUrl = 'https://ramhis-v2-1.onrender.com';
  static const String apiBaseUrl = '$productionUrl/api';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: apiBaseUrl,
  );

  static const String socketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: productionUrl,
  );

  static const String uploadsBaseUrl = '$productionUrl/uploads';

  static bool get isLocal =>
      baseUrl.contains('10.0.2.2') ||
      baseUrl.contains('localhost') ||
      baseUrl.contains('127.0.0.1');

  static bool get isProduction => baseUrl == apiBaseUrl;
}