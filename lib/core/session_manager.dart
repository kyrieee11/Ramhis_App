import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

class AuthSession {
  static const String baseUrl = AppConfig.baseUrl;

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userKey = 'auth_user';

  static String? accessToken;
  static String? refreshToken;
  static Map<String, dynamic>? currentUser;

  // ── Save session ────────────────────────────────────────────────────────────
  static Future<void> saveSession({
    required String access,
    required String refresh,
    required Map<String, dynamic> user,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    currentUser = user;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // ── Restore session ─────────────────────────────────────────────────────────
  static Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    accessToken = prefs.getString(_accessTokenKey);
    refreshToken = prefs.getString(_refreshTokenKey);

    final rawUser = prefs.getString(_userKey);

    if (rawUser != null) {
      currentUser = jsonDecode(rawUser);
    }
  }

  // ── Update tokens ───────────────────────────────────────────────────────────
  static Future<void> updateTokens({
    required String access,
    required String refresh,
  }) async {
    accessToken = access;
    refreshToken = refresh;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  // ── Auth headers ────────────────────────────────────────────────────────────
  static Map<String, String> headers() {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null)
        'Authorization': 'Bearer $accessToken',
    };
  }

  // ── Refresh access token ────────────────────────────────────────────────────
  static Future<bool> refreshSession() async {
    try {
      if (refreshToken == null || refreshToken!.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      await updateTokens(
        access: data['accessToken'],
        refresh: data['refreshToken'],
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers(),
      );
    } catch (_) {}

    await clearSession();
  }

  // ── Clear session safely ────────────────────────────────────────────────────
  static Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    currentUser = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // ── Login state ─────────────────────────────────────────────────────────────
  static bool get isLoggedIn {
    return accessToken != null && accessToken!.isNotEmpty;
  }

  static Map<String, dynamic>? get user => null;

  static Future<dynamic> login({required String email, required String password}) async {}

  static Future<void> fetchMe() async {}
}