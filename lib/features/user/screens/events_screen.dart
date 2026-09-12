// RAMHIS EventsWidget + EventDetailScreen — visual redesign only.
// Existing API, Socket.IO, filtering, search, join/leave, delete confirmation,
// maps, navigation, and event-status logic are preserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/models/event_model.dart';
import 'package:ramhis_app/services/api/event_service.dart';

// Shared helpers (date parsing / success-check / title casing), also used
// by home_screen.dart, so both stay in sync. Adjust the path to match
// wherever you place event_helpers.dart in your project.
import 'package:ramhis_app/utils/event_helpers.dart';

// RAMHIS medical blue theme.
const _kPrimary = Color(0xFF10539B);
const _kPrimaryDark = Color(0xFF1863B5);
const _kPrimarySoft = Color(0xFFEBF3FA);
const _kPrimaryLight = Color(0xFFE3F2FD);
const _kPrimaryTint = Color(0xFFF8FAFC);

const _kAccent = Color(0xFFFFB800);
const _kAccentBg = Color(0xFFFFF7D6);

const _kSurface = Color(0xFFFFFFFF);
const _kBg = Color(0xFFF8FAFC);
const _kCardBorder = Color(0xFFE2E8F0);
const _kDivider = Color(0xFFE5EAF0);

const _kTextPrimary = Color(0xFF102A43);
const _kTextSecondary = Color(0xFF526579);
const _kTextMuted = Color(0xFF8292A6);
const _kGray = Color(0xFF8292A6);

const _kGreen = Color(0xFF22A06B);
const _kGreenBg = Color(0xFFE8F7F0);
const _kOrange = Color(0xFFFFB800);
const _kOrangeBg = Color(0xFFFFF7D6);
const _kRed = Color(0xFFD95C5C);
const _kRedBg = Color(0xFFFFEFEF);
const _kInfo = Color(0xFF1863B5);

const _kChartBlue = Color(0xFF5D8FC8);
const _kChartSky = Color(0xFF4A9BD5);
const _kChartRose = Color(0xFFE58B8B);

const _kBlueAccent = Color(0xFF8EC1DA);
const _kBlueAccentSoft = Color(0xFFE3F2FD);
const _kNavy = Color(0xFF10539B);
const _kCream = Color(0xFFFFFFFF);
const _kWarmSurface = Color(0xFFFFFFFF);


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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    _statusTimer?.cancel();
    _socket?.off('events_updated');
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _openLocationInMaps(String location) async {
    if (location.trim().isEmpty) return;

    final encoded = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );

    try {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('❌ Failed to open maps: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Maps'),
        ),
      );
    }
  }

  void _connectSocket() {
  _socket = io.io(
    AppConfig.socketBaseUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  );

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

  _socket?.onConnectError((error) {
    debugPrint('❌ Events socket connection error: $error');
  });

  _socket?.onError((error) {
    debugPrint('❌ Events socket error: $error');
  });

  _socket?.connect();
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

  // FIX: uses shared isEventActionSuccessful instead of a loose local
  // check, so join/leave/delete responses are no longer treated as
  // successful just because the payload happens to include a `message`
  // field (which many error responses also have).
  bool _isSuccess(Map<String, dynamic> result) => isEventActionSuccessful(result);

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

    // A past event is closed even if its status/registrationOpen has not
    // yet been updated by the server.
    return status == 'completed' ||
        status == 'cancelled' ||
        status == 'done' ||
        !event.registrationOpen ||
        isPastEventDate(event);
  }

  List<EventModel> get filteredEvents {
    // 1. Apply status filter
    List<EventModel> filtered = selectedFilter == 'All'
        ? List.from(events)
        : events.where((event) {
            return _statusText(event).toLowerCase() ==
                selectedFilter.toLowerCase();
          }).toList();

    // 2. Apply search query across all event fields
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
            _descriptionText(event).toLowerCase().contains(query) ||
            _typeText(event).toLowerCase().contains(query) ||
            _statusText(event).toLowerCase().contains(query) ||
            _eventDate(event).toLowerCase().contains(query) ||
            _eventTime(event).toLowerCase().contains(query) ||
            _eventLocation(event).toLowerCase().contains(query) ||
            _organizerName(event).toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
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

  // FIX: now delegates to the shared formatEventDateDisplay so this
  // matches home_screen.dart's date formatting/fallback exactly.
  String _eventDate(EventModel event) => formatEventDateDisplay(event);

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

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical mission':
        return _kInfo;
      case 'training':
        return _kPrimary;
      case 'seminar':
        return _kChartSky;
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
                    color: _kRed,
                    backgroundColor: _kCream,
                    onRefresh: _loadEvents,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 28),
                      children: [
                        _buildFilterTabs(),
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                        const SizedBox(height: 15),
                        if (events.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _buildEmptyState(),
                          )
                        else if (list.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _searchQuery.isNotEmpty
                                ? _buildSearchEmptyState()
                                : _buildFilteredEmptyState(),
                          )
                        else
                          Column(
                            children: list.map(_buildSwipeableEventCard).toList(),
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
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
      decoration: const BoxDecoration(
        color: _kCream,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Community',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2B2523),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'EVENTS • MEDICAL MISSIONS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.85,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: _kBg,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _loadEvents,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: _kPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 43,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _kWarmSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _kPrimary.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: filters.map((filter) {
                final selected = selectedFilter == filter;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? _kOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: selected ? Colors.white : _kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return const SizedBox.shrink();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _kWarmSurface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _kTextPrimary.withValues(
              alpha: _searchQuery.isNotEmpty ? 0.34 : 0.12,
            ),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: Color(0xFF2B2523),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _kTextPrimary,
              size: 20,
            ),
            hintText: 'Search events...',
            hintStyle: const TextStyle(
              color: _kTextSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _kTextSecondary,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      itemBuilder: (_, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 116,
          decoration: BoxDecoration(
            color: _kWarmSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kPrimary.withValues(alpha: 0.10),
            ),
          ),
        );
      },
    );
  }

  // Swipe left to quickly remove an event schedule.
  Widget _buildSwipeableEventCard(EventModel event) {
    return Dismissible(
      key: ValueKey('event_${event.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.45,
      },
      background: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: _kRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await _confirmRemoveEvent(event);
      },
      resizeDuration: const Duration(milliseconds: 250),
      child: _buildEventCard(event),
    );
  }

  Future<bool> _confirmRemoveEvent(EventModel event) async {
    final eventTitle = titleCaseEventText(
      event.title.trim().isNotEmpty ? event.title : 'Untitled Event',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Event?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Are you sure you want to remove "$eventTitle"?\n\n'
            'This will permanently remove this event schedule.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Remove',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    return await _removeEvent(event);
  }

  // NOTE: this calls EventService.deleteEvent — a permanent, global
  // delete — from a user-facing swipe gesture. Confirm this is intended
  // (vs. a per-user "leave/unregister" action) and that the backend
  // route is properly restricted to admins before shipping this as-is.
  Future<bool> _removeEvent(EventModel event) async {
    try {
      final result = await EventService.deleteEvent(event.id);

      final success = _isSuccess(result);

      if (!mounted) return success;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${titleCaseEventText(event.title)} removed successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['message'] ?? 'Failed to remove event.').toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return success;
    } catch (error) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove event: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }
  }

  Widget _buildEventCard(EventModel event) {
    final joinStatus = _joinStatus(event);
    final isPastDate = isPastEventDate(event);
    final imageUrl = _imageUrl(event).trim();
    final type = _typeText(event);
    final status = _statusText(event);
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: _kWarmSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _kPrimary.withValues(alpha: 0.22),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEventDetails(event),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 9, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            titleCaseEventText(
                              event.title.isNotEmpty
                                  ? event.title
                                  : 'Untitled Event',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF171313),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _statusPill(status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _eventMetaRow(
                      Icons.calendar_month_rounded,
                      _eventDate(event),
                    ),
                    const SizedBox(height: 5),
                    _eventMetaRow(
                      Icons.location_on_rounded,
                      _eventLocation(event),
                      maxLines: 2,
                    ),
                    if (type.trim().isNotEmpty &&
                        type.toLowerCase() != 'other') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor(type).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: _typeColor(type),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                    if (joinStatus == 'Approved' ||
                        joinStatus == 'Pending' ||
                        joinStatus == 'Rejected' ||
                        (joinStatus == 'None' && isPastDate)) ...[
                      const SizedBox(height: 7),
                      _missionBadge(joinStatus, isPastDate),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventThumbnail(
    EventModel event,
    String imageUrl,
    String type,
  ) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kBg,
        border: Border.all(
          color: _kPrimary.withValues(alpha: 0.28),
          width: 1.3,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _eventBannerFallback(type),
            )
          : _eventBannerFallback(type),
    );
  }

  Widget _eventMetaRow(
    IconData icon,
    String text, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _kTextPrimary, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3B302D),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventBannerFallback(String type) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimarySoft, _kPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _typeIcon(type),
          color: _kTextPrimary,
          size: 34,
        ),
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _missionBadge(String joinStatus, bool isPastDate) {
    late String text;
    late Color color;
    IconData icon;

    if (joinStatus == 'Approved') {
      text = 'Approved for this mission ✓';
      color = _kGreen;
      icon = Icons.verified_rounded;
    } else if (joinStatus == 'Pending') {
      text = 'Pending for this mission';
      color = _kOrange;
      icon = Icons.hourglass_top_rounded;
    } else if (joinStatus == 'Rejected') {
      text = 'Rejected for this mission';
      color = _kRed;
      icon = Icons.block_rounded;
    } else {
      text = 'Event date passed';
      color = _kGray;
      icon = Icons.event_busy_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
      decoration: BoxDecoration(
        color: _kWarmSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kPrimary.withValues(alpha: 0.18),
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 52, color: _kTextPrimary),
          SizedBox(height: 14),
          Text(
            'No events available',
            style: TextStyle(
              color: Color(0xFF2B2523),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Please check again later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: _kWarmSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off_rounded,
            size: 50,
            color: _kTextPrimary,
          ),
          const SizedBox(height: 13),
          Text(
            'No $selectedFilter events',
            style: const TextStyle(
              color: Color(0xFF2B2523),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try another filter or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: _kWarmSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _kPrimarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 31,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No results found',
            style: TextStyle(
              color: Color(0xFF2B2523),
              fontSize: 17.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No events matched "$_searchQuery".\nTry a different keyword.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Clear search',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
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
  MapLibreMapController? _mapController;

  Color get typeColor => _typeColor(widget.typeText);
  Color get statusColor => _statusColor(widget.statusText);

  Widget _mapPreview() {
    final double? latitude = widget.event.latitude;
    final double? longitude = widget.event.longitude;

    final bool hasValidCoordinates = latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;

    Future<void> openGoogleMaps() async {
      if (!hasValidCoordinates) return;

      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('❌ Failed to open Google Maps: $e');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Google Maps'),
          ),
        );
      }
    }

    return Container(
      height: 190,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasValidCoordinates
          ? Stack(
              children: [
                MapLibreMap(
                  styleString: 'https://tiles.openfreemap.org/styles/liberty',
                  initialCameraPosition: CameraPosition(
                    target: LatLng(latitude, longitude),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onStyleLoadedCallback: () async {
                    if (_mapController == null) return;

                    try {
                      await _mapController!.addSymbol(
                        SymbolOptions(
                          geometry: LatLng(latitude, longitude),
                          iconImage: 'marker-15',
                          iconSize: 1.8,
                        ),
                      );
                    } catch (e) {
                      debugPrint('❌ Failed to add MapLibre marker: $e');
                    }
                  },
                  myLocationEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                ),
                const Center(
                  child: IgnorePointer(
                    child: Icon(
                      Icons.location_pin,
                      color: _kRed,
                      size: 44,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.event.location.isNotEmpty
                                ? widget.event.location
                                : 'Event location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: openGoogleMaps,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Google Maps',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Text(
                'No coordinates available',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  static Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical mission':
        return _kInfo;
      case 'training':
        return _kPrimary;
      case 'seminar':
        return _kChartSky;
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
          _detailHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          titleCaseEventText(
                            widget.event.title.isEmpty
                                ? 'Untitled Event'
                                : widget.event.title,
                          ),
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (widget.joinStatus != 'None') ...[
                        const SizedBox(width: 10),
                        _detailBadge(
                          text: widget.joinStatus == 'Approved'
                              ? 'Approved ✓'
                              : widget.joinStatus,
                          color: _joinStatusColor(widget.joinStatus),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.descriptionText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _mapPreview(),
                  const SizedBox(height: 22),
                  _infoCard(),
                  const SizedBox(height: 22),
                  _sectionTitle('Description'),
                  const SizedBox(height: 10),
                  Text(
                    widget.descriptionText,
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Organizers'),
                  const SizedBox(height: 12),
                  _organizerCard(),
                ],
              ),
            ),
          ),
          _stickyFooter(),
        ],
      ),
    );
  }

  Widget _detailHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 48, 18, 18),
      decoration: const BoxDecoration(
        color: _kCream,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kTextPrimary,
              ),
            ),
          ),
          const Text(
            'Event Details',
            style: TextStyle(
              color: Color(0xFF2B2523),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlueAccentSoft.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoTile(
            icon: Icons.calendar_month_rounded,
            title: 'Date',
            value: widget.dateText,
            color: _kBlueAccent,
          ),
          _infoTile(
            icon: Icons.access_time_rounded,
            title: 'Time',
            value: widget.timeText,
            color: _kOrange,
          ),
          _infoTile(
            icon: Icons.location_on_rounded,
            title: 'Location',
            value: widget.locationText,
            color: _kRed,
            actionText: 'View on map',
            onTap: () => _openLocationInMaps(widget.locationText),
          ),
          _infoTile(
            icon: Icons.groups_rounded,
            title: 'Participants',
            value: '${widget.event.participants.length} joined',
            color: _kGreen,
          ),
          _infoTile(
            icon: Icons.person_rounded,
            title: 'Created By',
            value: widget.organizerName,
            color: _kPrimary,
          ),
          _infoTile(
            icon: _typeIcon(widget.typeText),
            title: 'Event Type',
            value: widget.typeText,
            color: typeColor,
            badgeValue: widget.typeText,
          ),
          _infoTile(
            icon: Icons.verified_rounded,
            title: 'Status',
            value: widget.statusText,
            color: statusColor,
            badgeValue: widget.statusText,
          ),
        ],
      ),
    );
  }
  Future<void> _openLocationInMaps(String location) async {
    if (location.trim().isEmpty) return;

    final encoded = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );

    try {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('❌ Failed to open maps: $e');
    }
  }

  Color _joinStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _kGreen;
      case 'pending':
        return _kOrange;
      case 'rejected':
        return _kRed;
      default:
        return _kGray;
    }
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
    return Container(
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
          Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? actionText,
    VoidCallback? onTap,
    String? badgeValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
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
                const SizedBox(height: 4),
                if (badgeValue != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _detailBadge(
                      text: badgeValue,
                      color: color,
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                if (actionText != null) ...[
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      actionText,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _organizerCard() {
    final initial = widget.organizerName.trim().isNotEmpty
        ? widget.organizerName.trim()[0].toUpperCase()
        : 'R';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlueAccentSoft.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _kNavy,
            child: Text(
              initial,
              style: const TextStyle(
                color: _kBlueAccentSoft,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.organizerName,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Organizer',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: _kBlueAccent, size: 20),
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
      text = 'Cancel join request';
      icon = Icons.cancel_rounded;
      color = _kRed;
    } else if (joinStatus == 'Pending') {
      text = 'Request Pending';
      icon = Icons.hourglass_top_rounded;
      color = _kOrange;
    } else if (joinStatus == 'Approved') {
      text = 'Approved for: ${titleCaseEventText(widget.event.title)} ✓';
      icon = Icons.verified_rounded;
      color = _kGreen;
    } else if (joinStatus == 'Rejected') {
      text = 'Rejected';
      icon = Icons.block_rounded;
      color = _kRed;
    } else if (isPastEventDate(widget.event)) {
      text = 'Event Date Passed';
      icon = Icons.event_busy_rounded;
      color = _kGray;
    } else if (widget.isClosed) {
      text = 'Registration Closed';
      icon = Icons.lock_clock_rounded;
      color = _kGray;
    } else {
      text = 'Join Event';
      icon = Icons.how_to_reg_rounded;
      color = _kNavy;
      canJoin = true;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: _kBlueAccentSoft, width: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.08),
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
            SizedBox(
              width: double.infinity,
              height: 54,
              child: canJoin
                  ? ElevatedButton.icon(
                      onPressed: isSubmitting ? null : _submitJoin,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kBlueAccentSoft,
                              ),
                            )
                          : Icon(icon, color: _kBlueAccentSoft),
                      label: Text(isSubmitting ? 'Please wait...' : text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        disabledBackgroundColor: color.withValues(alpha: 0.70),
                        foregroundColor: _kBlueAccentSoft,
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                          side: const BorderSide(color: _kBlueAccent, width: 1),
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(icon, color: color),
                      label: Text(text),
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: color,
                        side: BorderSide(color: color, width: 1.3),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
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
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
