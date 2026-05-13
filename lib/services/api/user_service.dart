import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../../core/session_manager.dart';

class UserService {
  static const String baseUrl = AppConfig.baseUrl;

  // GET /me
  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: AuthSession.headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch profile.');
    }

    AuthSession.currentUser = Map<String, dynamic>.from(data);
    return data;
  }

  // PUT /me/change-password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/me/change-password'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to change password.');
    }

    return data;
  }

  // GET /users
  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: AuthSession.headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch users.');
    }

    return data as List<dynamic>;
  }

  // GET /users/approved?q=search
  static Future<List<dynamic>> getApprovedUsers({String q = ''}) async {
    final uri = Uri.parse('$baseUrl/users/approved').replace(
      queryParameters: q.trim().isEmpty ? null : {'q': q.trim()},
    );

    final response = await http.get(
      uri,
      headers: AuthSession.headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch approved users.');
    }

    return data as List<dynamic>;
  }

  // PUT /users/:id
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String fullName,
    required String email,
    required String contactNumber,
    required String birthdate,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'contact_number': contactNumber,
        'birthdate': birthdate,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update user.');
    }

    if (data['user'] is Map<String, dynamic>) {
      AuthSession.currentUser = Map<String, dynamic>.from(data['user']);
    }

    return data;
  }

  // PUT /users/:id/profile-image
  static Future<Map<String, dynamic>> updateProfileImage({
    required String id,
    required String imageBase64,
    required String fileName,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id/profile-image'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'imageBase64': imageBase64,
        'fileName': fileName,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update profile image.');
    }

    if (data['user'] is Map<String, dynamic>) {
      AuthSession.currentUser = Map<String, dynamic>.from(data['user']);
    }

    return data;
  }
}