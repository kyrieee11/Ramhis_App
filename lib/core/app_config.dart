class AppConfig {
  static const String productionUrl =
      'https://ramhis-v2-1.onrender.com';

  static const String apiBaseUrl =
      '$productionUrl/api';

  static const String baseUrl =
      apiBaseUrl;

  static const String socketBaseUrl =
      productionUrl;

  static const String uploadsBaseUrl =
      '$productionUrl/uploads';

  static bool get isLocal => false;

  static bool get isProduction => true;
}