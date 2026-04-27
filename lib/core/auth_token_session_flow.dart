import 'dart:async';
import 'dart:convert';
import 'dart:developer'; // ✅ for log()

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static String? accessToken;
  static String? refreshToken;
  static Map<String, dynamic>? user;

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userKey = 'auth_user';

  static bool isReady = false;
  static bool _isRefreshing = false;

  // ✅ LOGIN STATE
  static bool get isLoggedIn =>
      accessToken != null && accessToken!.isNotEmpty;

  // ✅ ADMIN CHECK
  static bool get isAdmin {
    final role = (user?['role'] ?? '').toString().toLowerCase();
    final type = (user?['account_type'] ?? '').toString().toLowerCase();
    return role == 'admin' || type == 'admin';
  }

  static String get userStatus =>
      (user?['status'] ?? 'active').toString();

  // ✅ HEADERS
  static Map<String, String> headers({
    bool json = true,
    String? tokenOverride,
  }) {
    final token = tokenOverride ?? accessToken;

    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ✅ SAVE SESSION
  static Future<void> saveSession({
    required String newAccessToken,
    required String newRefreshToken,
    required Map<String, dynamic> newUser,
  }) async {
    accessToken = newAccessToken;
    refreshToken = newRefreshToken;
    user = Map<String, dynamic>.from(newUser);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, newAccessToken);
    await prefs.setString(_refreshTokenKey, newRefreshToken);
    await prefs.setString(_userKey, jsonEncode(newUser));

    // ✅ PRODUCTION SAFE LOG
    log('LOGIN USER: $user');
    log('IS ADMIN: $isAdmin');
  }

  // ✅ UPDATE TOKENS
  static Future<void> updateTokens({
    required String newAccessToken,
    required String newRefreshToken,
  }) async {
    accessToken = newAccessToken;
    refreshToken = newRefreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, newAccessToken);
    await prefs.setString(_refreshTokenKey, newRefreshToken);
  }

  // ✅ UPDATE USER
  static Future<void> updateUser(Map<String, dynamic> newUser) async {
    user = Map<String, dynamic>.from(newUser);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(newUser));
  }

  // ✅ RESTORE SESSION
  static Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      accessToken = prefs.getString(_accessTokenKey);
      refreshToken = prefs.getString(_refreshTokenKey);

      final savedUser = prefs.getString(_userKey);

      if (savedUser != null && savedUser.isNotEmpty) {
        final decoded = jsonDecode(savedUser);
        user = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      accessToken = null;
      refreshToken = null;
      user = null;
    } finally {
      isReady = true;
    }
  }

  // ✅ CLEAR SESSION
  static Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ✅ REFRESH TOKEN
  static Future<bool> refreshAccessToken() async {
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 500));
      return accessToken != null;
    }

    if (refreshToken == null || refreshToken!.isEmpty) {
      await clearSession();
      return false;
    }

    _isRefreshing = true;

    try {
      final response = await http
          .post(
            Uri.parse('${AuthApi.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      final data = AuthApi.tryDecodeMap(response.body);

      if (response.statusCode == 200 &&
          data != null &&
          data['accessToken'] != null &&
          data['refreshToken'] != null) {
        await updateTokens(
          newAccessToken: data['accessToken'],
          newRefreshToken: data['refreshToken'],
        );
        return true;
      }

      await clearSession();
      return false;
    } catch (e) {
      log('REFRESH TOKEN ERROR: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}

class AuthApi {
  static const String baseUrl = 'http://10.0.2.2:5000';

  static Future<void> logout() async {
    try {
      await post('/auth/logout');
    } catch (_) {
      // ignore
    } finally {
      await AuthSession.clearSession();
    }
  }

  static Future<void> fetchMe() async {
    try {
      final response = await get('/me');

      if (response.statusCode == 200) {
        final data = tryDecodeMap(response.body);
        if (data != null) {
          await AuthSession.updateUser(data);
        }
      }
    } catch (_) {}
  }

  // ✅ SAFE JSON PARSE
  static Map<String, dynamic>? tryDecodeMap(String body) {
    try {
      if (body.trim().isEmpty) return null;
      final decoded = jsonDecode(body);
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static String extractMessage(http.Response res) {
    final data = tryDecodeMap(res.body);
    return data?['message'] ?? 'Request failed';
  }

  // ✅ LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = tryDecodeMap(response.body);

      if (response.statusCode == 200 &&
          data != null &&
          data['accessToken'] != null) {
        await AuthSession.saveSession(
          newAccessToken: data['accessToken'],
          newRefreshToken: data['refreshToken'],
          newUser: data['user'],
        );

        return {'ok': true};
      }

      return {'ok': false, 'message': extractMessage(response)};
    } catch (e) {
      log('LOGIN ERROR: $e');
      return {'ok': false, 'message': 'Connection error'};
    }
  }

  // ✅ REQUEST HANDLER
  static Future<http.Response> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request();

      if (response.statusCode == 401) {
        final refreshed = await AuthSession.refreshAccessToken();

        if (refreshed) {
          response = await request();
        } else {
          await AuthSession.clearSession();
        }
      }

      return response;
    } catch (e) {
      log('NETWORK ERROR: $e');
      return http.Response(
        jsonEncode({'message': 'Network error'}),
        500,
      );
    }
  }

  static Future<http.Response> get(String path) {
    return _handleRequest(() => http.get(
          Uri.parse('$baseUrl$path'),
          headers: AuthSession.headers(json: false),
        ));
  }

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _handleRequest(() => http.post(
          Uri.parse('$baseUrl$path'),
          headers: AuthSession.headers(),
          body: jsonEncode(body ?? {}),
        ));
  }

  static Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _handleRequest(() => http.put(
          Uri.parse('$baseUrl$path'),
          headers: AuthSession.headers(),
          body: jsonEncode(body ?? {}),
        ));
  }

  static Future<http.Response> delete(String path) {
    return _handleRequest(() => http.delete(
          Uri.parse('$baseUrl$path'),
          headers: AuthSession.headers(json: false),
        ));
  }
}