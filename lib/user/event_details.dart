import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/auth_token_session_flow.dart';

class EventDetailsWidget extends StatefulWidget {
  const EventDetailsWidget({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<EventDetailsWidget> createState() => _EventDetailsWidgetState();
}

class _EventDetailsWidgetState extends State<EventDetailsWidget> {
  static const String baseUrl = 'http://10.0.2.2:5000';

  bool isLoading = true;
  List<Map<String, dynamic>> participants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/events/${widget.eventId}/participants'),
        headers: AuthSession.headers(json: false),
      );

      if (res.statusCode == 200) {
        participants = List<Map<String, dynamic>>.from(
          jsonDecode(res.body),
        );
      } else {
        participants = [];
      }
    } catch (_) {
      participants = [];
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E5EBE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4766C7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Volunteers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : participants.isEmpty
              ? const Center(
                  child: Text(
                    'No volunteers yet.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: participants.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (p['full_name'] ?? 'Volunteer').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}