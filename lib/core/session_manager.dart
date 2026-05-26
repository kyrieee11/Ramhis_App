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

  // ─────────────────────────────────────────────────────────────
  // SAVE SESSION
  // ─────────────────────────────────────────────────────────────

  static Future<void> saveSession({
    required String access,
    required String refresh,
    required Map<String, dynamic> user,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    currentUser = user;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _accessTokenKey,
      access,
    );

    await prefs.setString(
      _refreshTokenKey,
      refresh,
    );

    await prefs.setString(
      _userKey,
      jsonEncode(user),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RESTORE SESSION
  // ─────────────────────────────────────────────────────────────

  static Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    accessToken = prefs.getString(
      _accessTokenKey,
    );

    refreshToken = prefs.getString(
      _refreshTokenKey,
    );

    final rawUser = prefs.getString(_userKey);

    if (rawUser != null && rawUser.isNotEmpty) {
      currentUser = Map<String, dynamic>.from(
        jsonDecode(rawUser),
      );
    }
  }


  // ─────────────────────────────────────────────────────────────
  // UPDATE CURRENT USER
  // ─────────────────────────────────────────────────────────────

  static Future<void> updateCurrentUser(
    Map<String, dynamic> updates,
  ) async {
    final mergedUser = <String, dynamic>{
      ...?currentUser,
      ...updates,
    };

    currentUser = mergedUser;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userKey,
      jsonEncode(mergedUser),
    );
  }

  static Future<void> setCurrentUser(
    Map<String, dynamic> user,
  ) async {
    currentUser = Map<String, dynamic>.from(user);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userKey,
      jsonEncode(currentUser),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE TOKENS
  // ─────────────────────────────────────────────────────────────

  static Future<void> updateTokens({
    required String access,
    required String refresh,
  }) async {
    accessToken = access;
    refreshToken = refresh;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _accessTokenKey,
      access,
    );

    await prefs.setString(
      _refreshTokenKey,
      refresh,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AUTH HEADERS
  // ─────────────────────────────────────────────────────────────

  static Map<String, String> headers() {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken!.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  // ─────────────────────────────────────────────────────────────
  // REFRESH ACCESS TOKEN
  // ─────────────────────────────────────────────────────────────

  static Future<bool> refreshSession() async {
    try {
      if (refreshToken == null || refreshToken!.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/auth/refresh',
        ),
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

      final data = Map<String, dynamic>.from(
        jsonDecode(response.body),
      );

      final newAccess = (data['accessToken'] ?? '').toString();
      final newRefresh = (data['refreshToken'] ?? '').toString();

      if (newAccess.isEmpty || newRefresh.isEmpty) {
        return false;
      }

      await updateTokens(
        access: newAccess,
        refresh: newRefresh,
      );

      return true;
    } catch (error) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FETCH CURRENT USER
  // ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchMe() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: headers(),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = Map<String, dynamic>.from(
        jsonDecode(response.body),
      );

      final resolvedUser = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'])
          : data['data'] is Map
              ? Map<String, dynamic>.from(data['data'])
              : data;

      await setCurrentUser(resolvedUser);

      return data;
    } catch (error) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse(
          '$baseUrl/api/auth/logout',
        ),
        headers: headers(),
      );
    } catch (_) {}

    await clearSession();
  }

  // ─────────────────────────────────────────────────────────────
  // CLEAR SESSION
  // ─────────────────────────────────────────────────────────────

  static Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    currentUser = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _accessTokenKey,
    );

    await prefs.remove(
      _refreshTokenKey,
    );

    await prefs.remove(_userKey);
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  static bool get isLoggedIn {
    return accessToken != null && accessToken!.isNotEmpty;
  }

  static Map<String, dynamic>? get user {
    return currentUser;
  }
}