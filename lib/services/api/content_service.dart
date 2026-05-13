import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../../core/session_manager.dart';
import '../../models/content_model.dart';

class ContentService {
  static const String baseUrl = AppConfig.baseUrl;

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static List<dynamic> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  static void _throwIfFailed(http.Response response, String fallbackMessage) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeObject(response);
      throw Exception(data['message'] ?? fallbackMessage);
    }
  }

  // ── Public: GET /content/homepage_content ─────────────────────────────────
  // No Authorization header because this backend route is public.
  static Future<ContentModel?> getHomepageContent() async {
    final response = await http.get(
      Uri.parse('$baseUrl/content/homepage_content'),
    );

    if (response.statusCode == 404) {
      return null;
    }

    _throwIfFailed(response, 'Failed to fetch homepage content.');

    return ContentModel.fromJson(_decodeObject(response));
  }

  // ── Admin: GET /admin/content ──────────────────────────────────────────────
  static Future<List<ContentModel>> adminGetContent() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/content'),
      headers: AuthSession.headers(),
    );

    _throwIfFailed(response, 'Failed to fetch admin content.');

    return _decodeList(response)
        .map((item) => ContentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ── Admin: POST /admin/content ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> adminCreateContent({
    required String slug,
    required String title,
    required String body,
    required Map<String, dynamic> sections,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/content'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'slug': slug,
        'title': title,
        'body': body,
        'sections': sections,
      }),
    );

    _throwIfFailed(response, 'Failed to create content.');

    return _decodeObject(response);
  }

  // ── Admin: PUT /admin/content/:id ──────────────────────────────────────────
  static Future<Map<String, dynamic>> adminUpdateContent({
    required String id,
    required String slug,
    required String title,
    required String body,
    required Map<String, dynamic> sections,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/content/$id'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'slug': slug,
        'title': title,
        'body': body,
        'sections': sections,
      }),
    );

    _throwIfFailed(response, 'Failed to update content.');

    return _decodeObject(response);
  }
}