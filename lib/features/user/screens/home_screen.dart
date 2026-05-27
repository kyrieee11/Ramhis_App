import 'package:flutter/material.dart';

import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/features/user/widgets/loading_view.dart'; // ← ADD THIS

import 'package:ramhis_app/services/api/analytics_service.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  bool _showAllTrends = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? errorMessage;

  Map<String, dynamic>? summary;

  List<Map<String, dynamic>> patientsPerClinic = [];
  List<Map<String, dynamic>> mostUsedMedicines = [];
  List<Map<String, dynamic>> keyDrivers = [];
  
  Color? get kBg => null;

  @override
  void initState() {
    super.initState();
    _loadHomeAnalytics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  num _readNumber(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return 0;

    for (final key in keys) {
      final value = map[key];

      if (value is num) return value;

      if (value is String) {
        return num.tryParse(value) ?? 0;
      }
    }

    return 0;
  }

  String _readString(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return '';

    for (final key in keys) {
      final value = map[key];

      if (value != null && value.toString().trim().isNotEmpty) {
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
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }

    return [];
  }

  Future<void> _loadHomeAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final responses = await Future.wait<Map<String, dynamic>?>([
        AnalyticsService.getDashboardSummary(),
        AnalyticsService.getPatientTrends(),
        AnalyticsService.getDiagnosisDistribution(),
        AnalyticsService.getTopMedicines(),
      ]);

      final dashboardSummary = responses[0];
      final patientTrends = responses[1];
      final diagnosisDistribution = responses[2];
      final topMedicines = responses[3];
      print('SUMMARY: $dashboardSummary');
print('PATIENT TRENDS: $patientTrends');
print('DIAGNOSIS: $diagnosisDistribution');
print('TOP MEDICINES: $topMedicines');

      if (dashboardSummary == null &&
          patientTrends == null &&
          diagnosisDistribution == null &&
          topMedicines == null) {
        _loadFallbackData();
        return;
      }

      final dashboardData = dashboardSummary?['data'] is Map
          ? Map<String, dynamic>.from(dashboardSummary?['data'])
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

      final prescriptionVolume = _readNumber(
        dashboardData,
        [
          'prescriptionVolume',
          'totalPrescriptions',
          'prescriptions',
          'prescriptionCount',
        ],
      );

      final healthAlert = _readString(
        dashboardData,
        [
          'healthAlert',
          'alert',
          'message',
        ],
      );

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

      final totalClinicCount = clinicRaw.fold<num>(
        0,
        (sum, item) =>
            sum +
            _readNumber(
              item,
              ['count', 'patients', 'total', 'value'],
            ),
      );

      patientsPerClinic = clinicRaw.map((item) {
        final count = _readNumber(
          item,
          ['count', 'patients', 'total', 'value'],
        );

        final percentage = _readNumber(
          item,
          ['percentage', 'percent'],
        );

        return {
          'clinic': _readString(
  item,
  ['month'],
).isNotEmpty
    ? _readString(
        item,
        ['month'],
      )
    : 'Unknown month',
          'count': count,
          'percentage': percentage > 0
              ? percentage
              : totalClinicCount > 0
                  ? ((count / totalClinicCount) * 100).round()
                  : 0,
        };
      }).toList();

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
        final aCount = _readNumber(a, ['count', 'value', 'total']);
        final bCount = _readNumber(b, ['count', 'value', 'total']);
        return bCount.compareTo(aCount);
      });

      final topDiagnosis = diagnosisRaw.isNotEmpty ? diagnosisRaw.first : null;

      final topDiagnosisName = _readString(
        topDiagnosis,
        ['name', 'diagnosis', 'label'],
      );

      final topDiagnosisCount = _readNumber(
        topDiagnosis,
        ['count', 'value', 'total'],
      );

      final topDiagnosisPercentage = _readNumber(
        topDiagnosis,
        ['percentage', 'percent'],
      );

      keyDrivers = [
        {
          'label': 'Total Patients',
          'value': totalPatients,
          'detail': 'Registered patients',
        },
        {
          'label': 'Most Common Diagnosis',
          'value': topDiagnosisName.isNotEmpty ? topDiagnosisName : 'No data',
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
          'value': healthAlert.isNotEmpty ? healthAlert : 'No major alert',
          'detail': 'Monitor and prepare resources',
        },
      ];

      final medicinesRaw = _extractList(
  topMedicines,
  [
    'data',
    'topMedicines',
    'medicines',
    'items',
  ],
);

      mostUsedMedicines = medicinesRaw.map((item) {
        final count = _readNumber(
          item,
          ['count', 'total', 'value', 'quantity'],
        );

        return {
          'name': _readString(
                item,
                ['name', 'medicine', 'medicineName', 'label'],
              ).isNotEmpty
              ? _readString(
                  item,
                  ['name', 'medicine', 'medicineName', 'label'],
                )
              : 'Unknown medicine',
          'count': count,
          'demand': _readString(item, ['demand', 'level']).isNotEmpty
              ? _readString(item, ['demand', 'level'])
              : count >= 50
                  ? 'High'
                  : count >= 25
                      ? 'Moderate'
                      : 'Stable',
        };
      }).toList();

      setState(() {
        summary = {
          'totalPatients': totalPatients,
          'prescriptionVolume': prescriptionVolume,
          'healthAlert':
              healthAlert.isNotEmpty ? healthAlert : 'No major health alert',
          'topDiagnosis': {
            'name': topDiagnosisName.isNotEmpty ? topDiagnosisName : 'No data',
            'count': topDiagnosisCount,
            'percentage': topDiagnosisPercentage,
          },
        };

        isLoading = false;
      });
    } catch (e) {
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    setState(() {
      summary = {
        'totalPatients': 0,
        'prescriptionVolume': 0,
        'healthAlert': 'No data available',
        'topProvince': {'name': 'No data', 'count': 0},
        'topDiagnosis': {'name': 'No data', 'count': 0},
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
          'detail': 'Monitor and prepare resources',
        },
      ];

      isLoading = false;
    });
  }
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
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            // Icon + Title
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        Color.lerp(color, Colors.white, 0.3)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Value pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Value',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Detail text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                detail,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      );
    },
  );
}
  

  // ── Search: filters all sections by query ──
  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  String get _query => _searchQuery.trim().toLowerCase();

  List<Map<String, dynamic>> get _searchResults {
    if (!_isSearching) return [];

    final results = <Map<String, dynamic>>[];

    // Search in keyDrivers
    for (final item in keyDrivers) {
      final label = '${item['label'] ?? ''}'.toLowerCase();
      final value = '${item['value'] ?? ''}'.toLowerCase();
      final detail = '${item['detail'] ?? ''}'.toLowerCase();
      if (label.contains(_query) || value.contains(_query) || detail.contains(_query)) {
        results.add({'section': 'insight', ...item});
      }
    }

    // Search in patientsPerClinic (months)
    for (final item in patientsPerClinic) {
      final clinic = '${item['clinic'] ?? ''}'.toLowerCase();
      final count = '${item['count'] ?? ''}'.toLowerCase();
      if (clinic.contains(_query) || count.contains(_query)) {
        results.add({'section': 'trend', ...item});
      }
    }

    // Search in mostUsedMedicines
    for (final item in mostUsedMedicines) {
      final name = '${item['name'] ?? ''}'.toLowerCase();
      final demand = '${item['demand'] ?? ''}'.toLowerCase();
      final count = '${item['count'] ?? ''}'.toLowerCase();
      if (name.contains(_query) || demand.contains(_query) || count.contains(_query)) {
        results.add({'section': 'medicine', ...item});
      }
    }

    return results;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ↓ CHANGED: wrap the entire Scaffold with LogoLoadingOverlay
    return LogoLoadingOverlay(
      isLoading: isLoading,
      message: 'Loading dashboard...',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF5D74DA),
            backgroundColor: Colors.white,
            onRefresh: _loadHomeAnalytics,
            // ↓ CHANGED: removed the isLoading ternary — overlay handles it
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  if (_isSearching) ...[
                    _buildSearchResults(),
                    const SizedBox(height: 28),
                  ] else ...[
                    _buildMainInsightCard(),
                    const SizedBox(height: 24),
                    _buildKeyDrivers(),
                    const SizedBox(height: 24),
                    _buildClinicDistribution(),
                    const SizedBox(height: 24),
                    _buildMedicineDemand(),
                    const SizedBox(height: 28),
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

Widget _buildHeader() {
  final displayName = _readString(
    summary,
    ['firstName', 'first_name', 'name', 'userName'],
  );

  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName.isNotEmpty
                  ? 'Hello, $displayName 👋'
                  : 'Hello, VOLUNTEERS 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Community Health Dashboard',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7C86A5),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF5D74DA),
                size: 26,
              ),
            ),
            Positioned(
              top: 12,
              right: 13,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.6,
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

Widget _buildMainInsightCard() {
  final totalPatients = summary?['totalPatients'] ?? 0;

  final healthAlert =
      summary?['healthAlert'] ?? 'No major health alert';

  final hasAlert =
      !healthAlert
          .toString()
          .toLowerCase()
          .contains('no');

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(34),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5B4CF0)
              .withValues(alpha: 0.28),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B8F),
                  Color(0xFF4338CA),
                  Color(0xFF7C3AED),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(24),
                        color: Colors.white
                            .withValues(alpha: 0.10),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white
                                .withValues(alpha: 0.08),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),

                    const SizedBox(width: 18),

                    const Expanded(
                      child: Text(
                        'Live community overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(28),
                    color: Colors.white
                        .withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  const LinearGradient(
                                colors: [
                                  Color(0xFF60A5FA),
                                  Color(0xFF2563EB),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '$totalPatients',
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize: 52,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                      height: 1,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                const Icon(
                                  Icons.trending_up,
                                  color:
                                      Color(0xFF22C55E),
                                  size: 34,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Patients',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 18),

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(999),
                        child: Container(
                          height: 10,
                          width: 160,
                          color: Colors.white
                              .withValues(alpha: 0.16),
                          child: Align(
                            alignment:
                                Alignment.centerLeft,
                            child: Container(
                              width: 74,
                              decoration:
                                  const BoxDecoration(
                                gradient:
                                    LinearGradient(
                                  colors: [
                                    Color(0xFF67E8F9),
                                    Color(0xFF3B82F6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withValues(alpha: 0.08),
              ),
            ),
          ),

          Positioned(
            right: 40,
            top: 80,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white
                      .withValues(alpha: 0.10),
                  width: 10,
                ),
              ),
            ),
          ),

          Positioned(
            right: 30,
            bottom: 60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _whiteMetric(String label, String value) {
  return Container(
    height: 88,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.17),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.15),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
        const Spacer(),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE3E7FF),
            fontSize: 10.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget _buildKeyDrivers() {
  final icons = [
    Icons.people_alt_rounded,
    Icons.medical_services_rounded,
    Icons.receipt_long_rounded,
    Icons.notification_important_rounded,
  ];

  final colors = [
    const Color(0xFF5D74DA),
    const Color(0xFF7C5CFF),
    const Color(0xFF22C55E),
    const Color(0xFFF59E0B),
  ];

  final onTaps = [
    // Total Patients — show summary modal
    () => _showInsightModal(
          title: 'Total Patients',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF5D74DA),
          value: '${summary?['totalPatients'] ?? 0}',
          detail: 'Total registered patients in the system.',
        ),
    // Most Common Diagnosis
    () => _showInsightModal(
          title: 'Most Common Diagnosis',
          icon: Icons.medical_services_rounded,
          color: const Color(0xFF7C5CFF),
          value: '${summary?['topDiagnosis']?['name'] ?? 'No data'}',
          detail:
              'Count: ${summary?['topDiagnosis']?['count'] ?? 0}\nPercentage: ${summary?['topDiagnosis']?['percentage'] ?? 0}% of all records.',
        ),
    // Prescription Volume
    () => _showInsightModal(
          title: 'Prescription Volume',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF22C55E),
          value: '${summary?['prescriptionVolume'] ?? 0}',
          detail: 'Total prescriptions issued across all clinics.',
        ),
    // Health Alert
    () => _showInsightModal(
          title: 'Health Alert',
          icon: Icons.notification_important_rounded,
          color: const Color(0xFFF59E0B),
          value: '${summary?['healthAlert'] ?? 'No major alert'}',
          detail: 'Monitor resources and prepare accordingly.',
        ),
  ];

  return _sectionCard(
    title: 'Key Insights',
    icon: Icons.bolt_rounded,
    child: Column(
      children: keyDrivers.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return GestureDetector(
          onTap: onTaps[index < onTaps.length ? index : 0],
          child: _listTile(
            icon: icons[index < icons.length ? index : 0],
            title: '${item['label'] ?? ''}',
            subtitle: '${item['detail'] ?? ''}',
            trailing: '${item['value'] ?? ''}',
            accentColor: colors[index < colors.length ? index : 0],
          ),
        );
      }).toList(),
    ),
  );
}

Widget _buildClinicDistribution() {
  final displayList = _showAllTrends
      ? patientsPerClinic
      : patientsPerClinic.take(3).toList();

  return _sectionCard(
    title: 'Patient Trends',
    icon: Icons.local_hospital_rounded,
    child: patientsPerClinic.isEmpty
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: const Column(
              children: [
                Icon(
                  Icons.local_hospital_outlined,
                  color: Color(0xFFB9C0D4),
                  size: 44,
                ),
                SizedBox(height: 12),
                Text(
                  'No patient trend data available',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    color: Color(0xFF8892B0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              ...displayList.map((item) {
                final clinic = item['clinic'] ?? 'Unknown';
                final percentageValue = item['percentage'] is num
                    ? item['percentage'] as num
                    : num.tryParse('${item['percentage']}') ?? 0;
                final count = item['count'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE7ECFF),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5D74DA).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clinic.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5D74DA),
                                  Color(0xFF7C5CFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count patients',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                height: 12,
                                color: const Color(0xFFE6EBFF),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor:
                                        (percentageValue.clamp(0, 100)) / 100,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF5D74DA),
                                            Color(0xFF7C5CFF),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${percentageValue.round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5D74DA),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Show more / Show less button
              if (patientsPerClinic.length > 3)
                GestureDetector(
                  onTap: () => setState(() => _showAllTrends = !_showAllTrends),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEEF2FF),
                          Color(0xFFEDE9FE),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE7ECFF),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAllTrends
                              ? 'Show less'
                              : 'Show all ${patientsPerClinic.length} months',
                          style: const TextStyle(
                            color: Color(0xFF5D74DA),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _showAllTrends ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF5D74DA),
                            size: 20,
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

Widget _buildMedicineDemand() {
  final hasHighDemand = mostUsedMedicines.any(
    (item) => '${item['demand']}'.toLowerCase() == 'high',
  );

  final footerMessage = hasHighDemand
      ? 'Some medicines are experiencing high demand.'
      : 'All medicines are within normal usage.';

  return _sectionCard(
    title: 'Most Used Medicines',
    icon: Icons.medication_rounded,
    child: mostUsedMedicines.isEmpty
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: const Column(
              children: [
                Icon(
                  Icons.medication_outlined,
                  color: Color(0xFFB9C0D4),
                  size: 44,
                ),
                SizedBox(height: 12),
                Text(
                  'No medicine data available',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    color: Color(0xFF8892B0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              ...mostUsedMedicines.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                final name = '${item['name'] ?? 'Unknown medicine'}';
                final count = item['count'] ?? 0;
                final demand = '${item['demand'] ?? 'Stable'}';
                final isOthers = name.toLowerCase() == 'others';

                Color demandColor;
                if (demand.toLowerCase() == 'high') {
                  demandColor = const Color(0xFFEF4444);
                } else if (demand.toLowerCase() == 'moderate') {
                  demandColor = const Color(0xFFF59E0B);
                } else {
                  demandColor = const Color(0xFF22C55E);
                }

                final badge = index == 0
                    ? '🥇'
                    : index == 1
                        ? '🥈'
                        : index == 2
                            ? '🥉'
                            : '${index + 1}';

                return InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: isOthers
                      ? () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                            ),
                            builder: (_) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Other Medicines',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Total usage: $count',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5D74DA),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'This category contains medicines outside the top listed medicines.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE8ECFF),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D74DA).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C5CFF).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: index < 3 ? 18 : 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF7C5CFF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1A1F36),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$count',
                              style: const TextStyle(
                                color: Color(0xFF5D74DA),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: demandColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                demand,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Footer banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF7C5CFF),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        footerMessage,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF7C5CFF),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}

Widget _buildSearchBar() {
  return Container(
    height: 54,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: _isSearching
            ? const Color(0xFF5D74DA).withValues(alpha: 0.40)
            : const Color(0xFFE7ECFF),
        width: _isSearching ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: _isSearching
              ? const Color(0xFF5D74DA).withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      style: const TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        prefixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isSearching ? Icons.search_rounded : Icons.search_rounded,
            key: ValueKey(_isSearching),
            color: _isSearching ? const Color(0xFF5D74DA) : const Color(0xFF7C86A5),
            size: 22,
          ),
        ),
        hintText: 'Search insights, medicines, trends...',
        hintStyle: const TextStyle(
          color: Color(0xFF7C86A5),
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
        suffixIcon: _isSearching
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF7C86A5),
                  size: 20,
                ),
                onPressed: () => setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                }),
              )
            : null,
      ),
    ),
  );
}

Widget _buildSearchResults() {
  final results = _searchResults;

  if (results.isEmpty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7ECFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF5D74DA).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Color(0xFF5D74DA),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing matched "$_searchQuery".\nTry a different keyword.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7C86A5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() {
              _searchQuery = '';
              _searchController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5D74DA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Clear search',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Group results by section
  final insights = results.where((r) => r['section'] == 'insight').toList();
  final trends = results.where((r) => r['section'] == 'trend').toList();
  final medicines = results.where((r) => r['section'] == 'medicine').toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Result count header
      Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 2),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${results.length} result${results.length == 1 ? '' : 's'} ',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: 'for "$_searchQuery"',
                style: const TextStyle(
                  color: Color(0xFF7C86A5),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),

      // Key Insights results
      if (insights.isNotEmpty) ...[
        _searchSectionLabel('Key Insights', Icons.bolt_rounded, const Color(0xFF5D74DA)),
        const SizedBox(height: 8),
        ...insights.map((item) {
          final idx = insights.indexOf(item);
          final icons = [
            Icons.people_alt_rounded,
            Icons.medical_services_rounded,
            Icons.receipt_long_rounded,
            Icons.notification_important_rounded,
          ];
          final colors = [
            const Color(0xFF5D74DA),
            const Color(0xFF7C5CFF),
            const Color(0xFF22C55E),
            const Color(0xFFF59E0B),
          ];
          final allIdx = keyDrivers.indexWhere((k) => k['label'] == item['label']);
          final iconIdx = allIdx >= 0 ? allIdx : idx;
          return _listTile(
            icon: icons[iconIdx < icons.length ? iconIdx : 0],
            title: '${item['label'] ?? ''}',
            subtitle: '${item['detail'] ?? ''}',
            trailing: '${item['value'] ?? ''}',
            accentColor: colors[iconIdx < colors.length ? iconIdx : 0],
          );
        }),
        const SizedBox(height: 16),
      ],

      // Patient Trends results
      if (trends.isNotEmpty) ...[
        _searchSectionLabel('Patient Trends', Icons.local_hospital_rounded, const Color(0xFF5D74DA)),
        const SizedBox(height: 8),
        ...trends.map((item) {
          final clinic = item['clinic'] ?? 'Unknown';
          final count = item['count'] ?? 0;
          final percentageValue = item['percentage'] is num
              ? item['percentage'] as num
              : num.tryParse('${item['percentage']}') ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7ECFF)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D74DA).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clinic.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5D74DA), Color(0xFF7C5CFF)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count patients',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 12,
                          color: const Color(0xFFE6EBFF),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (percentageValue.clamp(0, 100)) / 100,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF5D74DA), Color(0xFF7C5CFF)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${percentageValue.round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5D74DA),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],

      // Medicines results
      if (medicines.isNotEmpty) ...[
        _searchSectionLabel('Most Used Medicines', Icons.medication_rounded, const Color(0xFF7C5CFF)),
        const SizedBox(height: 8),
        ...medicines.map((item) {
          final name = '${item['name'] ?? 'Unknown'}';
          final count = item['count'] ?? 0;
          final demand = '${item['demand'] ?? 'Stable'}';
          Color demandColor;
          if (demand.toLowerCase() == 'high') {
            demandColor = const Color(0xFFEF4444);
          } else if (demand.toLowerCase() == 'moderate') {
            demandColor = const Color(0xFFF59E0B);
          } else {
            demandColor = const Color(0xFF22C55E);
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8ECFF)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D74DA).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C5CFF).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Color(0xFF7C5CFF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1F36),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: Color(0xFF5D74DA),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: demandColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        demand,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    ],
  );
}

Widget _searchSectionLabel(String title, IconData icon, Color color) {
  return Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );
}

Widget _sectionCard({
  required String title,
  required Widget child,
  IconData? icon,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.92),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E293B).withValues(alpha: 0.06),
          blurRadius: 28,
          offset: const Offset(0, 14),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEEF2FF),
                      Color(0xFFEDE9FE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF5D74DA),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
  Color accentColor = const Color(0xFF5D74DA),
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0xFFE7ECFF),
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  Color.lerp(accentColor, Colors.white, 0.25)!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7C86A5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              trailing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
