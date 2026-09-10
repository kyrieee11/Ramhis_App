class AppConfig {
  // ============================================================
  // LOCAL BACKEND
  // Android Emulator -> your PC localhost
  // ============================================================

  static const String localUrl =
      'http://10.0.2.2:5000';

  static const String localApiBaseUrl =
      '$localUrl/api';

  // ============================================================
  // PRODUCTION BACKEND
  // ============================================================

  static const String productionUrl =
      'https://ramhis-v2-1.onrender.com';

  static const String productionApiBaseUrl =
      '$productionUrl/api';

  // ============================================================
  // CURRENT BACKEND
  // PRODUCTION
  // ============================================================

  static const String apiBaseUrl =
      productionApiBaseUrl;

  static const String baseUrl =
      apiBaseUrl;

  // ============================================================
  // SOCKET.IO
  // PRODUCTION
  // ============================================================

  static const String socketBaseUrl =
      productionUrl;

  // ============================================================
  // UPLOADED FILES
  // PRODUCTION
  // ============================================================

  static const String uploadsBaseUrl =
      '$productionUrl/uploads';

  // ============================================================
  // ENVIRONMENT STATUS
  // ============================================================

  static bool get isLocal => false;

  static bool get isProduction => true;
}