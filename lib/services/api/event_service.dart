import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;


import '../../core/app_config.dart';
import '../../core/session_manager.dart';
import '../../models/event_model.dart';

class EventService {
static const String apiUrl = AppConfig.baseUrl;
  static Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) return {};

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  static List<dynamic> _extractEventList(http.Response response) {
    if (response.body.isEmpty) return [];

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is List) {
        return decoded['data'];
      }

      if (decoded['events'] is List) {
        return decoded['events'];
      }
    }

    return [];
  }

  static void _throwIfFailed(
  http.Response response,
  String fallbackMessage,
) {
  Map<String, dynamic> data = {};

  try {
    data = _decodeObject(response);
  } catch (_) {}

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      data['ok'] != false) {
    return;
  }

  throw Exception(
    data['message']?.toString() ?? fallbackMessage,
  );
}

  static Future<http.Response> _withRefresh(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request();

      if (response.statusCode == 401) {
        final refreshed = await AuthSession.refreshSession();

        if (refreshed) {
          response = await request();
        }
      }

      return response;
    } on TimeoutException catch (_) {
      throw Exception('Server is starting up. Please try again.');
    }
  }

  static String get _currentUserId {
    final user = AuthSession.currentUser;

    return (user?['_id'] ?? user?['id'] ?? user?['userId'] ?? '').toString();
  }

  // GET /api/events
  static Future<List<EventModel>> getEvents() async {
    final response = await _withRefresh(() {
      return http
          .get(
            Uri.parse('$apiUrl/events'),
            headers: AuthSession.headers(),
          )
          .timeout(
            const Duration(seconds: 60),
          );
    });
    

print('GET EVENTS URL: $apiUrl/events');
print('GET EVENTS STATUS: ${response.statusCode}');
print('GET EVENTS BODY: ${response.body}');



    _throwIfFailed(response, 'Failed to fetch events.');

    final data = _extractEventList(response);

    return data
        .map(
          (item) => EventModel.fromJson(
            Map<String, dynamic>.from(item),
            _currentUserId,
          ),
        )
        .toList();
  }

  // GET /api/events/:id
  static Future<EventModel> getEventById(String eventId) async {
    final response = await _withRefresh(() {
      return http
          .get(
            Uri.parse('$apiUrl/events/$eventId'),
            headers: AuthSession.headers(),
          )
          .timeout(
            const Duration(seconds: 60),
          );
    });

    _throwIfFailed(response, 'Failed to fetch event.');

    final data = _decodeObject(response);

    final eventJson =
        data['data'] ??
        data['event'] ??
        data;

    return EventModel.fromJson(
      Map<String, dynamic>.from(eventJson),
      _currentUserId,
    );
  }

  // POST /api/events/:id/join
  static Future<Map<String, dynamic>> registerForEvent(
    String eventId,
  ) async {
    print('AUTH HEADERS: ${AuthSession.headers()}');
    final response = await _withRefresh(() {
      return http
          .post(
            Uri.parse('$apiUrl/events/$eventId/join'),
            headers: AuthSession.headers(),
          )
          .timeout(
            const Duration(seconds: 60),
          );
    });

    print('JOIN STATUS: ${response.statusCode}');
print('JOIN BODY: ${response.body}');

    _throwIfFailed(response, 'Failed to join event.');

    return _decodeObject(response);
  }

  // Optional alias
  static Future<Map<String, dynamic>> joinEvent(String eventId) {
    return registerForEvent(eventId);
  }

  // POST /api/events/:id/leave
  static Future<Map<String, dynamic>> leaveEvent(
    String eventId,
  ) async {
    final response = await _withRefresh(() {
      return http
          .post(
            Uri.parse('$apiUrl/events/$eventId/leave'),
            headers: AuthSession.headers(),
          )
          .timeout(
            const Duration(seconds: 60),
          );
    });

    _throwIfFailed(response, 'Failed to cancel join request.');

    final data = _decodeObject(response);

    return {
      'ok': data['ok'] ?? true,
      'message': data['message'] ?? 'Request cancelled.',
      ...data,
    };
  }

  // Optional alias
   // Optional alias
  static Future<Map<String, dynamic>> cancelJoinRequest(String eventId) {
    return leaveEvent(eventId);
  }

  // ↓ ADDED: DELETE /api/events/:id
  static Future<Map<String, dynamic>> deleteEvent(
    String eventId,
  ) async {
    final response = await _withRefresh(() {
      return http
          .delete(
            Uri.parse('$apiUrl/events/$eventId'),
            headers: AuthSession.headers(),
          )
          .timeout(
            const Duration(seconds: 60),
          );
    });

    _throwIfFailed(
      response,
      'Failed to remove event schedule.',
    );

    final data = _decodeObject(response);

    return {
      'ok': data['ok'] ?? true,
      'message': data['message'] ?? 'Event removed successfully.',
      ...data,
    };
  }
}
