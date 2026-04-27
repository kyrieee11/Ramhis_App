import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/auth_token_session_flow.dart';
import '../models/user_model.dart';

class UserService {
  Future<UserModel?> getProfile() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/me'),
      headers: AuthSession.headers(json: false),
    );

    if (response.statusCode != 200) return null;

    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    AuthSession.user = data;
    return UserModel.fromJson(data);
  }
}