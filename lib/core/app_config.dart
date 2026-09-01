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
  // Keep this because other files in the app still reference it.
  // ============================================================

  static const String productionUrl =
      'https://ramhis-v2-1.onrender.com';

  static const String productionApiBaseUrl =
      '$productionUrl/api';

  // ============================================================
  // CURRENT BACKEND
  // ============================================================

  static const String apiBaseUrl =
      localApiBaseUrl;

  static const String baseUrl =
      apiBaseUrl;

  // Socket.IO
  static const String socketBaseUrl =
      localUrl;

  // Uploaded files
  static const String uploadsBaseUrl =
      '$localUrl/uploads';

  // Environment status
  static bool get isLocal => true;

  static bool get isProduction => false;
}