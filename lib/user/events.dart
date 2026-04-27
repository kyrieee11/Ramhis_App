import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../widgets/bottom_nav.dart';
import 'event_details.dart';

class EventsWidget extends StatefulWidget {
  const EventsWidget({super.key});

  @override
  State<EventsWidget> createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  final EventService _eventService = EventService();

  bool isLoading = true;
  List<EventModel> events = [];
  final Map<String, bool> acceptedTerms = {};

  io.Socket? _socket;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _connectSocket();

    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  void _connectSocket() {
    _socket = io.io(
      'http://10.0.2.2:5000',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Connected to events socket');
    });

    _socket!.on('events_updated', (_) async {
      if (!mounted) return;
      await _loadEvents();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from events socket');
    });
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final data = await _eventService.getEvents();

      if (!mounted) return;
      setState(() {
        events = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        events = [];
        isLoading = false;
      });
    }
  }

  Future<void> _register(String eventId) async {
    final success = await _eventService.registerForEvent(eventId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Joined successfully' : 'Join failed'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      await _loadEvents();
    }
  }

  Future<void> _cancelJoin(String eventId) async {
    final success = await _eventService.cancelEvent(eventId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Cancelled successfully' : 'Cancel failed'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      await _loadEvents();
    }
  }

  Future<void> _confirmCancelJoin(String eventId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cancel Join?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to cancel your participation in this mission?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'No',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD95362),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _cancelJoin(eventId);
    }
  }

  void _openVolunteers(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsWidget(eventId: eventId),
      ),
    );
  }

  EventModel? get _nextMission {
    if (events.isEmpty) return null;
    return events.first;
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case 'ongoing':
        color = const Color(0xFFF59E0B);
        break;
      case 'done':
        color = const Color(0xFF6B7280);
        break;
      default:
        color = const Color(0xFF22C55E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextMission = _nextMission;

    return Scaffold(
      backgroundColor: const Color(0xFF3E5EBE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4766C7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Events',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _buildHeroHeader(),
                        const SizedBox(height: 18),
                        if (nextMission == null)
                          _buildEmptyState()
                        else
                          _buildNextMissionCard(nextMission),
                      ],
                    ),
                  ),
          ),
          const CustomNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B76D1),
            Color(0xFF7A8FF0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Incoming Mission',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'View the latest upcoming mission and confirm your participation.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFFEAF0FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMissionCard(EventModel event) {
    final accepted = acceptedTerms[event.id] ?? false;
    final isDone = event.status.toLowerCase() == 'done';
    final isRegistrationClosed = !event.registrationOpen;
    final canJoin = accepted &&
        !event.alreadyJoined &&
        !isDone &&
        !isRegistrationClosed;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5A6FD6),
                  Color(0xFF6D84EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'LATEST MISSION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _statusBadge(event.status),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  event.title.isEmpty ? 'Mission Event' : event.title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.location.isEmpty
                      ? 'Location to be announced'
                      : event.location,
                  style: const TextStyle(
                    color: Color(0xFFEAF0FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Column(
              children: [
                _detailCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Mission Date',
                  value: event.operationDays.isEmpty ? '-' : event.operationDays,
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.access_time_rounded,
                  label: 'Call Time',
                  value: event.callTime.isEmpty ? '-' : event.callTime,
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.place_rounded,
                  label: 'Meeting Place',
                  value: event.meetingPlace.isEmpty ? '-' : event.meetingPlace,
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.groups_rounded,
                  label: 'Volunteers',
                  value: '${event.volunteers.length} joined / listed',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openVolunteers(event.id),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      color: Color(0xFF4866CA),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'View Volunteers',
                        style: TextStyle(
                          color: Color(0xFF1B2559),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF4866CA),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: accepted,
                    activeColor: const Color(0xFF5A48B3),
                    onChanged: (event.alreadyJoined || isDone || isRegistrationClosed)
                        ? null
                        : (value) {
                            setState(() {
                              acceptedTerms[event.id] = value ?? false;
                            });
                          },
                  ),
                  Expanded(
                    child: Text(
                      event.alreadyJoined
                          ? 'You already joined this mission'
                          : isDone
                              ? 'This mission is already done'
                              : isRegistrationClosed
                                  ? 'Registration is closed'
                                  : 'I agree to Terms and Conditions',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1B2559),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: event.alreadyJoined
                  ? ElevatedButton.icon(
                      onPressed: isDone
                          ? null
                          : () => _confirmCancelJoin(event.id),
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Cancel Join',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7280),
                        disabledBackgroundColor: const Color(0xFFBFC7D9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: canJoin ? () => _register(event.id) : null,
                      icon: Icon(
                        isDone
                            ? Icons.event_busy_rounded
                            : isRegistrationClosed
                                ? Icons.lock_clock_rounded
                                : Icons.how_to_reg_rounded,
                      ),
                      label: Text(
                        isDone
                            ? 'Mission Done'
                            : isRegistrationClosed
                                ? 'Registration Closed'
                                : 'Join Mission',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD95362),
                        disabledBackgroundColor: const Color(0xFFBFC7D9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4866CA),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF1B2559),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: Colors.white,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'No upcoming mission available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Please check again later for the next incoming medical mission.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFDCE6FF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}