import 'dart:convert';

import '../core/auth_token_session_flow.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel?> fetchMe() async {
    final response = await AuthApi.get('/me');

    if (response.statusCode != 200) return null;

    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    AuthSession.user = data;
    return UserModel.fromJson(data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await AuthApi.login(
      email: email,
      password: password,
    );

    if (result['ok'] == true && result['user'] != null) {
      return {
        'ok': true,
        'accessToken': result['accessToken'],
        'refreshToken': result['refreshToken'],
        'user': result['user'],
      };
    }

    return {
      'ok': false,
      'message': (result['message'] ?? 'Login failed.').toString(),
    };
  }

  Future<void> logout() async {
    await AuthApi.logout();
  }
}