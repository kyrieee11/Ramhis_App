import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../../core/session_manager.dart';
import '../../models/event_model.dart';

class EventService {
  static const String baseUrl = AppConfig.baseUrl;

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  static List<dynamic> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded;
    }

    return [];
  }

  static void _throwIfFailed(
    http.Response response,
    String fallbackMessage,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    final data = _decodeObject(response);

    throw Exception(
      data['message']?.toString() ?? fallbackMessage,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // USER: GET /events
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<EventModel>> getEvents() async {
  Future<http.Response> requestEvents() {
    return http.get(
      Uri.parse('$baseUrl/events'),
      headers: AuthSession.headers(),
    );
  }

  var response = await requestEvents();

  debugPrint('USER EVENTS STATUS BEFORE REFRESH: ${response.statusCode}');
  debugPrint('USER EVENTS BODY BEFORE REFRESH: ${response.body}');

  if (response.statusCode == 401) {
    final refreshed = await AuthSession.refreshSession();

    debugPrint('USER EVENTS REFRESHED: $refreshed');

    if (refreshed) {
      response = await requestEvents();

      debugPrint('USER EVENTS STATUS AFTER REFRESH: ${response.statusCode}');
      debugPrint('USER EVENTS BODY AFTER REFRESH: ${response.body}');
    }
  }

  _throwIfFailed(
    response,
    'Failed to fetch events.',
  );

  final data = _decodeList(response);

  return data
      .map(
        (item) => EventModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

  // ────────────────────────────────────────────────────────────────────────────
  // USER: POST /events/:id/register
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> registerForEvent(
    String eventId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/register'),
      headers: AuthSession.headers(),
    );

    _throwIfFailed(
      response,
      'Failed to register for event.',
    );

    return _decodeObject(response);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // USER: POST /events/cancel
  // Body: { eventId }
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> cancelEvent(
    String eventId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/cancel'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'eventId': eventId,
      }),
    );

    _throwIfFailed(
      response,
      'Failed to cancel event.',
    );

    return _decodeObject(response);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // USER: GET /events/:id/participants
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getParticipants(
    String eventId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/participants'),
      headers: AuthSession.headers(),
    );

    _throwIfFailed(
      response,
      'Failed to fetch participants.',
    );

    return _decodeList(response);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ADMIN: GET /admin/events
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<EventModel>> adminGetEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/events'),
      headers: AuthSession.headers(),
    );

    _throwIfFailed(
      response,
      'Failed to fetch admin events.',
    );

    final data = _decodeList(response);

    return data
        .map(
          (item) => EventModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ADMIN: POST /admin/events
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> adminCreateEvent({
    required String title,
    required String description,
    required String location,
    required String operationDays,
    required String callTime,
    required String meetingPlace,
    required DateTime? missionDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/events'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'operation_days': operationDays,
        'call_time': callTime,
        'meeting_place': meetingPlace,
        'mission_date': missionDate?.toIso8601String(),
      }),
    );

    _throwIfFailed(
      response,
      'Failed to create event.',
    );

    return _decodeObject(response);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ADMIN: PUT /admin/events/:id
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> adminUpdateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required String operationDays,
    required String callTime,
    required String meetingPlace,
    required DateTime? missionDate,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/events/$eventId'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'operation_days': operationDays,
        'call_time': callTime,
        'meeting_place': meetingPlace,
        'mission_date': missionDate?.toIso8601String(),
      }),
    );

    _throwIfFailed(
      response,
      'Failed to update event.',
    );

    return _decodeObject(response);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ADMIN: POST /admin/events/delete
  // Body: { eventId }
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> adminDeleteEvent(
    String eventId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/events/delete'),
      headers: AuthSession.headers(),
      body: jsonEncode({
        'eventId': eventId,
      }),
    );

    _throwIfFailed(
      response,
      'Failed to delete event.',
    );

    return _decodeObject(response);
  }
}