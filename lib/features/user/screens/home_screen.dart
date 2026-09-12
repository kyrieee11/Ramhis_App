// RAMHIS HomeScreen — visual redesign only.
// Existing API, socket, navigation, search, analytics, and event logic preserved.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/features/user/widgets/loading_view.dart';
import 'package:ramhis_app/services/api/analytics_service.dart';
import 'package:ramhis_app/services/api/event_service.dart';
import 'package:ramhis_app/models/event_model.dart';
import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/features/user/screens/events_screen.dart';

// Shared helpers (date parsing / success-check), deduplicated so this file
// and events_widget.dart don't diverge. Adjust the path below to match
// where you place event_helpers.dart in your project.
import 'package:ramhis_app/utils/event_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTANT:
// Use the actual file where EventDetailScreen is defined.

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
//
// RAMHIS palette: blue is the primary brand color, supported by soft
// blue surfaces and red accents. The same palette is reused across cards,
// charts, icons, buttons, and notifications for a consistent visual system.
abstract class AppColors {
  static const Color primary = Color(0xFF10539B);
  static const Color primaryDark = Color(0xFF0B4380);
  static const Color primarySoft = Color(0xFFEBF3FA);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color primaryTint = Color(0xFFF8FAFC);

  static const Color accentGold = Color(0xFFFFB800);
  static const Color accentGoldBg = Color(0xFFFFF7D6);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFCDE1EC);
  static const Color divider = Color(0xFFE5EAF0);

  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF526579);
  static const Color textMuted = Color(0xFF8292A6);

  static const Color success = Color(0xFF22A06B);
  static const Color successBg = Color(0xFFE8F7F0);
  static const Color warning = Color(0xFFFFB800);
  static const Color warningBg = Color(0xFFFFF7D6);
  static const Color danger = Color(0xFFD95C5C);
  static const Color dangerBg = Color(0xFFFFEFEF);
  static const Color info = Color(0xFF1863B5);

  static const Color chartViolet = Color(0xFF7A9BC8);
  static const Color chartSky = Color(0xFF65B5E6);
  static const Color chartRose = Color(0xFFE58B8B);
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
        final chartHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 190.0;

        final chartWidth = constraints.maxWidth.isFinite
            ? math.max(0.0, constraints.maxWidth - 46).toDouble()
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(
            left: 42,
            right: 4,
            top: 10,
            bottom: 4,
          ),
          child: SizedBox(
            width: double.infinity,
            height: chartHeight,
            child: _buildChart(
              safeMax,
              chartHeight,
              chartWidth,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(
  double safeMax,
  double chartHeight,
  double availableWidth,
) {
  const topLabelHeight = 28.0;
  const bottomLabelHeight = 24.0;
  const gap = 5.0;

  final availableBarHeight = math
      .max(
        30.0,
        chartHeight -
            topLabelHeight -
            bottomLabelHeight -
            gap,
      )
      .toDouble();

  // IMPORTANT:
  // Always fit every month inside the available screen width.
  // No horizontal scrolling and no minimum column width.
  final columnWidth = data.isEmpty
      ? 0.0
      : math.max(0.0, availableWidth / data.length).toDouble();

  // Keep bars proportional while making sure
  // they remain visible on smaller screens.
  final barWidth = math
      .min(
        20.0,
        columnWidth * 0.5,
      )
      .toDouble();

  return SizedBox(
    width: availableWidth,
    height: chartHeight,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
      Positioned(
        left: 0,
        right: 0,
        top: topLabelHeight,
        height: availableBarHeight,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: List.generate(
            5,
            (i) => Container(
              width: double.infinity,
              height: 1,
              color: i == 4
                  ? AppColors.cardBorder
                  : AppColors.divider,
            ),
          ),
        ),
      ),

      Positioned(
        left: -40,
        top: topLabelHeight - 6,
        width: 34,
        height: availableBarHeight + 8,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              CrossAxisAlignment.end,
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
          crossAxisAlignment:
              CrossAxisAlignment.end,
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children: data.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final item = entry.value;

              final value = readNumber(
                item,
                [
                  'count',
                  'patients',
                  'total',
                  'value',
                ],
              ).toDouble();

              final label =
                  '${item['clinic'] ?? 'Unknown'}';

              final normalizedHeight =
                  (value / safeMax)
                      .clamp(0.0, 1.0);

              final baseColor =
                  colors[index % colors.length];

              final isPeak = value == safeMax && value > 0;

              return SizedBox(
                width: columnWidth,
                height: chartHeight,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: topLabelHeight,
                      child: Align(
                        alignment:
                            Alignment.bottomCenter,
                        child: value > 0
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 6,
                                    vertical: 2.5,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: isPeak
                                        ? baseColor
                                        : baseColor
                                            .withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      7,
                                    ),
                                  ),
                                  child: Text(
                                    _formatNumber(
                                      value,
                                    ),
                                    style: TextStyle(
                                      color: isPeak
                                          ? Colors.white
                                          : baseColor,
                                      fontSize: 9,
                                      fontWeight:
                                          FontWeight.w800,
                                      letterSpacing: 0.1,
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
                        alignment:
                            Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 400,
                          ),
                          curve:
                              Curves.easeOutCubic,
                          width: barWidth,
                          height: math.max(
                            value > 0
                                ? 8.0
                                : 3.0,
                            availableBarHeight *
                                normalizedHeight,
                          ),
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: baseColor
                                    .withOpacity(
                                  0.24,
                                ),
                                blurRadius: 10,
                                offset:
                                    const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ],
                            gradient:
                                LinearGradient(
                              begin:
                                  Alignment.topCenter,
                              end:
                                  Alignment.bottomCenter,
                              colors: [
                                baseColor
                                    .withOpacity(
                                  0.70,
                                ),
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
                      width: columnWidth,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _shortLabel(label),
                            maxLines: 1,
                            style: TextStyle(
                              color: isPeak
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: isPeak
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
        ),
      ),
      ],
    ),
  );
}

  Widget _axisText(double value) {
    return Text(
      _formatNumber(value),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w700,
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

    // Soft area fill under the curve gives the sparkline depth without
    // touching the underlying data binding.
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.18),
          color.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withOpacity(0.55),
          color,
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    // Endpoint marker gives the trend a finished, dashboard-grade look.
    final lastValue = values.last.clamp(0.0, 1.0);
    final endPoint = Offset(
      size.width,
      size.height - (lastValue * size.height),
    );

    canvas.drawCircle(
      endPoint,
      5,
      Paint()..color = color.withOpacity(0.16),
    );

    canvas.drawCircle(
      endPoint,
      3.2,
      Paint()..color = color,
    );

    canvas.drawCircle(
      endPoint,
      3.2,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
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

Set<String> _knownHomeEventIds = <String>{};

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



bool _homeEventsInitialized = false;

// Persistent storage keys.
static const String _recentEventIdsKey =
    'home_recent_event_notification_ids';

static const String _dismissedEventIdsKey =
    'home_dismissed_event_ids';

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  

@override
void initState() {
  super.initState();

  _recentEventNotifications =
      List<EventModel>.from(
    _persistentRecentEventNotifications,
  );

  _dismissedHomeEventIds
      .addAll(
    _persistentDismissedHomeEventIds,
  );

  _loadHomeAnalytics();

  // Load persisted notification state first,
  // then load the current events as the baseline.
  _startHomeEvents();
}


// ─────────────────────────────────────────────
// START HOME EVENTS
// ─────────────────────────────────────────────

Future<void> _startHomeEvents() async {
  await _loadPersistentHomeEventNotifications();

  await _initializeHomeEvents();

  _connectHomeEventSocket();
}


Future<void> _loadPersistentHomeEventNotifications() async {
  try {
    final prefs =
        await SharedPreferences.getInstance();

    final savedRecentIds =
        prefs.getStringList(
              _recentEventIdsKey,
            ) ??
            <String>[];

    final savedDismissedIds =
        prefs.getStringList(
              _dismissedEventIdsKey,
            ) ??
            <String>[];

    _dismissedHomeEventIds
      ..clear()
      ..addAll(savedDismissedIds);

    _persistentDismissedHomeEventIds
      ..clear()
      ..addAll(savedDismissedIds);

    // We only store IDs here.
    // The actual EventModel objects will be
    // reconstructed after the API events are loaded.
    _recentEventNotifications.clear();

    debugPrint(
      'Loaded ${savedRecentIds.length} persisted Home notification ID(s).',
    );
  } catch (e) {
    debugPrint(
      'Failed to load persisted Home notifications: $e',
    );
  }
}

// ─────────────────────────────────────────────
// SAVE NOTIFICATION STATE
// ─────────────────────────────────────────────

Future<void> _saveHomeEventNotificationState() async {
  try {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      _recentEventIdsKey,
      _recentEventNotifications
          .map((event) => event.id)
          .toList(),
    );

    await prefs.setStringList(
      _dismissedEventIdsKey,
      _dismissedHomeEventIds.toList(),
    );

    debugPrint(
      'Saved Home event notification state.',
    );
  } catch (e) {
    debugPrint(
      'Failed to save Home notification state: $e',
    );
  }
}



  // ─────────────────────────────────────────────
  // EVENT INITIALIZATION
  // ─────────────────────────────────────────────

  Future<void> _initializeHomeEvents() async {
  try {
    final events = await EventService.getEvents();

    if (!mounted) return;

    final prefs =
        await SharedPreferences.getInstance();

    final savedRecentIds =
        prefs.getStringList(
              _recentEventIdsKey,
            ) ??
            <String>[];

    final restoredNotifications =
        <EventModel>[];

    for (final event in events) {
      if (savedRecentIds.contains(event.id) &&
          !_dismissedHomeEventIds.contains(event.id)) {
        restoredNotifications.add(event);
      }
    }

    restoredNotifications.sort(
      (a, b) {
        final aIndex =
            savedRecentIds.indexOf(a.id);
        final bIndex =
            savedRecentIds.indexOf(b.id);

        return aIndex.compareTo(bIndex);
      },
    );

    setState(() {
  _homeEvents =
      List<EventModel>.from(events);

  _knownHomeEventIds =
      events.map((event) => event.id).toSet();

  _recentEventNotifications =
      restoredNotifications;

      _persistentRecentEventNotifications
        ..clear()
        ..addAll(
          _recentEventNotifications,
        );

      _homeEventsInitialized = true;
    });

    await _saveHomeEventNotificationState();

    debugPrint(
      'Home loaded ${_homeEvents.length} events.',
    );

    debugPrint(
      'Home restored ${_recentEventNotifications.length} notification(s).',
    );
  } catch (e) {
    debugPrint(
      'Failed to initialize Home events: $e',
    );

    if (mounted) {
      setState(() {
        _homeEventsInitialized = true;
      });
    }
  }
}

  // ─────────────────────────────────────────────
  // SOCKET CONNECTION
  // ─────────────────────────────────────────────

  void _connectHomeEventSocket() {
    debugPrint('🔵 _connectHomeEventSocket() CALLED');
  _eventSocket = io.io(
    AppConfig.socketBaseUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  );

  // Register listeners BEFORE connecting.
  _eventSocket?.onConnect((_) async {
  debugPrint(
    '🟢 HOME SOCKET CONNECTED: ${_eventSocket?.id}',
  );

    // Do not refresh if the initial event list
    // has not been loaded yet.
    if (!_homeEventsInitialized) {
      debugPrint(
        'Home socket connected before event initialization completed.',
      );
      return;
    }

    await _refreshHomeEvents();
  });

  _eventSocket?.on(
  'events_updated',
  _handleHomeEventsUpdated,
);



_eventSocket?.on(
  'event_created',
  _handleHomeEventCreated,
);



  _eventSocket?.onDisconnect((reason) {
  debugPrint(
    '🔴 HOME SOCKET DISCONNECTED: ${_eventSocket?.id} | reason: $reason',
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

  // Connect LAST.
  _eventSocket?.connect();
}

Future<void> _refreshHomeEvents() async {
  try {
    final updatedEvents =
        await EventService.getEvents();

    if (!mounted) return;

    final updatedIds =
        updatedEvents.map((event) => event.id).toSet();

    // Detect only events that were NOT known
    // when Home was initialized.
    final newEvents = updatedEvents.where(
      (event) =>
          !_knownHomeEventIds.contains(event.id) &&
          !_dismissedHomeEventIds.contains(event.id),
    ).toList();

    debugPrint(
      'Home refresh detected ${newEvents.length} new event(s)',
    );

    setState(() {
      _homeEvents =
          List<EventModel>.from(updatedEvents);

      // Remember the current API events.
      _knownHomeEventIds = updatedIds;

      // Keep notifications for events that
      // still exist in the API.
      _recentEventNotifications.removeWhere(
        (event) => !updatedIds.contains(event.id),
      );

      // Update existing notification data.
      _recentEventNotifications =
          _recentEventNotifications.map((existing) {
        return updatedEvents.firstWhere(
          (updated) => updated.id == existing.id,
          orElse: () => existing,
        );
      }).toList();

      // Add ONLY genuinely new events.
      for (final event in newEvents.reversed) {
        _recentEventNotifications.removeWhere(
          (existing) => existing.id == event.id,
        );

        _recentEventNotifications.insert(
          0,
          event,
        );
      }

      _persistentRecentEventNotifications
        ..clear()
        ..addAll(_recentEventNotifications);
    });

    await _saveHomeEventNotificationState();

  } catch (e) {
    debugPrint(
      'Failed to refresh Home events: $e',
    );
  }
}

  // ─────────────────────────────────────────────
// DETECT NEW EVENTS
// ─────────────────────────────────────────────

Future<void> _handleHomeEventsUpdated(
  dynamic socketData,
) async {
  debugPrint(
    'Home received events_updated: $socketData',
  );

  if (!_homeEventsInitialized) {
    debugPrint(
      'Home received events_updated before initialization completed.',
    );

    await _initializeHomeEvents();

    // Refresh again so an event created during
    // initialization can be detected as NEW.
    await _refreshHomeEvents();

    return;
  }

  await _refreshHomeEvents();
}

Future<void> _handleHomeEventCreated(
  dynamic socketData,
) async {
  try {
    debugPrint(
      '🟢🟢🟢 EVENT_CREATED RECEIVED',
    );
    debugPrint(
      '🟢 Payload: $socketData',
    );

    if (!mounted) return;

    if (socketData is! Map) {
      debugPrint(
        '🔴 Invalid event_created payload',
      );
      return;
    }

    final rawEvent =
        socketData['event'];

    if (rawEvent is! Map) {
      debugPrint(
        '🔴 event_created payload has no event object',
      );
      return;
    }

    final currentUser =
        AuthSession.currentUser;

    final currentUserId =
        (currentUser?['_id'] ??
                currentUser?['id'] ??
                currentUser?['userId'] ??
                '')
            .toString();

    final event =
        EventModel.fromJson(
      Map<String, dynamic>.from(
        rawEvent,
      ),
      currentUserId,
    );

    if (_dismissedHomeEventIds
        .contains(event.id)) {
      debugPrint(
        'Home ignored dismissed event: ${event.id}',
      );
      return;
    }

    setState(() {
  _homeEvents.removeWhere(
    (existing) => existing.id == event.id,
  );

  _homeEvents.insert(
    0,
    event,
  );

  _knownHomeEventIds.add(event.id);

  _recentEventNotifications.removeWhere(
    (existing) => existing.id == event.id,
  );

  _recentEventNotifications.insert(
    0,
    event,
  );

  _persistentRecentEventNotifications
    ..clear()
    ..addAll(_recentEventNotifications);
});

    await _saveHomeEventNotificationState();

    debugPrint(
      '🟢 HOME DISPLAYED NEW EVENT: ${event.title}',
    );

    debugPrint(
      '🟢 TOTAL HOME NOTIFICATIONS: '
      '${_recentEventNotifications.length}',
    );
  } catch (e, stackTrace) {
    debugPrint(
      '🔴 Failed to handle event_created: $e',
    );

    debugPrint(
      '🔴 STACK: $stackTrace',
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
      accent: AppColors.accentGold,
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.accentGoldBg,
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AppColors.accentGoldBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'NEW EVENT',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (!mounted) return;

                        setState(() {
                          _dismissedHomeEventIds.add(event.id);

                          _recentEventNotifications.removeWhere(
                            (item) => item.id == event.id,
                          );

                          _persistentDismissedHomeEventIds
                            ..clear()
                            ..addAll(_dismissedHomeEventIds);

                          _persistentRecentEventNotifications
                            ..clear()
                            ..addAll(_recentEventNotifications);
                        });

                        await _saveHomeEventNotificationState();
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 7),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  titleCaseEventText(
                    event.title.isNotEmpty ? event.title : 'Untitled Event',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textMuted,
                      size: 11,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        formatEventDateDisplay(event),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await _openHomeEventDetails(event);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Event Details',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primary,
                          size: 13,
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

  _eventSocket?.off(
    'event_created',
    _handleHomeEventCreated,
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
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          color.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 25,
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
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.10),
                      color.withOpacity(0.03),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        color.withOpacity(0.16),
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
                            FontWeight.w800,
                        color: color.withOpacity(
                          0.85,
                        ),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight:
                            FontWeight.w900,
                        color: color,
                        letterSpacing: -0.4,
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
                      AppColors.surfaceSoft,
                  borderRadius:
                      BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.divider,
                  ),
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
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _loadHomeAnalytics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 94),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 14),
                  if (_isSearching) ...[
                    _buildSearchResults(),
                  ] else ...[
                    _buildDashboardMetricGrid(),
                    const SizedBox(height: 14),
                    _buildClinicDistribution(),
                    if (_recentEventNotifications.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildRecentEventNotifications(),
                    ],
                    const SizedBox(height: 14),
                    _buildMainInsightCard(),
                    const SizedBox(height: 14),
                    _buildMedicineDemand(),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const CustomNavBar(currentIndex: 0),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DASHBOARD METRIC GRID
  // ─────────────────────────────────────────────
  Widget _buildDashboardMetricGrid() {
    final totalPatients = '${summary?['totalPatients'] ?? 0}';
    final prescriptionVolume = '${summary?['prescriptionVolume'] ?? 0}';
    final diagnosisName = '${summary?['topDiagnosis']?['name'] ?? 'No data'}';
    final diagnosisCount = '${summary?['topDiagnosis']?['count'] ?? 0}';
    final healthAlert = '${summary?['healthAlert'] ?? 'No major health alert'}';
    final hasAlert = !healthAlert.toLowerCase().contains('no');

    final cards = [
      {
        'value': totalPatients,
        'label': 'Total Patients',
        'detail': 'Registered',
        'icon': Icons.people_alt_rounded,
        'accent': AppColors.primary,
        'background': AppColors.primaryLight,
        'trend': '↗ Live',
        'onTap': () => _showInsightModal(
          title: 'Total Patients',
          icon: Icons.people_alt_rounded,
          color: AppColors.primary,
          value: totalPatients,
          detail: 'Total registered patients in the system.',
        ),
      },
      {
        'value': prescriptionVolume,
        'label': 'Prescriptions',
        'detail': 'Issued',
        'icon': Icons.receipt_long_rounded,
        'accent': AppColors.info,
        'background': const Color(0xFFE7F3FF),
        'trend': '↗ Live',
        'onTap': () => _showInsightModal(
          title: 'Prescription Volume',
          icon: Icons.receipt_long_rounded,
          color: AppColors.info,
          value: prescriptionVolume,
          detail: 'Total prescriptions issued across all clinics.',
        ),
      },
      {
        'value': diagnosisName,
        'label': 'Top Diagnosis',
        'detail': '$diagnosisCount cases',
        'icon': Icons.medical_services_rounded,
        'accent': AppColors.danger,
        'background': AppColors.dangerBg,
        'trend': '• Top',
        'onTap': () => _showInsightModal(
          title: 'Most Common Diagnosis',
          icon: Icons.medical_services_rounded,
          color: AppColors.danger,
          value: diagnosisName,
          detail:
              'Count: $diagnosisCount\nPercentage: ${summary?['topDiagnosis']?['percentage'] ?? 0}% of all records.',
        ),
      },
      {
        'value': hasAlert ? 'Alert' : 'Normal',
        'label': 'Health Status',
        'detail': hasAlert ? 'Review notice' : 'No major alert',
        'icon': hasAlert
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded,
        'accent': hasAlert ? AppColors.warning : AppColors.success,
        'background': hasAlert ? AppColors.warningBg : AppColors.successBg,
        'trend': hasAlert ? '↗ Review' : '✓ Stable',
        'onTap': () => _showInsightModal(
          title: 'Health Alert',
          icon: hasAlert
              ? Icons.warning_amber_rounded
              : Icons.check_circle_rounded,
          color: hasAlert ? AppColors.warning : AppColors.success,
          value: hasAlert ? 'Alert' : 'Normal',
          detail: 'Monitor resources and prepare accordingly.',
        ),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((card) {
            return _buildDashboardMetricCard(
              width: width,
              value: card['value'] as String,
              label: card['label'] as String,
              detail: card['detail'] as String,
              icon: card['icon'] as IconData,
              accent: card['accent'] as Color,
              background: card['background'] as Color,
              trend: card['trend'] as String,
              onTap: card['onTap'] as VoidCallback,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDashboardMetricCard({
    required double width,
    required String value,
    required String label,
    required String detail,
    required IconData icon,
    required Color accent,
    required Color background,
    required String trend,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 122),
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.045),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    String displayName = 'Volunteer';

   final currentUser = AuthSession.currentUser;

if (currentUser != null) {
  final candidates = [
    currentUser['firstName'],
    currentUser['first_name'],
    currentUser['name'],
    currentUser['username'],
  ];

  for (final item in candidates) {
    final value = item?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      displayName = value.split(RegExp(r'\s+')).first;
      break;
    }
  }
}

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good day,',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hello, $displayName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Together for a healthier community',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
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
  Widget _buildMainInsightCard() {
    final healthAlert =
        '${summary?['healthAlert'] ?? 'No major health alert'}';
    final hasAlert = !healthAlert.toLowerCase().contains('no');
    final color = hasAlert ? AppColors.warning : AppColors.success;

    return GestureDetector(
      onTap: () => _showInsightModal(
        title: 'Health Alert',
        icon: hasAlert
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded,
        color: color,
        value: hasAlert ? 'Attention' : 'Normal',
        detail: healthAlert,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasAlert
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: color,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HEALTH STATUS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasAlert
                        ? 'System needs attention'
                        : 'All systems look normal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // KEY DRIVERS

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
      AppColors.chartViolet,
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
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    width: cardWidth,
                    padding:
                        const EdgeInsets
                            .all(4),
                    
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration:
                              BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withOpacity(0.18),
                                accent.withOpacity(0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icons[
                                safeIndex],
                            color: accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 7,
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
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
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
        _showAllTrends ? patientsPerClinic : patientsPerClinic.take(7).toList();

    double changePercent = 0;
    bool hasChange = false;

    if (patientsPerClinic.length >= 2) {
      final latest = _readNumber(
        patientsPerClinic[patientsPerClinic.length - 1],
        ['count', 'patients', 'total', 'value'],
      ).toDouble();
      final previous = _readNumber(
        patientsPerClinic[patientsPerClinic.length - 2],
        ['count', 'patients', 'total', 'value'],
      ).toDouble();

      if (previous != 0) {
        changePercent = ((latest - previous) / previous) * 100;
        hasChange = true;
      }
    }

    final changeText = !hasChange
        ? 'Current period • live data'
        : '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}% from last period';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Patient Trends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (displayList.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No trend data available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 188,
              width: double.infinity,
              child: _PatientBarChart(
                data: displayList,
                colors: const [
                  AppColors.chartSky,
                  AppColors.primaryLight,
                  AppColors.accentGold,
                  AppColors.chartRose,
                  AppColors.chartViolet,
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
          if (patientsPerClinic.length > 7)
            GestureDetector(
              onTap: () => setState(
                () => _showAllTrends = !_showAllTrends,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllTrends
                          ? 'Show Less'
                          : 'View All (${patientsPerClinic.length} months)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      _showAllTrends
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 15,
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
        _readNumber(summary?['topDiagnosis'], ['count', 'value', 'total'])
            .toDouble();
    final diagnosisPercentage =
        _readNumber(
          summary?['topDiagnosis'],
          ['percentage', 'percent'],
        ).toDouble();

    final medicine = mostUsedMedicines.isNotEmpty
        ? mostUsedMedicines.first
        : <String, dynamic>{
            'name': 'No medicine data',
            'count': 0,
            'demand': 'Stable',
          };

    final medicineName = '${medicine['name'] ?? 'Unknown medicine'}';
    final medicineCount =
        _readNumber(medicine, ['count', 'total', 'value', 'quantity'])
            .toDouble();
    final medicineDemand = '${medicine['demand'] ?? 'Stable'}';

    final maxMedicine = mostUsedMedicines.isEmpty
        ? 1.0
        : mostUsedMedicines
            .map(
              (item) => _readNumber(
                item,
                ['count', 'total', 'value', 'quantity'],
              ).toDouble(),
            )
            .fold<double>(0, (max, value) => value > max ? value : max);

    double progress(double value, double max) {
      if (max <= 0) return 0;
      return (value / max).clamp(0.0, 1.0).toDouble();
    }

    return _sectionCard(
      title: 'Health Overview',
      icon: Icons.insights_rounded,
      accent: AppColors.primary,
      child: Column(
        children: [
          _buildOverviewProgressRow(
            icon: Icons.medical_services_outlined,
            color: AppColors.primary,
            label: 'Most Common Diagnosis',
            value: diagnosisName,
            trailing: diagnosisCount.round().toString(),
            progressValue: diagnosisPercentage > 0
                ? (diagnosisPercentage / 100).clamp(0.0, 1.0).toDouble()
                : 0.62,
          ),
          const SizedBox(height: 15),
          _buildOverviewProgressRow(
            icon: Icons.medication_outlined,
            color: AppColors.chartViolet,
            label: 'Most Used Medicine',
            value: medicineName,
            trailing: medicineCount.round().toString(),
            progressValue: progress(medicineCount, maxMedicine),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MEDICINE DEMAND',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medicineDemand,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewProgressRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String trailing,
    required double progressValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 7,
            backgroundColor: AppColors.primarySoft,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTrendRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required String value,
    required String stat,
    required Color sparkColor,
    required List<double> sparkValues,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.cardBorder,
                ),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textMuted,
                size: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: sparkValues,
              color: sparkColor,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSearching
              ? AppColors.primary
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isSearching
                ? AppColors.primary
                : AppColors.textMuted,
            size: 18,
          ),
          hintText: 'Search insights, trends, or medicines...',
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
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
          horizontal: 16,
          vertical: 26,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(26),
          border: Border.all(
            color:
                AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 28,
                color:
                    AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
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
    Color? accent,
  }) {
    final accentColor = accent ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textMuted,
                  size: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 90),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
