class AppConfig {
  static const String productionUrl =
      'http://10.0.2.2:5000';

  static const String apiBaseUrl =
      '$productionUrl/api';

  static const String baseUrl =
      apiBaseUrl;

  static const String socketBaseUrl =
      productionUrl;

  static const String uploadsBaseUrl =
      '$productionUrl/uploads';

  static bool get isLocal => true;

  static bool get isProduction => false;
}