import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/models/event_model.dart';
import 'package:ramhis_app/services/api/event_service.dart';

const _kPrimary = Color(0xFF5B76F7);
const _kAccent = Color(0xFF4564E8);
const _kBg = Color(0xFFF0F2FF);
const _kTextPrimary = Color(0xFF1B2559);
const _kTextSecondary = Color(0xFF7B8BB2);
const _kGreen = Color(0xFF22C55E);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kGray = Color(0xFF6B7280);

class EventsWidget extends StatefulWidget {
  const EventsWidget({super.key});

  @override
  State<EventsWidget> createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  bool isLoading = true;
  List<EventModel> events = [];
  final Map<String, bool> acceptedTerms = {};

  String selectedFilter = 'All';

  io.Socket? _socket;
  Timer? _statusTimer;

  final List<String> filters = const [
    'All',
    'Upcoming',
    'Ongoing',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _connectSocket();

    _statusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadEvents(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _socket?.off('events_updated');
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _connectSocket() {
    _socket = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('✅ Connected to events socket');
    });

    _socket?.on('events_updated', (_) async {
      if (!mounted) return;
      await _loadEvents();
    });

    _socket?.onDisconnect((_) {
      debugPrint('❌ Disconnected from events socket');
    });
  }

  Future<void> _loadEvents() async {
  if (!mounted) return;

  setState(() => isLoading = true);

  try {
    final data = await EventService.getEvents();

    if (!mounted) return;

    setState(() {
      events = data;
      isLoading = false;
    });
  } catch (error) {
    debugPrint('❌ Failed to load events: $error');

    if (!mounted) return;

    // DEBUG MODE: load mock events so UI can be tested
    // without a live backend
    if (kDebugMode) {
      setState(() {
        events = [
          EventModel.mock(
            id: 'mock-1',
            title: 'Medical Mission Tondo',
            status: 'Upcoming',
            type: 'Medical Mission',
            location: 'Tondo, Manila',
            date: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
            startTime: '8:00 AM',
            endTime: '5:00 PM',
            description: 'Free medical checkup for the community.',
          ),
          EventModel.mock(
            id: 'mock-2',
            title: 'Health Seminar 2025',
            status: 'Ongoing',
            type: 'Seminar',
            location: 'Quezon City Hall',
            date: DateTime.now().toIso8601String(),
            startTime: '9:00 AM',
            endTime: '12:00 PM',
            description: 'Community health awareness seminar.',
          ),
          EventModel.mock(
            id: 'mock-3',
            title: 'Volunteer Training',
            status: 'Completed',
            type: 'Training',
            location: 'Pasig City',
            date: DateTime.now()
                .subtract(const Duration(days: 5))
                .toIso8601String(),
            startTime: '7:00 AM',
            endTime: '3:00 PM',
            description: 'Training for new health volunteers.',
          ),
        ];
        isLoading = false;
      });
      return;
    }

    setState(() {
      events = [];
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load events: $error'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  bool _isSuccess(Map<String, dynamic> result) {
    return result['ok'] == true ||
        result['success'] == true ||
        result['message'] != null;
  }

  Future<bool> _joinEvent(String eventId) async {
    try {
      final result = await EventService.registerForEvent(eventId);
      final success = _isSuccess(result);

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Join request submitted. Please wait for admin approval.'
                : (result['message'] ?? 'Join failed').toString(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) {
        await _loadEvents();
      }

      return success;
    } catch (error) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }
  }

  Future<bool> _leaveEvent(String eventId) async {
    try {
      final result = await EventService.leaveEvent(eventId);
      final success = _isSuccess(result);

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Join request cancelled.'
                : (result['message'] ?? 'Cancel request failed').toString(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) {
        await _loadEvents();
      }

      return success;
    } catch (error) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }
  }

  bool _isClosed(EventModel event) {
    final status = event.status.toLowerCase();
    return status == 'completed' ||
        status == 'cancelled' ||
        status == 'done' ||
        !event.registrationOpen;
  }

  List<EventModel> get filteredEvents {
    if (selectedFilter == 'All') return events;

    return events.where((event) {
      return _statusText(event).toLowerCase() == selectedFilter.toLowerCase();
    }).toList();
  }

  String _safeText(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _dynamicField(EventModel event, String key) {
    final dynamic e = event;

    try {
      switch (key) {
        case 'type':
          return _safeText(e.type);
        case 'description':
          return _safeText(e.description);
        case 'imageUrl':
          return _safeText(e.imageUrl);
        case 'date':
          return _safeText(e.date);
        case 'startTime':
          return _safeText(e.startTime);
        case 'endTime':
          return _safeText(e.endTime);
        case 'joinStatus':
          return _safeText(e.joinStatus);
        case 'participantStatus':
          return _safeText(e.participantStatus);
        case 'requestStatus':
          return _safeText(e.requestStatus);
        case 'myStatus':
          return _safeText(e.myStatus);
        case 'userStatus':
          return _safeText(e.userStatus);
      }
    } catch (_) {}

    return '';
  }

  String _statusText(EventModel event) {
    final status = event.status.trim();

    if (status.isEmpty) return 'Upcoming';
    if (status.toLowerCase() == 'done') return 'Completed';

    return status;
  }

  String _typeText(EventModel event) {
    final type = _dynamicField(event, 'type');

    if (type.isNotEmpty) return type;

    return 'Other';
  }

  String _descriptionText(EventModel event) {
    final description = _dynamicField(event, 'description');

    if (description.isNotEmpty) return description;

    return 'No description provided for this event.';
  }

  String _imageUrl(EventModel event) {
    return _dynamicField(event, 'imageUrl');
  }

  String _eventDate(EventModel event) {
    final rawDate = _dynamicField(event, 'date');

    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);

      if (parsed != null) {
        return _formatDate(parsed);
      }

      return rawDate;
    }

    if (event.operationDays.trim().isNotEmpty) {
      return event.operationDays;
    }

    return 'Date to be announced';
  }

  String _eventTime(EventModel event) {
    final start = _dynamicField(event, 'startTime');
    final end = _dynamicField(event, 'endTime');

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    }

    if (event.callTime.trim().isNotEmpty) {
      return event.callTime;
    }

    return 'Time to be announced';
  }

  String _eventLocation(EventModel event) {
    if (event.location.trim().isNotEmpty) {
      return event.location;
    }

    if (event.meetingPlace.trim().isNotEmpty) {
      return event.meetingPlace;
    }

    return 'Location to be announced';
  }

  String _organizerName(EventModel event) {
    final dynamic e = event;

    try {
      final createdBy = e.createdBy;

      if (createdBy is Map) {
        final name = _safeText(createdBy['name']);
        if (name.isNotEmpty) return name;

        final email = _safeText(createdBy['email']);
        if (email.isNotEmpty) return email;
      }

      final name = _safeText(createdBy.name);
      if (name.isNotEmpty) return name;
    } catch (_) {}

    return 'RAMHIS Admin';
  }

  String _joinStatus(EventModel event) {
    final possibleFields = [
      'joinStatus',
      'participantStatus',
      'requestStatus',
      'myStatus',
      'userStatus',
    ];

    for (final field in possibleFields) {
      final value = _dynamicField(event, field);

      if (value.isNotEmpty) {
        final normalized = value.toLowerCase();

        if (normalized.contains('approved')) return 'Approved';
        if (normalized.contains('pending')) return 'Pending';
        if (normalized.contains('rejected')) return 'Rejected';
      }
    }

    if (event.alreadyJoined) return 'Pending';

    return 'None';
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical mission':
        return _kRed;
      case 'training':
        return _kPrimary;
      case 'seminar':
        return _kAccent;
      case 'community outreach':
        return _kGreen;
      default:
        return _kGray;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical mission':
        return Icons.health_and_safety_rounded;
      case 'training':
        return Icons.school_rounded;
      case 'seminar':
        return Icons.record_voice_over_rounded;
      case 'community outreach':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return _kGreen;
      case 'completed':
      case 'done':
        return _kGray;
      case 'cancelled':
        return _kRed;
      case 'upcoming':
      default:
        return _kPrimary;
    }
  }

  void _openEventDetails(EventModel event) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          onJoin: () => _joinEvent(event.id),
          onLeave: () => _leaveEvent(event.id),
          typeText: _typeText(event),
          statusText: _statusText(event),
          descriptionText: _descriptionText(event),
          imageUrl: _imageUrl(event),
          dateText: _eventDate(event),
          timeText: _eventTime(event),
          locationText: _eventLocation(event),
          organizerName: _organizerName(event),
          joinStatus: _joinStatus(event),
          isClosed: _isClosed(event),
        ),
      ),
    );

    if (shouldRefresh == true) {
      await _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredEvents;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: isLoading
                ? _buildSkeletonList()
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _loadEvents,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _buildFilterTabs(),
                        const SizedBox(height: 16),
                        if (events.isEmpty)
                          _buildEmptyState()
                        else if (list.isEmpty)
                          _buildFilteredEmptyState()
                        else
                          AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 260),
                            child: Column(
                              children: list.map(_buildEventCard).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          const CustomNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 46, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B76F7), Color(0xFF4564E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -34,
            bottom: -42,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Material(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _loadEvents,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? null : Colors.white,
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF5B76F7), Color(0xFF4564E8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(999),
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFFE8ECFF)),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? _kPrimary.withValues(alpha: 0.24)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: selected ? 16 : 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: selected ? Colors.white : _kTextSecondary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                height: 38,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _skeletonCard(),
        _skeletonCard(),
        _skeletonCard(),
      ],
    );
  }

  Widget _skeletonCard() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch),
      tween: Tween<double>(begin: 0.55, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECFF),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 14),
            _skeletonLine(width: double.infinity, height: 18),
            const SizedBox(height: 10),
            _skeletonLine(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _skeletonLine(width: 220, height: 12),
            const SizedBox(height: 14),
            _skeletonLine(width: double.infinity, height: 46),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine({
    required double width,
    required double height,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECFF),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final status = _statusText(event);
    final type = _typeText(event);
    final joinStatus = _joinStatus(event);
    final closed = _isClosed(event);
    final participants = event.participants.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 18,
            bottom: 18,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: _typeColor(type),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openEventDetails(event),
            child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventImage(
                event: event,
                type: type,
                status: status,
              ),
              const SizedBox(height: 14),
              Text(
                event.title.isEmpty ? 'Untitled Event' : event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.calendar_month_rounded,
                text: _eventDate(event),
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.access_time_rounded,
                text: _eventTime(event),
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.location_on_rounded,
                text: _eventLocation(event),
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.groups_rounded,
                text: '$participants joined',
              ),
              const SizedBox(height: 16),
              _joinButton(
                event: event,
                joinStatus: joinStatus,
                closed: closed,
                isLarge: false,
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventImage({
    required EventModel event,
    required String type,
    required String status,
  }) {
    final image = _imageUrl(event);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 150,
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _gradientBanner(type);
                    },
                  )
                : _gradientBanner(type),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _badge(
              text: type,
              color: _typeColor(type),
              icon: _typeIcon(type),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _badge(
              text: status,
              color: _statusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBanner(String type) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _typeColor(type),
            _kAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -24,
            child: Icon(
              _typeIcon(type),
              size: 140,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Center(
            child: Icon(
              _typeIcon(type),
              size: 54,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _kPrimary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
}

  Widget _joinButton({
    required EventModel event,
    required String joinStatus,
    required bool closed,
    required bool isLarge,
  }) {
    final status = _statusText(event).toLowerCase();

    String label;
    IconData icon;
    Color color;
    bool filled;
    bool enabled;

    if (status == 'completed' || status == 'done') {
      label = 'Event Completed';
      icon = Icons.event_available_rounded;
      color = _kGray;
      filled = true;
      enabled = false;
    } else if (status == 'cancelled') {
      label = 'Event Cancelled';
      icon = Icons.cancel_rounded;
      color = _kRed;
      filled = true;
      enabled = false;
    } else if (joinStatus == 'Pending') {
      label = 'Request Pending';
      icon = Icons.hourglass_top_rounded;
      color = _kOrange;
      filled = false;
      enabled = false;
    } else if (joinStatus == 'Approved') {
      label = 'Approved ✓';
      icon = Icons.verified_rounded;
      color = _kGreen;
      filled = false;
      enabled = false;
    } else if (joinStatus == 'Rejected') {
      label = 'Rejected';
      icon = Icons.block_rounded;
      color = _kRed;
      filled = false;
      enabled = false;
    } else if (closed) {
      label = 'Registration Closed';
      icon = Icons.lock_clock_rounded;
      color = _kGray;
      filled = true;
      enabled = false;
    } else {
      label = 'Join Event';
      icon = Icons.how_to_reg_rounded;
      color = _kPrimary;
      filled = true;
      enabled = true;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      height: isLarge ? 54 : 48,
      decoration: filled
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF5B76F7), Color(0xFF4564E8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: enabled ? null : color.withValues(alpha: 0.70),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            )
          : null,
      child: filled
          ? ElevatedButton.icon(
              onPressed: enabled ? () => _joinEvent(event.id) : null,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.92),
                elevation: 0,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isLarge ? 15 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: null,
              icon: Icon(icon, color: color),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                disabledForegroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isLarge ? 15 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B76F7), Color(0xFF4564E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 58,
            color: Colors.white,
          ),
          SizedBox(height: 14),
          Text(
            'No events available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Please check again later for upcoming community health events.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B76F7), Color(0xFF4564E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off_rounded,
            size: 54,
            color: Colors.white,
          ),
          const SizedBox(height: 14),
          Text(
            'No $selectedFilter events',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try another filter or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  final Future<bool> Function() onJoin;
  final Future<bool> Function() onLeave;

  final String typeText;
  final String statusText;
  final String descriptionText;
  final String imageUrl;
  final String dateText;
  final String timeText;
  final String locationText;
  final String organizerName;
  final String joinStatus;
  final bool isClosed;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.onJoin,
    required this.onLeave,
    required this.typeText,
    required this.statusText,
    required this.descriptionText,
    required this.imageUrl,
    required this.dateText,
    required this.timeText,
    required this.locationText,
    required this.organizerName,
    required this.joinStatus,
    required this.isClosed,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool isSubmitting = false;

  Color get typeColor => _typeColor(widget.typeText);
  Color get statusColor => _statusColor(widget.statusText);

  static Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical mission':
        return _kRed;
      case 'training':
        return _kPrimary;
      case 'seminar':
        return _kAccent;
      case 'community outreach':
        return _kGreen;
      default:
        return _kGray;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical mission':
        return Icons.health_and_safety_rounded;
      case 'training':
        return Icons.school_rounded;
      case 'seminar':
        return Icons.record_voice_over_rounded;
      case 'community outreach':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return _kGreen;
      case 'completed':
      case 'done':
        return _kGray;
      case 'cancelled':
        return _kRed;
      case 'upcoming':
      default:
        return _kPrimary;
    }
  }

  Future<void> _submitJoin() async {
    setState(() => isSubmitting = true);

    final success = await widget.onJoin();

    if (!mounted) return;

    setState(() => isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => isSubmitting = true);

    final success = await widget.onLeave();

    if (!mounted) return;

    setState(() => isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHero(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title.isEmpty
                              ? 'Untitled Event'
                              : widget.event.title,
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _detailBadge(
                              text: widget.typeText,
                              color: typeColor,
                              icon: _typeIcon(widget.typeText),
                            ),
                            const SizedBox(width: 8),
                            _detailBadge(
                              text: widget.statusText,
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle('Description'),
                        const SizedBox(height: 10),
                        Text(
                          widget.descriptionText,
                          style: const TextStyle(
                            color: _kTextSecondary,
                            fontSize: 14,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle('Event Information'),
                        const SizedBox(height: 12),
                        _infoTile(
                          icon: Icons.calendar_month_rounded,
                          title: 'Date',
                          value: widget.dateText,
                        ),
                        _infoTile(
                          icon: Icons.access_time_rounded,
                          title: 'Time',
                          value: widget.timeText,
                        ),
                        _infoTile(
                          icon: Icons.location_on_rounded,
                          title: 'Location',
                          value: widget.locationText,
                        ),
                        _infoTile(
                          icon: Icons.groups_rounded,
                          title: 'Participants',
                          value:
                              '${widget.event.participants.length} participants joined',
                        ),
                        const SizedBox(height: 18),
                        _organizerCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _stickyFooter(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 290,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.imageUrl.isNotEmpty
                ? Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroGradient(),
                  )
                : _heroGradient(),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.38),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 46,
            left: 16,
            child: Material(
               child: Container(
              decoration: BoxDecoration(
  gradient: const LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF2F5FF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: _kPrimary.withValues(alpha: 0.16),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ],
),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: _kTextPrimary,
                  ),
                ),
              ),
            ),
          ),
          )
        ],
      ),
    );
  }

  Widget _heroGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            typeColor,
            _kAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -30,
            child: Icon(
              _typeIcon(widget.typeText),
              color: Colors.white.withValues(alpha: 0.13),
              size: 180,
            ),
          ),
          Center(
            child: Icon(
              _typeIcon(widget.typeText),
              size: 76,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _kTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _detailBadge({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _kPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _organizerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _kPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: _kPrimary,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Organized by: ',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: widget.organizerName,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyFooter() {
    final status = widget.statusText.toLowerCase();
    final joinStatus = widget.joinStatus;

    String text;
    IconData icon;
    Color color;
    bool canJoin = false;

    if (status == 'completed' || status == 'done') {
      text = 'Event Completed';
      icon = Icons.event_available_rounded;
      color = _kGray;
    } else if (status == 'cancelled') {
      text = 'Event Cancelled';
      icon = Icons.cancel_rounded;
      color = _kRed;
    } else if (joinStatus == 'Pending') {
      text = 'Your request is pending approval';
      icon = Icons.hourglass_top_rounded;
      color = _kOrange;
    } else if (joinStatus == 'Approved') {
      text = 'You are approved to attend ✓';
      icon = Icons.verified_rounded;
      color = _kGreen;
    } else if (joinStatus == 'Rejected') {
      text = 'Your request was rejected';
      icon = Icons.block_rounded;
      color = _kRed;
    } else if (widget.isClosed) {
      text = 'Registration Closed';
      icon = Icons.lock_clock_rounded;
      color = _kGray;
    } else {
      text = 'Submit Join Request';
      icon = Icons.how_to_reg_rounded;
      color = _kPrimary;
      canJoin = true;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: canJoin && !isSubmitting ? _submitJoin : null,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon),
                label: Text(isSubmitting ? 'Please wait...' : text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  disabledBackgroundColor: color.withValues(alpha: 0.70),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            if (joinStatus == 'Pending') ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: isSubmitting ? null : _cancelRequest,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel join request'),
                style: TextButton.styleFrom(
                  foregroundColor: _kRed,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}