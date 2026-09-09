import 'dart:convert';
import 'dart:io';

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

      print('💬 THREADS URL: ${response.request?.url}');
      print('💬 THREADS STATUS: ${response.statusCode}');
      print('💬 THREADS BODY: ${response.body}');

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      final rawData = decoded is List
          ? decoded
          : decoded['threads'] ??
              decoded['data'] ??
              const [];

      final data = List<Map<String, dynamic>>.from(
        rawData.map(
          (item) => Map<String, dynamic>.from(item),
        ),
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
      final response = await http
    .post(
      Uri.parse('$_base/chat/threads/$threadId/messages'),
      headers: {
        ...AuthSession.headers(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
      }),
    )
    .timeout(
      const Duration(seconds: 15),
    );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print('❌ sendMessage error: $e');
      return false;
    }
  }

  Future<ChatMessageModel?> sendFileMessage({
    required String threadId,
    required String filePath,
    String message = '',
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        print('❌ sendFileMessage error: File does not exist');
        return null;
      }

      final uri = Uri.parse(
        '$_base/chat/threads/$threadId/files',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.headers.addAll(
        AuthSession.headers(),
      );

      request.fields['message'] = message;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      print('📎 FILE SEND URL: $uri');
      print('📎 FILE SEND STATUS: ${response.statusCode}');
      print('📎 FILE SEND BODY: ${response.body}');

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      return ChatMessageModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      print('❌ sendFileMessage error: $e');
      return null;
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