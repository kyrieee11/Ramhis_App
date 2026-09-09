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
  // LOCAL
  // ============================================================

  static const String apiBaseUrl =
      localApiBaseUrl;

  static const String baseUrl =
      apiBaseUrl;

  // ============================================================
  // SOCKET.IO
  // LOCAL
  // ============================================================

  static const String socketBaseUrl =
      localUrl;

  // ============================================================
  // UPLOADED FILES
  // LOCAL
  // ============================================================

  static const String uploadsBaseUrl =
      '$localUrl/uploads';

  // ============================================================
  // ENVIRONMENT STATUS
  // ============================================================

  static bool get isLocal => true;

  static bool get isProduction => false;
}