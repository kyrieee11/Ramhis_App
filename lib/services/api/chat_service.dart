import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/models/chat_message_model.dart';
import 'package:ramhis_app/models/chat_thread_model.dart';

class ChatService {
  Future<List<ChatThreadModel>> getThreads() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/chat/threads'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode != 200) return [];

      final data = List<Map<String, dynamic>>.from(
        jsonDecode(response.body),
      );

      return data.map(ChatThreadModel.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ChatMessageModel>> getMessages(String threadId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/chat/threads/$threadId/messages'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode != 200) return [];

      final data = List<Map<String, dynamic>>.from(
        jsonDecode(response.body),
      );

      return data.map(ChatMessageModel.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendMessage({
    required String threadId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/chat/threads/$threadId/messages'),
        headers: AuthSession.headers(),
        body: jsonEncode({'message': message}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchApprovedUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.baseUrl}/users/approved?q=${Uri.encodeQueryComponent(query)}',
        ),
        headers: AuthSession.headers(),
      );

      if (response.statusCode != 200) return [];

      return List<Map<String, dynamic>>.from(
        jsonDecode(response.body),
      );
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createOrOpenDirectThread(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/chat/direct'),
        headers: AuthSession.headers(),
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (_) {
      return null;
    }
  }
}