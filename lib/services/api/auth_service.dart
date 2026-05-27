import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../../core/session_manager.dart';

class AuthService {
  static const String baseUrl = AppConfig.baseUrl;

  // ── Signup: POST /signup ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String accountType,
    String contactNumber = '',
    String birthdate = '',
    bool acceptedTerms = false,
    String prcLicenseNumber = '',
    String specialty = '',
    String hospitalClinic = '',
    String organization = '',
    String skills = '',
    File? licenseFile,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/signup');

    final request = http.MultipartRequest('POST', uri);

    request.fields['full_name'] = fullName;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['account_type'] = accountType;
    request.fields['contact_number'] = contactNumber;
    request.fields['birthdate'] = birthdate;
    request.fields['accepted_terms'] = acceptedTerms.toString();
    request.fields['prc_license_number'] = prcLicenseNumber;
    request.fields['specialty'] = specialty;
    request.fields['hospital_clinic'] = hospitalClinic;
    request.fields['organization'] = organization;
    request.fields['skills'] = skills;

    if (licenseFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'license_file',
          licenseFile.path,
        ),
      );
    }

    final streamedResponse = await request
    .send()
    .timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse);

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Signup failed.');
    }

    return data;
  }

  // ── Login: POST /login ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
    .post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    )
    .timeout(
      const Duration(seconds: 60),
    );

    final data = jsonDecode(response.body);

   if (response.statusCode != 200) {
  final message =
      (data['message'] ?? data['msg'] ?? '')
          .toString()
          .toLowerCase();

  if (message.contains('awaiting admin approval') ||
      message.contains('pending')) {
    throw Exception(
      'Your account is pending approval',
    );
  }

  throw Exception(
    data['message'] ??
        data['msg'] ??
        'Login failed.',
  );
}

    await AuthSession.saveSession(
      access:
    data['accessToken'] ??
    data['token'] ??
    '',
refresh:
    data['refreshToken'] ??
    '',
      user: Map<String, dynamic>.from(data['user']),
    );

    return data;
  }

  // ── Refresh: POST /auth/refresh ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = AuthSession.refreshToken;

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token found.');
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

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Token refresh failed.');
    }

    await AuthSession.updateTokens(
      access:
    data['accessToken'] ??
    data['token'] ??
    '',
refresh:
    data['refreshToken'] ??
    '',
    );

    return data;
  }

  // ── Logout: POST /auth/logout ───────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: AuthSession.headers(),
      );
    } catch (_) {}

    await AuthSession.clearSession();
  }

  // ── Forgot Password: POST /auth/forgot-password ─────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http
    .post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Forgot password failed.');
    }

    return data;
  }

  // ── Reset Password: POST /auth/reset-password ───────────────────────────────
  static Future<Map<String, dynamic>> resetPassword({
  required String token,
  required String newPassword,
}) async {
  final response = await http
      .post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      )
      .timeout(
        const Duration(seconds: 60),
      );

  final data = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300) {
    throw Exception(
      data['message'] ??
          'Reset password failed.',
    );
  }

  return data;
}

  // ── Get Me ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: AuthSession.headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch user.');
    }

    final userData =
    Map<String, dynamic>.from(
      data['data'] ?? data,
    );

AuthSession.currentUser = userData;

return userData;
  }

  // NOTE:
  // GET /reset-password is intentionally NOT used here.
  // Your backend serves it as an HTML page for email/deep-link flow,
  // not as a Flutter API endpoint.
}