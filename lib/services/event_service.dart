import 'dart:convert';

import '../core/auth_token_session_flow.dart';
import '../models/event_model.dart';

class EventService {
  /// ================= GET EVENTS =================
  Future<List<EventModel>> getEvents() async {
    final response = await AuthApi.get('/events');

    if (response.statusCode != 200) {
      throw Exception('Failed to load events: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// ================= REGISTER =================
  Future<bool> registerForEvent(String eventId) async {
    final response = await AuthApi.post('/events/$eventId/register');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    return false;
  }

  /// ================= CANCEL =================
  Future<bool> cancelEvent(String eventId) async {
    final response = await AuthApi.post(
      '/events/cancel',
      body: {
        'eventId': eventId,
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  /// ================= OPTIONAL: GET PARTICIPANTS =================
  Future<List<dynamic>> getParticipants(String eventId) async {
    final response = await AuthApi.get('/events/$eventId/participants');

    if (response.statusCode != 200) {
      throw Exception('Failed to load participants');
    }

    return jsonDecode(response.body);
  }
}