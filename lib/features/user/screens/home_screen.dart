import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/features/user/widgets/loading_view.dart';
import 'package:ramhis_app/services/api/analytics_service.dart';
import 'package:ramhis_app/services/api/event_service.dart';
import 'package:ramhis_app/models/event_model.dart';
import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/features/user/screens/events_screen.dart';

// Shared helpers (date parsing / success-check), deduplicated so this file
// and events_widget.dart don't diverge. Adjust the path below to match
// where you place event_helpers.dart in your project.
import 'package:ramhis_app/utils/event_helpers.dart';

// IMPORTANT:
// Use the actual file where EventDetailScreen is defined.

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
abstract class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS & GRAPH GRAPHICS
// ─────────────────────────────────────────────────────────────────────────────

class _PatientBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<Color> colors;
  final double maxValue;
  final num Function(Map<String, dynamic>?, List<String>) readNumber;

  const _PatientBarChart({
    required this.data,
    required this.colors,
    required this.maxValue,
    required this.readNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(left: 40, right: 4, top: 10, bottom: 4),
          child: _buildChart(
            safeMax,
            constraints.maxHeight,
            constraints.maxWidth - 44, // account for left axis padding
          ),
        );
      },
    );
  }

  Widget _buildChart(double safeMax, double chartHeight, double availableWidth) {
    const topLabelHeight = 26.0;
    const bottomLabelHeight = 24.0;
    const gap = 6.0;

    final availableBarHeight = math
        .max(30.0, chartHeight - topLabelHeight - bottomLabelHeight - gap)
        .toDouble();

    // Dynamically size each bar column so all bars fit within availableWidth,
    // no matter how many months are shown.
    final columnWidth = (availableWidth / data.length).clamp(24.0, 64.0);
    final barWidth = (columnWidth * 0.5).clamp(8.0, 26.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: topLabelHeight,
          height: availableBarHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              5,
              (_) => Container(
                width: double.infinity,
                height: 1,
                color: AppColors.cardBorder.withOpacity(0.6),
              ),
            ),
          ),
        ),
        Positioned(
          left: -38,
          top: topLabelHeight - 6,
          width: 32,
          height: availableBarHeight + 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _axisText(safeMax),
              _axisText(safeMax * 0.75),
              _axisText(safeMax * 0.50),
              _axisText(safeMax * 0.25),
              _axisText(0),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final value =
                  readNumber(item, ['count', 'patients', 'total', 'value'])
                      .toDouble();

              final label = '${item['clinic'] ?? 'Unknown'}';
              final normalizedHeight = (value / safeMax).clamp(0.0, 1.0);
              final baseColor = colors[index % colors.length];

              return SizedBox(
                width: columnWidth,
                height: chartHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: topLabelHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: value > 0
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: baseColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatNumber(value),
                                    style: TextStyle(
                                      color: baseColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    SizedBox(
                      height: availableBarHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: barWidth,
                          height: math.max(
                            value > 0 ? 8.0 : 3.0,
                            availableBarHeight * normalizedHeight,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: baseColor.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                baseColor.withOpacity(0.85),
                                baseColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: gap),
                    SizedBox(
                      height: bottomLabelHeight,
                      child: Center(
                        child: Text(
                          _shortLabel(label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _axisText(double value) {
    return Text(
      _formatNumber(value),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return value.round().toString();
  }

  String _shortLabel(String label) {
    if (label.length <= 4) return label;

    final lower = label.toLowerCase();

    const months = {
      'january': 'Jan',
      'february': 'Feb',
      'march': 'Mar',
      'april': 'Apr',
      'may': 'May',
      'june': 'Jun',
      'july': 'Jul',
      'august': 'Aug',
      'september': 'Sep',
      'october': 'Oct',
      'november': 'Nov',
      'december': 'Dec'
    };

    return months[lower] ?? label.substring(0, 4);
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({
    required this.values,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final path = Path();
    final step = size.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final x = i * step;
      final y =
          size.height - (values[i].clamp(0.0, 1.0) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final previousX = (i - 1) * step;
        final previousY =
            size.height -
            (values[i - 1].clamp(0.0, 1.0) * size.height);

        final controlX = (previousX + x) / 2;

        path.cubicTo(
          controlX,
          previousY,
          controlX,
          y,
          x,
          y,
        );
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  bool _showAllTrends = false;

  String _searchQuery = '';
  final TextEditingController _searchController =
      TextEditingController();

  String? errorMessage;

  Map<String, dynamic>? summary;

  List<Map<String, dynamic>> patientsPerClinic = [];
  List<Map<String, dynamic>> mostUsedMedicines = [];
  List<Map<String, dynamic>> keyDrivers = [];

  // ─────────────────────────────────────────────
// HOME EVENT NOTIFICATIONS
// ─────────────────────────────────────────────

List<EventModel> _homeEvents = [];

/// Keeps Home event notifications alive when the
/// HomeScreen widget is recreated while navigating
/// between Home, Events, Chat, and Account.
static final List<EventModel>
    _persistentRecentEventNotifications =
    <EventModel>[];

/// Keeps manually dismissed notifications dismissed
/// when HomeScreen is recreated.
static final Set<String>
    _persistentDismissedHomeEventIds =
    <String>{};

List<EventModel> _recentEventNotifications =
    <EventModel>[];

final Set<String> _dismissedHomeEventIds =
    <String>{};

io.Socket? _eventSocket;

static const int _maxRecentEventNotifications = 3;

bool _homeEventsInitialized = false;

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  @override
void initState() {
  super.initState();

  // Restore the Home notification state when this screen
  // is recreated after navigating between tabs.
  _recentEventNotifications =
      List<EventModel>.from(
    _persistentRecentEventNotifications,
  );

  _dismissedHomeEventIds
      .addAll(
    _persistentDismissedHomeEventIds,
  );

  _loadHomeAnalytics();
  _startHomeEvents();
}

  Future<void> _startHomeEvents() async {
    await _initializeHomeEvents();
    _connectHomeEventSocket();
  }

  // ─────────────────────────────────────────────
  // EVENT INITIALIZATION
  // ─────────────────────────────────────────────

  Future<void> _initializeHomeEvents() async {
    try {
      final events = await EventService.getEvents();

      if (!mounted) return;

      setState(() {
        _homeEvents = List<EventModel>.from(events);
        _homeEventsInitialized = true;
      });

      debugPrint(
        'Home loaded ${_homeEvents.length} events',
      );
    } catch (e) {
      debugPrint(
        'Failed to initialize Home events: $e',
      );

      if (mounted) {
        setState(
          () => _homeEventsInitialized = true,
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // SOCKET CONNECTION
  // ─────────────────────────────────────────────

  void _connectHomeEventSocket() {
    _eventSocket = io.io(
      AppConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _eventSocket?.connect();

    _eventSocket?.onConnect((_) {
      debugPrint(
        'Home connected to event socket',
      );
    });

    _eventSocket?.on(
      'events_updated',
      _handleHomeEventsUpdated,
    );

    _eventSocket?.onDisconnect((_) {
      debugPrint(
        'Home disconnected from event socket',
      );
    });

    _eventSocket?.onConnectError((error) {
      debugPrint(
        'Home socket connection error: $error',
      );
    });

    _eventSocket?.onError((error) {
      debugPrint(
        'Home socket error: $error',
      );
    });
  }

  // ─────────────────────────────────────────────
// DETECT NEW EVENTS
// ─────────────────────────────────────────────

int _eventsUpdateRequestId = 0;

Future<void> _handleHomeEventsUpdated(
  dynamic socketData,
) async {
  if (!_homeEventsInitialized) {
    debugPrint(
      'Home received events_updated before init — ignoring',
    );
    return;
  }

  final requestId = ++_eventsUpdateRequestId;

  try {
    debugPrint(
      'Home received events_updated',
    );

    final updatedEvents =
        await EventService.getEvents();

    if (!mounted) return;

    if (requestId != _eventsUpdateRequestId) {
      debugPrint(
        'Home dropping stale events_updated response',
      );
      return;
    }

    final oldIds =
        _homeEvents.map((event) => event.id).toSet();

    final updatedIds =
        updatedEvents.map((event) => event.id).toSet();

    // Detect only genuinely NEW events.
    //
    // Events that were manually dismissed with X
    // must never be added again.
    final newEvents = updatedEvents
        .where(
          (event) =>
              !oldIds.contains(event.id) &&
              !_dismissedHomeEventIds.contains(event.id),
        )
        .toList();

    debugPrint(
      'Home detected ${newEvents.length} new event(s)',
    );

    setState(() {
      // Always keep the latest event information.
      _homeEvents =
          List<EventModel>.from(updatedEvents);

      // Remove notifications only if the event
      // no longer exists in the backend.
      _recentEventNotifications.removeWhere(
        (event) =>
            !updatedIds.contains(event.id),
      );

      // Refresh existing notifications using
      // the latest backend event data.
      _recentEventNotifications =
          _recentEventNotifications.map((existing) {
        return updatedEvents.firstWhere(
          (updated) =>
              updated.id == existing.id,
          orElse: () => existing,
        );
      }).toList();

      // Add genuinely NEW events.
      //
      // Opening Event Details does NOT remove them.
      // Only pressing X adds the event to the
      // dismissed set.
      for (final event in newEvents) {
        if (_dismissedHomeEventIds.contains(event.id)) {
          continue;
        }

        _recentEventNotifications.removeWhere(
          (existing) =>
              existing.id == event.id,
        );

        _recentEventNotifications.insert(
          0,
          event,
        );
      }

      // Keep only the latest three notifications.
      if (_recentEventNotifications.length >
          _maxRecentEventNotifications) {
        _recentEventNotifications =
            _recentEventNotifications
                .take(_maxRecentEventNotifications)
                .toList();
      }

      // Persist notification state so it survives
      // HomeScreen recreation when navigating between
      // Home, Events, Chat, and Account.
      _persistentRecentEventNotifications
        ..clear()
        ..addAll(
          _recentEventNotifications,
        );

      _persistentDismissedHomeEventIds
        ..clear()
        ..addAll(
          _dismissedHomeEventIds,
        );
    });
  } catch (e) {
    debugPrint(
      'Failed to handle Home events_updated: $e',
    );
  }
}

  // ─────────────────────────────────────────────
  // HOME EVENT NOTIFICATION SECTION
  // ─────────────────────────────────────────────

  Widget _buildRecentEventNotifications() {
    if (_recentEventNotifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      title: 'New Events',
      icon: Icons.notifications_active_outlined,
      child: Column(
        children: _recentEventNotifications
            .map(
              (event) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child:
                    _buildEventNotificationRow(event),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEventNotificationRow(
  EventModel event,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.cardBorder,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.event_rounded,
            color: AppColors.primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER WITH X BUTTON
              Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Expanded(
      child: Text(
        'NEW EVENT',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    ),

    // X = explicitly dismiss this notification
    GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!mounted) return;

        setState(() {
          _dismissedHomeEventIds.add(event.id);

          _recentEventNotifications.removeWhere(
            (item) => item.id == event.id,
          );

          // Persist dismissal across HomeScreen rebuilds.
          _persistentDismissedHomeEventIds
            ..clear()
            ..addAll(_dismissedHomeEventIds);

          _persistentRecentEventNotifications
            ..clear()
            ..addAll(_recentEventNotifications);
        });

        debugPrint(
          'Home notification dismissed: ${event.id}',
        );
      },
      child: const Padding(
        padding: EdgeInsets.only(
          left: 8,
          bottom: 8,
        ),
        child: Icon(
          Icons.close_rounded,
          color: AppColors.textMuted,
          size: 18,
        ),
      ),
    ),
  ],
),

              const SizedBox(height: 4),

              Text(
                titleCaseEventText(
                  event.title.isNotEmpty
                      ? event.title
                      : 'Untitled Event',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.textMuted,
                    size: 12,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      formatEventDateDisplay(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
  // IMPORTANT:
  // Opening Event Details does NOT dismiss the notification.
  await _openHomeEventDetails(event);
},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Event Details',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ─────────────────────────────────────────────
  // EVENT DETAILS NAVIGATION
  // ─────────────────────────────────────────────

  Future<void> _openHomeEventDetails(
    EventModel event,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          onJoin: () =>
              _joinHomeEvent(event.id),
          onLeave: () =>
              _leaveHomeEvent(event.id),
          typeText:
              _homeTypeText(event),
          statusText:
              _homeStatusText(event),
          descriptionText:
              _homeDescriptionText(event),
          imageUrl:
              _homeImageUrl(event),
          dateText:
              formatEventDateDisplay(event),
          timeText:
              _homeEventTime(event),
          locationText:
              _homeEventLocation(event),
          organizerName:
              _homeOrganizerName(event),
          joinStatus:
              _homeJoinStatus(event),
          isClosed:
              _homeIsClosed(event),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EVENT DETAIL HELPERS
  // ─────────────────────────────────────────────

  String _homeTypeText(EventModel event) {
    final type = event.type.trim();
    return type.isNotEmpty ? type : 'Other';
  }

  String _homeStatusText(EventModel event) {
    final status = event.status.trim();

    if (status.isEmpty) {
      return 'Upcoming';
    }

    if (status.toLowerCase() == 'done') {
      return 'Completed';
    }

    return status;
  }

  String _homeDescriptionText(
    EventModel event,
  ) {
    final description =
        event.description.trim();

    return description.isNotEmpty
        ? description
        : 'No description provided for this event.';
  }

  String _homeImageUrl(EventModel event) =>
      event.imageUrl.trim();

  String _homeEventTime(EventModel event) {
    final start = event.startTime.trim();
    final end = event.endTime.trim();

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    }

    if (event.callTime.trim().isNotEmpty) {
      return event.callTime;
    }

    return 'Time to be announced';
  }

  String _homeEventLocation(
    EventModel event,
  ) {
    if (event.location.trim().isNotEmpty) {
      return event.location;
    }

    if (event.meetingPlace.trim().isNotEmpty) {
      return event.meetingPlace;
    }

    return 'Location to be announced';
  }

  String _homeOrganizerName(
    EventModel event,
  ) {
    return 'RAMHIS Admin';
  }

  String _homeJoinStatus(
    EventModel event,
  ) {
    final status =
        event.joinStatus.trim();

    if (status.isNotEmpty &&
        status.toLowerCase() != 'none') {
      return status;
    }

    final participantStatus =
        event.participantStatus.trim();

    if (participantStatus.isNotEmpty &&
        participantStatus.toLowerCase() !=
            'none') {
      return participantStatus;
    }

    if (event.alreadyJoined) {
      return 'Pending';
    }

    return 'None';
  }

  bool _homeIsClosed(
    EventModel event,
  ) {
    final status =
        event.status.toLowerCase();

    return status == 'completed' ||
        status == 'cancelled' ||
        status == 'done' ||
        !event.registrationOpen ||
        isPastEventDate(event);
  }

  // ─────────────────────────────────────────────
  // JOIN / LEAVE EVENT
  // ─────────────────────────────────────────────

  Future<bool> _joinHomeEvent(
    String eventId,
  ) async {
    try {
      final result =
          await EventService.registerForEvent(
        eventId,
      );

      final success =
          isEventActionSuccessful(result);

      if (success) {
        await _loadRecentEventsFromApi();
      }

      return success;
    } catch (e) {
      debugPrint(
        'Failed to join event: $e',
      );
      return false;
    }
  }

  Future<bool> _leaveHomeEvent(
    String eventId,
  ) async {
    try {
      final result =
          await EventService.leaveEvent(
        eventId,
      );

      final success =
          isEventActionSuccessful(result);

      if (success) {
        await _loadRecentEventsFromApi();
      }

      return success;
    } catch (e) {
      debugPrint(
        'Failed to leave event: $e',
      );
      return false;
    }
  }

  Future<void> _loadRecentEventsFromApi() async {
    try {
      final events =
          await EventService.getEvents();

      if (!mounted) return;

      setState(() {
        _homeEvents =
            List<EventModel>.from(events);
      });
    } catch (e) {
      debugPrint(
        'Failed to refresh Home events: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  @override
  void dispose() {
    _eventSocket?.off(
      'events_updated',
      _handleHomeEventsUpdated,
    );

    _eventSocket?.disconnect();
    _eventSocket?.dispose();

    _searchController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // ANALYTICS HELPERS
  // ─────────────────────────────────────────────

  num _readNumber(
    Map<String, dynamic>? map,
    List<String> keys,
  ) {
    if (map == null) return 0;

    for (final key in keys) {
      final value = map[key];

      if (value is num) {
        return value;
      }

      if (value is String) {
        return num.tryParse(value) ?? 0;
      }
    }

    return 0;
  }

  String _readString(
    Map<String, dynamic>? map,
    List<String> keys,
  ) {
    if (map == null) return '';

    for (final key in keys) {
      final value = map[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic>? response,
    List<String> keys,
  ) {
    if (response == null) return [];

    for (final key in keys) {
      final value = response[key];

      if (value is List) {
        return value
            .whereType<Map>()
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();
      }
    }

    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) =>
                Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is List) {
          return value
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                      item,
                    ),
              )
              .toList();
        }
      }
    }

    return [];
  }

  // ─────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────

  Future<void> _loadHomeAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final responses =
          await Future.wait<
              Map<String, dynamic>?>(
        [
          AnalyticsService.getDashboardSummary(),
          AnalyticsService.getPatientTrends(),
          AnalyticsService
              .getDiagnosisDistribution(),
          AnalyticsService.getTopMedicines(),
        ],
      );

      final dashboardSummary = responses[0];
      final patientTrends = responses[1];
      final diagnosisDistribution =
          responses[2];
      final topMedicines = responses[3];

      if (dashboardSummary == null &&
          patientTrends == null &&
          diagnosisDistribution == null &&
          topMedicines == null) {
        _loadFallbackData();
        return;
      }

      // ─────────────────────────────────────────
      // DASHBOARD SUMMARY
      // ─────────────────────────────────────────

      final dashboardData =
          dashboardSummary?['data'] is Map
              ? Map<String, dynamic>.from(
                  dashboardSummary?['data'],
                )
              : dashboardSummary;

      final totalPatients = _readNumber(
        dashboardData,
        [
          'totalPatients',
          'patients',
          'patientCount',
          'totalPatientCount',
        ],
      );

      // IMPORTANT:
      // /dashboard/summary does not provide
      // prescriptionVolume. The backend's
      // /dashboard/patient-trends endpoint
      // already provides monthly prescription
      // counts, so we calculate the total from
      // that same source.
      final healthAlert = _readString(
        dashboardData,
        [
          'healthAlert',
          'alert',
          'message',
        ],
      );

      // ─────────────────────────────────────────
      // PATIENT / PRESCRIPTION TRENDS
      // ─────────────────────────────────────────

      final clinicRaw = _extractList(
        patientTrends,
        [
          'data',
          'clinics',
          'distribution',
          'patientTrends',
          'trends',
        ],
      );

      // The backend returns:
      //
      // {
      //   month: "...",
      //   patients: number,
      //   prescriptions: number,
      //   volunteers: number
      // }
      //
      // Calculate total prescriptions from
      // the exact same backend response.
      final prescriptionVolume =
          clinicRaw.fold<num>(
        0,
        (sum, item) =>
            sum +
            _readNumber(
              item,
              [
                'prescriptions',
              ],
            ),
      );

      final totalClinicCount =
          clinicRaw.fold<num>(
        0,
        (sum, item) =>
            sum +
            _readNumber(
              item,
              [
                'patients',
                'count',
                'total',
                'value',
              ],
            ),
      );

      // Keep the existing patientsPerClinic
      // variable so no other UI functionality
      // needs to change.
      //
      // Internally, it now represents the
      // monthly patient trend returned by the
      // backend.
      patientsPerClinic =
          clinicRaw.map((item) {
        final count = _readNumber(
          item,
          [
            'patients',
            'count',
            'total',
            'value',
          ],
        );

        final percentage = _readNumber(
          item,
          [
            'percentage',
            'percent',
          ],
        );

        return {
          // Existing chart expects 'clinic',
          // so keep that key but populate it
          // with the actual backend month.
          'clinic': _readString(
            item,
            [
              'month',
            ],
          ).isNotEmpty
              ? _readString(
                  item,
                  [
                    'month',
                  ],
                )
              : 'Unknown month',

          // Existing chart expects 'count'.
          // Populate it from backend 'patients'.
          'count': count,

          'percentage': percentage > 0
              ? percentage
              : totalClinicCount > 0
                  ? ((count /
                              totalClinicCount) *
                          100)
                      .round()
                  : 0,

          // Preserve the original backend
          // values so the mobile side remains
          // capable of using them later.
          'patients': count,
          'prescriptions': _readNumber(
            item,
            [
              'prescriptions',
            ],
          ),
          'volunteers': _readNumber(
            item,
            [
              'volunteers',
            ],
          ),
        };
      }).toList();

      // ─────────────────────────────────────────
      // DIAGNOSIS DISTRIBUTION
      // ─────────────────────────────────────────

      final diagnosisRaw = _extractList(
        diagnosisDistribution,
        [
          'data',
          'diagnosisDistribution',
          'diagnoses',
          'distribution',
        ],
      );

      diagnosisRaw.sort((a, b) {
        final aCount = _readNumber(
          a,
          [
            'count',
            'value',
            'total',
          ],
        );

        final bCount = _readNumber(
          b,
          [
            'count',
            'value',
            'total',
          ],
        );

        return bCount.compareTo(aCount);
      });

      final topDiagnosis =
          diagnosisRaw.isNotEmpty
              ? diagnosisRaw.first
              : null;

      final topDiagnosisName =
          _readString(
        topDiagnosis,
        [
          'name',
          'diagnosis',
          'label',
        ],
      );

      final topDiagnosisCount =
          _readNumber(
        topDiagnosis,
        [
          'count',
          'value',
          'total',
        ],
      );

      final topDiagnosisPercentage =
          _readNumber(
        topDiagnosis,
        [
          'percentage',
          'percent',
        ],
      );

      // ─────────────────────────────────────────
      // KEY DRIVERS
      // ─────────────────────────────────────────

      keyDrivers = [
        {
          'label': 'Total Patients',
          'value': totalPatients,
          'detail': 'Registered patients',
        },
        {
          'label': 'Most Common Diagnosis',
          'value': topDiagnosisName.isNotEmpty
              ? topDiagnosisName
              : 'No data',
          'detail':
              '${topDiagnosisPercentage > 0 ? topDiagnosisPercentage : topDiagnosisCount}% of records',
        },
        {
          'label': 'Prescription Volume',
          'value': prescriptionVolume,
          'detail': 'Total prescriptions',
        },
        {
          'label': 'Health Alert',
          'value': healthAlert.isNotEmpty
              ? healthAlert
              : 'No major health alert',
          'detail':
              'Monitor and prepare resources',
        },
      ];

      // ─────────────────────────────────────────
      // TOP MEDICINES
      // ─────────────────────────────────────────

      final medicinesRaw = _extractList(
        topMedicines,
        [
          'data',
          'topMedicines',
          'medicines',
          'items',
        ],
      );

      mostUsedMedicines =
          medicinesRaw.map((item) {
        final count = _readNumber(
          item,
          [
            'count',
            'total',
            'value',
            'quantity',
          ],
        );

        return {
          'name': _readString(
                    item,
                    [
                      'name',
                      'medicine',
                      'medicineName',
                      'label',
                    ],
                  ).isNotEmpty
              ? _readString(
                  item,
                  [
                    'name',
                    'medicine',
                    'medicineName',
                    'label',
                  ],
                )
              : 'Unknown medicine',

          'count': count,

          'demand': _readString(
                    item,
                    [
                      'demand',
                      'level',
                    ],
                  ).isNotEmpty
              ? _readString(
                  item,
                  [
                    'demand',
                    'level',
                  ],
                )
              : count >= 50
                  ? 'High'
                  : count >= 25
                      ? 'Moderate'
                      : 'Stable',
        };
      }).toList();

      // ─────────────────────────────────────────
      // FINAL SUMMARY STATE
      // ─────────────────────────────────────────

      setState(() {
        summary = {
          'totalPatients': totalPatients,

          // NOW SYNCED WITH REAL BACKEND
          // PATIENT-TRENDS PRESCRIPTION DATA.
          'prescriptionVolume':
              prescriptionVolume,

          'healthAlert': healthAlert.isNotEmpty
              ? healthAlert
              : 'No major health alert',

          'topDiagnosis': {
            'name': topDiagnosisName.isNotEmpty
                ? topDiagnosisName
                : 'No data',
            'count': topDiagnosisCount,
            'percentage':
                topDiagnosisPercentage,
          },
        };

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to load Home analytics: $e',
      );

      _loadFallbackData();
    }
  }

  // ─────────────────────────────────────────────
  // FALLBACK
  // ─────────────────────────────────────────────

  void _loadFallbackData() {
    setState(() {
      summary = {
        'totalPatients': 0,
        'prescriptionVolume': 0,
        'healthAlert': 'No data available',
        'topProvince': {
          'name': 'No data',
          'count': 0,
        },
        'topDiagnosis': {
          'name': 'No data',
          'count': 0,
        },
      };

      patientsPerClinic = [
        {
          'clinic': 'General Medicine',
          'count': 0,
          'percentage': 0,
        },
      ];

      mostUsedMedicines = [
        {
          'name': 'No medicine data',
          'count': 0,
          'demand': 'Stable',
        },
      ];

      keyDrivers = [
        {
          'label': 'Top Province',
          'value': 'No data',
          'detail': '0 patients',
        },
        {
          'label': 'Most Common Diagnosis',
          'value': 'No data',
          'detail': '0%',
        },
        {
          'label': 'Prescription Volume',
          'value': 0,
          'detail': 'Total prescriptions',
        },
        {
          'label': 'Health Alert',
          'value': 'No major health alert',
          'detail':
              'Monitor and prepare resources',
        },
      ];

      isLoading = false;
    });
  }

  // ─────────────────────────────────────────────
  // INSIGHT MODAL
  // ─────────────────────────────────────────────

  void _showInsightModal({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String detail,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius:
                        BorderRadius.circular(100),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          color.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(0.06),
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        color.withOpacity(0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT METRIC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                        color: color.withOpacity(
                          0.8,
                        ),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      AppColors.background,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color:
                        AppColors.textSecondary,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────

  bool get _isSearching =>
      _searchQuery.trim().isNotEmpty;

  String get _query =>
      _searchQuery.trim().toLowerCase();

  List<Map<String, dynamic>>
      get _searchResults {
    if (!_isSearching) return [];

    final results =
        <Map<String, dynamic>>[];

    for (final item in keyDrivers) {
      final label =
          '${item['label'] ?? ''}'
              .toLowerCase();

      final value =
          '${item['value'] ?? ''}'
              .toLowerCase();

      final detail =
          '${item['detail'] ?? ''}'
              .toLowerCase();

      if (label.contains(_query) ||
          value.contains(_query) ||
          detail.contains(_query)) {
        results.add({
          'section': 'insight',
          ...item,
        });
      }
    }

    for (final item in patientsPerClinic) {
      final clinic =
          '${item['clinic'] ?? ''}'
              .toLowerCase();

      final count =
          '${item['count'] ?? ''}'
              .toLowerCase();

      if (clinic.contains(_query) ||
          count.contains(_query)) {
        results.add({
          'section': 'trend',
          ...item,
        });
      }
    }

    for (final item in mostUsedMedicines) {
      final name =
          '${item['name'] ?? ''}'
              .toLowerCase();

      final demand =
          '${item['demand'] ?? ''}'
              .toLowerCase();

      final count =
          '${item['count'] ?? ''}'
              .toLowerCase();

      if (name.contains(_query) ||
          demand.contains(_query) ||
          count.contains(_query)) {
        results.add({
          'section': 'medicine',
          ...item,
        });
      }
    }

    return results;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LogoLoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor:
            AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor:
                AppColors.surface,
            onRefresh:
                _loadHomeAnalytics,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                96,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 20),

                  if (_isSearching) ...[
                    _buildSearchResults(),
                    const SizedBox(height: 28),
                  ] else ...[
                    _buildMainInsightCard(),
                    const SizedBox(height: 20),

                    _buildRecentEventNotifications(),

                    if (_recentEventNotifications
                        .isNotEmpty)
                      const SizedBox(height: 20),

                    _buildKeyDrivers(),
                    const SizedBox(height: 20),

                    _buildClinicDistribution(),
                    const SizedBox(height: 20),

                    _buildMedicineDemand(),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar:
            const CustomNavBar(
          currentIndex: 0,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    final rawDisplayName =
        _readString(
      summary,
      [
        'firstName',
        'first_name',
        'name',
        'userName',
      ],
    ).trim();

    String displayName =
        rawDisplayName.isNotEmpty
            ? rawDisplayName
            : 'Volunteer';

    if (displayName.length > 22) {
      final parts = displayName.split(
        RegExp(r'\s+'),
      );

      displayName =
          parts.isNotEmpty &&
                  parts.first.isNotEmpty
              ? parts.first
              : 'Volunteer';
    }

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $displayName 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.w900,
                color:
                    AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Community Health Analytics',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textMuted,
              ),
            ),
          ],
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  AppColors.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary
                    .withOpacity(0.04),
                blurRadius: 10,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons
                      .notifications_none_rounded,
                  color:
                      AppColors.textPrimary,
                  size: 22,
                ),
              ),
              Positioned(
                top: 11,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.danger,
                    shape:
                        BoxShape.circle,
                    border: Border.all(
                      color:
                          AppColors.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MAIN INSIGHT
  // ─────────────────────────────────────────────

  Widget _buildMainInsightCard() {
    final healthAlert =
        summary?['healthAlert'] ??
            'No major health alert';

    final hasAlert = !healthAlert
        .toString()
        .toLowerCase()
        .contains('no');

    final color = hasAlert
        ? AppColors.warning
        : AppColors.success;

    final bgColor = hasAlert
        ? const Color(0xFFFFFBEB)
        : AppColors.successBg;

    final borderColor = hasAlert
        ? const Color(0xFFFDE68A)
        : const Color(0xFFA7F3D0);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasAlert
                  ? Icons
                      .warning_amber_rounded
                  : Icons
                      .check_circle_outline_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hasAlert
                      ? 'Health Notice'
                      : 'System Normal',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  healthAlert.toString(),
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // KEY DRIVERS
  // ─────────────────────────────────────────────

  Widget _buildKeyDrivers() {
    final icons = [
      Icons.people_alt_rounded,
      Icons.medical_services_rounded,
      Icons.receipt_long_rounded,
      Icons.notifications_active_rounded,
    ];

    final colors = [
      AppColors.primary,
      const Color(0xFF8B5CF6),
      AppColors.success,
      AppColors.warning,
    ];

    final onTaps = [
      () => _showInsightModal(
            title: 'Total Patients',
            icon:
                Icons.people_alt_rounded,
            color: colors[0],
            value:
                '${summary?['totalPatients'] ?? 0}',
            detail:
                'Total registered patients in the system.',
          ),
      () => _showInsightModal(
            title:
                'Most Common Diagnosis',
            icon:
                Icons.medical_services_rounded,
            color: colors[1],
            value:
                '${summary?['topDiagnosis']?['name'] ?? 'No data'}',
            detail:
                'Count: ${summary?['topDiagnosis']?['count'] ?? 0}\nPercentage: ${summary?['topDiagnosis']?['percentage'] ?? 0}% of all records.',
          ),
      () => _showInsightModal(
            title:
                'Prescription Volume',
            icon:
                Icons.receipt_long_rounded,
            color: colors[2],
            value:
                '${summary?['prescriptionVolume'] ?? 0}',
            detail:
                'Total prescriptions issued across all clinics.',
          ),
      () => _showInsightModal(
            title: 'Health Alert',
            icon:
                Icons.notification_important_rounded,
            color: colors[3],
            value:
                '${summary?['healthAlert'] ?? 'No major alert'}',
            detail:
                'Monitor resources and prepare accordingly.',
          ),
    ];

    return _sectionCard(
      title: 'Key Insights',
      icon: Icons.insights_rounded,
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final columns =
              constraints.maxWidth >=
                      520
                  ? 4
                  : 2;

          final gap = 12.0;

          final cardWidth =
              (constraints.maxWidth -
                      (gap *
                          (columns - 1))) /
                  columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children:
                keyDrivers.asMap().entries.map(
              (entry) {
                final index =
                    entry.key;

                final item =
                    entry.value;

                final safeIndex =
                    index < icons.length
                        ? index
                        : 0;

                final accent =
                    colors[safeIndex];

                final isNumeric =
                    item['value'] is num;

                final displayValue =
                    '${item['value'] ?? ''}';

                return GestureDetector(
                  onTap: onTaps[
                      index <
                              onTaps.length
                          ? index
                          : 0],
                  child: Container(
                    width: cardWidth,
                    padding:
                        const EdgeInsets
                            .all(14),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.surface,
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      border:
                          Border.all(
                        color:
                            AppColors
                                .cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors
                              .textPrimary
                              .withOpacity(
                            0.02,
                          ),
                          blurRadius: 8,
                          offset:
                              const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration:
                              BoxDecoration(
                            color: accent
                                .withOpacity(
                              0.12,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Icon(
                            icons[
                                safeIndex],
                            color: accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          displayValue,
                          maxLines:
                              isNumeric
                                  ? 1
                                  : 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .textPrimary,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          '${item['label'] ?? ''}',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .textMuted,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PATIENT TRENDS
  // ─────────────────────────────────────────────

  Widget _buildClinicDistribution() {
  final displayList =
      _showAllTrends ? patientsPerClinic : patientsPerClinic.take(5).toList();

  return _sectionCard(
    title: 'Patient Trends',
    icon: Icons.bar_chart_rounded,
    child: patientsPerClinic.isEmpty
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Column(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.textMuted,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'No trend data available',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: _PatientBarChart(
                  data: displayList,
                  colors: const [
                    AppColors.primary,
                    Color(0xFF3B82F6),
                    Color(0xFF8B5CF6),
                    AppColors.warning,
                    AppColors.danger,
                  ],
                  maxValue: displayList.fold<double>(
                    0,
                    (max, item) {
                      final value = _readNumber(
                        item,
                        ['count', 'patients', 'total', 'value'],
                      ).toDouble();
                      return value > max ? value : max;
                    },
                  ),
                  readNumber: _readNumber,
                ),
              ),
              if (patientsPerClinic.length > 5)
                GestureDetector(
                  onTap: () => setState(
                    () => _showAllTrends = !_showAllTrends,
                  ),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAllTrends
                              ? 'Show Less'
                              : 'View All (${patientsPerClinic.length} months)',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllTrends
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}

  // ─────────────────────────────────────────────
  // TOP HEALTH TRENDS
  // ─────────────────────────────────────────────

  Widget _buildMedicineDemand() {
    final diagnosisName =
        '${summary?['topDiagnosis']?['name'] ?? 'No data'}';

    final diagnosisCount =
        '${summary?['topDiagnosis']?['count'] ?? 0}';

    final diagnosisPercentage =
        '${summary?['topDiagnosis']?['percentage'] ?? 0}';

    final medicine =
        mostUsedMedicines.isNotEmpty
            ? mostUsedMedicines.first
            : <String, dynamic>{
                'name':
                    'No medicine data',
                'count': 0,
                'demand': 'Stable',
              };

    final medicineName =
        '${medicine['name'] ?? 'Unknown medicine'}';

    final medicineCount =
        '${medicine['count'] ?? 0}';

    final medicineDemand =
        '${medicine['demand'] ?? 'Stable'}';

    return _sectionCard(
      title: 'Top Health Trends',
      icon:
          Icons.trending_up_rounded,
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final sideBySide =
              constraints.maxWidth >=
                  470;

          final diagnosisCard =
              _trendCard(
            icon:
                Icons.medical_services_outlined,
            iconColor:
                AppColors.primary,
            iconBackground:
                AppColors.primaryLight,
            label:
                'Most Common Diagnosis',
            value:
                diagnosisName,
            stat:
                '$diagnosisCount cases ($diagnosisPercentage%)',
            sparkColor:
                AppColors.primary,
            sparkValues: const [
              0.25,
              0.42,
              0.31,
              0.55,
              0.39,
              0.62,
              0.48,
              0.70,
            ],
          );

          final medicineCard =
              _trendCard(
            icon:
                Icons.medication_outlined,
            iconColor:
                const Color(0xFF8B5CF6),
            iconBackground:
                const Color(0xFFF3E8FF),
            label:
                'Most Used Medicine',
            value:
                medicineName,
            stat:
                '$medicineCount prescriptions • $medicineDemand',
            sparkColor:
                const Color(0xFF8B5CF6),
            sparkValues: const [
              0.35,
              0.52,
              0.40,
              0.68,
              0.48,
              0.58,
              0.45,
              0.76,
            ],
          );

          return Column(
            children: [
              if (sideBySide)
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Expanded(
                      child:
                          diagnosisCard,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          medicineCard,
                    ),
                  ],
                )
              else ...[
                diagnosisCard,
                const SizedBox(
                  height: 12,
                ),
                medicineCard,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _trendCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required String value,
    required String stat,
    required Color sparkColor,
    required List<double> sparkValues,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(
                  color: iconBackground,
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.more_horiz_rounded,
                color:
                    AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  AppColors.textPrimary,
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat,
            style: const TextStyle(
              color:
                  AppColors.textMuted,
              fontSize: 10.5,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: CustomPaint(
              painter:
                  _SparklinePainter(
                values: sparkValues,
                color: sparkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: _isSearching
              ? AppColors.primary
              : AppColors.cardBorder,
          width:
              _isSearching ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary
                .withOpacity(0.03),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller:
            _searchController,
        onChanged: (value) =>
            setState(
          () => _searchQuery =
              value,
        ),
        style: const TextStyle(
          color:
              AppColors.textPrimary,
          fontWeight:
              FontWeight.w600,
          fontSize: 13.5,
        ),
        decoration:
            InputDecoration(
          border:
              InputBorder.none,
          contentPadding:
              const EdgeInsets
                  .symmetric(
            vertical: 12,
          ),
          prefixIcon:
              const Icon(
            Icons.search_rounded,
            color:
                AppColors.textMuted,
            size: 20,
          ),
          hintText:
              'Search insights, medicines, trends...',
          hintStyle:
              const TextStyle(
            color:
                AppColors.textMuted,
            fontWeight:
                FontWeight.w500,
            fontSize: 13,
          ),
          suffixIcon:
              _isSearching
                  ? IconButton(
                      icon:
                          const Icon(
                        Icons
                            .close_rounded,
                        color:
                            AppColors
                                .textMuted,
                        size: 18,
                      ),
                      onPressed:
                          () =>
                              setState(
                        () {
                          _searchQuery =
                              '';
                          _searchController
                              .clear();
                        },
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH RESULTS
  // ─────────────────────────────────────────────

  Widget _buildSearchResults() {
    final results =
        _searchResults;

    if (results.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 32,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color:
                AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 36,
              color:
                  AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No results found',
              style: TextStyle(
                color:
                    AppColors.textPrimary,
                fontSize: 16,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nothing matched "$_searchQuery".',
              style:
                  const TextStyle(
                color:
                    AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            bottom: 12,
            left: 2,
          ),
          child: Text(
            '${results.length} result(s) for "$_searchQuery"',
            style:
                const TextStyle(
              color:
                  AppColors.textPrimary,
              fontWeight:
                  FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        ...results.map((item) {
          final section =
              item['section'];

          final title =
              item['label'] ??
                  item['clinic'] ??
                  item['name'] ??
                  'Data Point';

          final subtitle =
              item['detail'] ??
                  '${item['count'] ?? 0} count';

          return _listTile(
            icon: section ==
                    'medicine'
                ? Icons
                    .medication_rounded
                : section ==
                        'trend'
                    ? Icons
                        .bar_chart_rounded
                    : Icons
                        .insights_rounded,
            title:
                title.toString(),
            subtitle:
                subtitle.toString(),
            trailing:
                item['value']
                        ?.toString() ??
                    '',
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECTION CARD
  // ─────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary
                .withOpacity(0.02),
            blurRadius: 12,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .primaryLight,
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color:
                        AppColors
                            .primary,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textPrimary,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIST TILE
  // ─────────────────────────────────────────────

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color:
                  AppColors.primaryLight,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color:
                  AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        AppColors
                            .textPrimary,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style:
                  const TextStyle(
                color:
                    AppColors.primary,
                fontWeight:
                    FontWeight.w800,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}