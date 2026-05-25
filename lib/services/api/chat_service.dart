import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/models/chat_message_model.dart';
import 'package:ramhis_app/models/chat_thread_model.dart';

class ChatService {
static String get _base => AppConfig.baseUrl;
  Future<List<ChatThreadModel>> getThreads() async {
    try {
      final response = await http.get(
        Uri.parse('$_base/chat/threads'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      final data = decoded is List
          ? List<Map<String, dynamic>>.from(decoded)
          : List<Map<String, dynamic>>.from(
              decoded['threads'] ?? [],
            );

      return data.map(ChatThreadModel.fromJson).toList();
    } catch (e) {
      print('❌ getThreads error: $e');
      return [];
    }
  }

  Future<List<ChatMessageModel>> getMessages(
    String threadId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_base/chat/threads/$threadId/messages',
        ),
        headers: AuthSession.headers(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      final data = decoded is List
          ? List<Map<String, dynamic>>.from(decoded)
          : List<Map<String, dynamic>>.from(
              decoded['messages'] ?? [],
            );

      return data
          .map(ChatMessageModel.fromJson)
          .toList();
    } catch (e) {
      print('❌ getMessages error: $e');
      return [];
    }
  }

  Future<bool> sendMessage({
    required String threadId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$_base/chat/threads/$threadId/messages',
        ),
        headers: {
          ...AuthSession.headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print('❌ sendMessage error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>>
      searchApprovedUsers(String query) async {
    try {
      final response = await http.get(
  Uri.parse(
    '$_base/users/approved?q=${Uri.encodeQueryComponent(query)}',
  ),
  headers: AuthSession.headers(),
);

print('🔍 SEARCH URL: ${response.request?.url}');
print('🔍 SEARCH STATUS: ${response.statusCode}');
print('🔍 SEARCH BODY: ${response.body}');

if (response.statusCode != 200) {
  return [];
}

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      return List<Map<String, dynamic>>.from(
        decoded['users'] ?? [],
      );
    } catch (e) {
      print('❌ searchApprovedUsers error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?>
      createOrOpenDirectThread(
    String userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/chat/direct'),
        headers: {
          ...AuthSession.headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        return null;
      }

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      print('❌ createOrOpenDirectThread error: $e');
      return null;
    }
  }
}