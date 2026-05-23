import 'package:flutter/material.dart';

import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';

import 'package:ramhis_app/services/api/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
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
          'patientsPerClinic',
          'clinicDistribution',
          'trends',
          'patientTrends',
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
                ['clinic', 'name', 'label', 'department'],
              ).isNotEmpty
              ? _readString(
                  item,
                  ['clinic', 'name', 'label', 'department'],
                )
              : 'General Medicine',
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
          'keyDrivers',
          'diagnosisDistribution',
          'diagnoses',
          'data',
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
          'mostUsedMedicines',
          'topMedicines',
          'medicines',
          'data',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF5D74DA),
          backgroundColor: Colors.white,
          onRefresh: _loadHomeAnalytics,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF5D74DA),
                  ),
                )
              : AnimatedOpacity(
                  opacity: isLoading ? 0 : 1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 22),
                        _buildMainInsightCard(),
                        const SizedBox(height: 18),
                        _buildKeyDrivers(),
                        const SizedBox(height: 18),
                        _buildClinicDistribution(),
                        const SizedBox(height: 18),
                        _buildMedicineDemand(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 0),
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
                    : 'Hello, RAMHIS 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1F36),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Community Health Dashboard',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8892B0),
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF5D74DA),
                size: 25,
              ),
            ),
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainInsightCard() {
    final totalPatients = summary?['totalPatients'] ?? 0;
    final prescriptionVolume = summary?['prescriptionVolume'] ?? 0;
    final healthAlert = summary?['healthAlert'] ?? 'No alert';

    final hasAlert = !healthAlert.toString().toLowerCase().contains('no major') &&
        !healthAlert.toString().toLowerCase().contains('no alert') &&
        !healthAlert.toString().toLowerCase().contains('no data');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4F46E5),
                    Color(0xFF7C3AED),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Intelligence',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Live community overview',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _whiteMetric(
                          'Patients',
                          totalPatients.toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _whiteMetric(
                          'Prescriptions',
                          prescriptionVolume.toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _whiteMetric(
                          'Alerts',
                          hasAlert ? 'Active' : 'OK',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasAlert
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            healthAlert.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
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
              right: -26,
              top: -28,
              child: Icon(
                Icons.monitor_heart_rounded,
                size: 140,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 34,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 16,
                  ),
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
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.13),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 15,
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
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

    return _sectionCard(
      title: 'Key Insights',
      icon: Icons.bolt_rounded,
      child: Column(
        children: keyDrivers.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return _listTile(
            icon: icons[index < icons.length ? index : 0],
            title: '${item['label'] ?? ''}',
            subtitle: '${item['detail'] ?? ''}',
            trailing: '${item['value'] ?? ''}',
            accentColor: colors[index < colors.length ? index : 0],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClinicDistribution() {
    return _sectionCard(
      title: 'Patients Per Clinic',
      icon: Icons.local_hospital_rounded,
      child: patientsPerClinic.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: const Column(
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    color: Color(0xFFB9C0D4),
                    size: 42,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No clinic data available',
                    style: TextStyle(
                      color: Color(0xFF1A1F36),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      color: Color(0xFF8892B0),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: patientsPerClinic.map((item) {
                final clinic = item['clinic'] ?? 'Unknown';
                final percentageValue = item['percentage'] is num
                    ? item['percentage'] as num
                    : num.tryParse('${item['percentage']}') ?? 0;
                final count = item['count'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE8ECFF),
                    ),
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
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1F36),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D74DA).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count patients',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5D74DA),
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
                              child: LinearProgressIndicator(
                                value: (percentageValue.clamp(0, 100)) / 100,
                                minHeight: 9,
                                backgroundColor: const Color(0xFFE5E9FF),
                                color: const Color(0xFF5D74DA),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${percentageValue.round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5D74DA),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMedicineDemand() {
    return _sectionCard(
      title: 'Most Used Medicines',
      icon: Icons.medication_rounded,
      child: mostUsedMedicines.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: const Column(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    color: Color(0xFFB9C0D4),
                    size: 42,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No medicine data available',
                    style: TextStyle(
                      color: Color(0xFF1A1F36),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      color: Color(0xFF8892B0),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: mostUsedMedicines.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final demand = '${item['demand'] ?? 'Stable'}';

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

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE8ECFF),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C5CFF).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
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
                          '${item['name'] ?? ''}',
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
                            '${item['count'] ?? 0}',
                            style: const TextStyle(
                              color: Color(0xFF5D74DA),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: demandColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              demand,
                              style: TextStyle(
                                color: demandColor,
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
              }).toList(),
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D74DA).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: const Color(0xFF5D74DA),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A1F36),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
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

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
    Color accentColor = const Color(0xFF5D74DA),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8ECFF),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: accentColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1A1F36),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8892B0),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        trailing,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}