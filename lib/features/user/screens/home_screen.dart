import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/models/user_model.dart';
import 'package:ramhis_app/services/api/auth_service.dart';
import 'package:ramhis_app/services/api/content_service.dart';
import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/features/user/screens/medication.view.dart';
import 'package:ramhis_app/features/user/screens/keydrivers.view.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  final ValueNotifier<String> searchNotifier = ValueNotifier<String>('');
  Timer? _searchDebounce;

  bool isLoading = true;
  String userName = 'User';
  String accountType = 'Volunteer';
  String homepageTitle = '';
  String homepageBody = '';

  List<Map<String, dynamic>> topConditions = [];
  List<Map<String, dynamic>> medicationNeeds = [];
  List<String> keyDrivers = [];

  static const Color primaryBlue = Color(0xFF0B6BFF);
  static const Color deepNavy = Color(0xFF071A4D);
  static const Color pageBg = Color(0xFFF7FAFF);
  static const Color softBlue = Color(0xFFEAF3FF);
  static const Color borderColor = Color(0xFFE1EAF6);
  static const Color mutedText = Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    Future.microtask(_loadHomeData);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    searchNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      searchNotifier.value = searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadHomeData() async {
    debugPrint('HOME ACCESS TOKEN: ${AuthSession.accessToken}');
    debugPrint('HOME HEADERS: ${AuthSession.headers()}');

    try {
      debugPrint('HOME: starting fetchMe...');
      final userData = await AuthService.fetchMe();
      debugPrint('HOME: fetchMe success: $userData');

      debugPrint('HOME: starting homepage content...');
      final content = await ContentService.getHomepageContent();
      debugPrint('HOME: homepage content success: $content');

      final UserModel user = UserModel.fromJson(userData);

      userName = user.fullName.isEmpty ? 'User' : user.fullName;
      accountType =
          user.accountType.isEmpty ? 'Volunteer' : _capitalize(user.accountType);

      if (content != null) {
        homepageTitle = content.title;
        homepageBody = content.body;

        final sections = content.sections;

        topConditions = List<Map<String, dynamic>>.from(
          sections['topConditions'] ?? [],
        );

        medicationNeeds = List<Map<String, dynamic>>.from(
          sections['medicationNeeds'] ?? [],
        );

        keyDrivers = List<String>.from(
          sections['keyDrivers'] ?? [],
        );

        if (topConditions.isEmpty &&
            medicationNeeds.isEmpty &&
            keyDrivers.isEmpty) {
          _loadFallbackData();
        }
      } else {
        _loadFallbackData();
      }
    } catch (error) {
      debugPrint('❌ Home load error: $error');
      _loadFallbackData();
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _loadFallbackData() {
    topConditions = [
      {
        'percent': 30,
        'change': 10,
        'title': 'Respiratory Infections',
        'color': 'warning',
      },
      {
        'percent': 24,
        'change': 6,
        'title': 'Hypertension Cases',
        'color': 'danger',
      },
      {
        'percent': 18,
        'change': 4,
        'title': 'Gastrointestinal Disorders',
        'color': 'blue',
      },
    ];

    medicationNeeds = [
      {
        'name': 'Amoxicillin',
        'amount': '1,200 doses',
        'risk': 'High Risk',
      },
      {
        'name': 'Paracetamol',
        'amount': '900 doses',
        'risk': 'Medium Risk',
      },
      {
        'name': 'Azithromycin',
        'amount': '600 doses',
        'risk': 'Low Risk',
      },
      {
        'name': 'Ibuprofen',
        'amount': '450 doses',
        'risk': 'Medium Risk',
      },
    ];

    keyDrivers = [
      'Increased antibiotic use',
      'Seasonal respiratory cases',
      'Population density growth',
      'Frequent weather changes',
    ];
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  List<Map<String, dynamic>> _filteredMedicationNeeds(String query) {
    if (query.isEmpty) return medicationNeeds;

    return medicationNeeds.where((item) {
      return (item['name'] ?? '').toString().toLowerCase().contains(query) ||
          (item['risk'] ?? '').toString().toLowerCase().contains(query) ||
          (item['amount'] ?? '').toString().toLowerCase().contains(query);
    }).toList();
  }

  List<String> _filteredDrivers(String query) {
    if (query.isEmpty) return keyDrivers;

    return keyDrivers
        .where((item) => item.toLowerCase().contains(query))
        .toList();
  }

  List<Map<String, dynamic>> _filteredConditions(String query) {
    if (query.isEmpty) return topConditions;

    return topConditions.where((item) {
      return (item['title'] ?? '').toString().toLowerCase().contains(query);
    }).toList();
  }

  Color _conditionColor(String key) {
    switch (key.toLowerCase()) {
      case 'red':
      case 'danger':
        return const Color(0xFFFFEEF1);
      case 'blue':
        return const Color(0xFFEAF3FF);
      case 'green':
      case 'success':
        return const Color(0xFFE9FFF3);
      case 'yellow':
      case 'warning':
      default:
        return const Color(0xFFFFF5E6);
    }
  }

  Color _conditionAccent(String key) {
    switch (key.toLowerCase()) {
      case 'red':
      case 'danger':
        return const Color(0xFFFF3B4E);
      case 'blue':
        return primaryBlue;
      case 'green':
      case 'success':
        return const Color(0xFF16B364);
      case 'yellow':
      case 'warning':
      default:
        return const Color(0xFFFF8A00);
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high risk':
        return const Color(0xFFFF2F45);
      case 'medium risk':
        return const Color(0xFFFF8A00);
      case 'low risk':
      default:
        return const Color(0xFF16B364);
    }
  }

  IconData _conditionIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('respiratory')) {
      return Icons.air_rounded;
    } else if (lower.contains('hypertension')) {
      return Icons.favorite_rounded;
    } else if (lower.contains('gastro')) {
      return Icons.medical_services_rounded;
    }

    return Icons.health_and_safety_rounded;
  }

  IconData _driverIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('weather')) {
      return Icons.cloud_rounded;
    } else if (lower.contains('seasonal')) {
      return Icons.air_rounded;
    } else if (lower.contains('population')) {
      return Icons.groups_rounded;
    } else if (lower.contains('antibiotic')) {
      return Icons.vaccines_rounded;
    }

    return Icons.trending_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isTablet = width >= 700;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: pageBg,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopHeader(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                          strokeWidth: 3,
                        ),
                      )
                    : RefreshIndicator(
                        color: primaryBlue,
                        backgroundColor: Colors.white,
                        onRefresh: _loadHomeData,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              sliver: SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 1100),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        _buildWelcomeCard(),
                                        const SizedBox(height: 18),
                                        _buildSearchBar(),
                                        const SizedBox(height: 20),
                                        ValueListenableBuilder<String>(
                                          valueListenable: searchNotifier,
                                          builder: (context, query, _) {
                                            if (isTablet) {
                                              return Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Expanded(
                                                    flex: 6,
                                                    child:
                                                        _buildConditionsSection(
                                                            query),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    flex: 5,
                                                    child:
                                                        _buildMedicationSection(
                                                            query),
                                                  ),
                                                ],
                                              );
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                _buildConditionsSection(query),
                                                const SizedBox(height: 18),
                                                _buildMedicationSection(query),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 18),
                                        ValueListenableBuilder<String>(
                                          valueListenable: searchNotifier,
                                          builder: (context, query, _) {
                                            return _buildDriversSection(query);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const CustomNavBar(currentIndex: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF005CFF),
            Color(0xFF0B7CFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/ramhis_logo.png',
                    fit: BoxFit.cover,
                    cacheWidth: 112,
                    cacheHeight: 112,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.health_and_safety_rounded,
                        color: primaryBlue,
                        size: 32,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RAMHIS',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Real-time Community Health Intelligence',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE9F2FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: IconButton(
                  onPressed: _loadHomeData,
                  tooltip: 'Refresh',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final String title =
        homepageTitle.trim().isEmpty ? 'Hello, $userName 👋' : homepageTitle;

    final String body = homepageBody.trim().isEmpty
        ? 'Your real-time community health intelligence dashboard. Stay informed. Take action. Save lives.'
        : homepageBody;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFDCE7F7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155EEF).withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  homepageTitle.trim().isEmpty ? 'Welcome to RAMHIS' : accountType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF697188),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B587C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildWelcomeIllustration(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeIllustration() {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 116,
              height: 116,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: softBlue,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMiniBar(42, const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildMiniBar(66, const Color(0xFF12B76A)),
                const SizedBox(width: 8),
                _buildMiniBar(92, const Color(0xFFFFA726)),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 8,
            child: Container(
              width: 132,
              height: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7E4FA)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildDot(),
                      const SizedBox(width: 4),
                      _buildDot(),
                      const SizedBox(width: 4),
                      _buildDot(),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildLinePoint(18),
                      _buildLinePoint(34),
                      _buildLinePoint(25),
                      _buildLinePoint(44),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 18,
            child: Container(
              width: 70,
              height: 82,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0B6BFF),
                    Color(0xFF064ED0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 46,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFF0B6BFF),
                    Color(0xFF13C2C2),
                    Color(0xFFFF8A00),
                    Color(0xFF0B6BFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(double height, Color color) {
    return Container(
      width: 18,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: primaryBlue,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLinePoint(double height) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          width: 4,
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ValueListenableBuilder<String>(
      valueListenable: searchNotifier,
      builder: (context, query, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextFormField(
            controller: searchController,
            focusNode: searchFocusNode,
            style: const TextStyle(
              color: deepNavy,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Search medications, risks, conditions...',
              hintStyle: const TextStyle(
                color: Color(0xFF8B95A7),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF667085),
                size: 28,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: primaryBlue,
                      ),
                      onPressed: searchController.clear,
                    )
                  : Container(
                      width: 54,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Color(0xFFE7ECF4),
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF667085),
                      ),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConditionsSection(String query) {
    final conditions = _filteredConditions(query);

    return _buildPanel(
  icon: Icons.monitor_heart_rounded,
  title: 'Top Conditions Predicted',
  showViewAll: false,
  child: conditions.isEmpty
      ? _buildEmptyState('No matching conditions found.')
      : SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: conditions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = conditions[index];
              final color = (item['color'] ?? 'warning').toString();
              final title = (item['title'] ?? '').toString();
              final percent = (item['percent'] ?? 0).toString();
              final change = (item['change'] ?? 0).toString();

              final Color bg = _conditionColor(color);
              final Color accent = _conditionAccent(color);

              return Container(
                width: 185,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        _conditionIcon(title),
                        color: accent,
                        size: 32,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 31,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 16,
                                color: accent,
                              ),
                              Text(
                                '$change%',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.28,
                        fontWeight: FontWeight.w800,
                        color: deepNavy,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
);
  }

  Widget _buildMedicationSection(String query) {
  final medicines = _filteredMedicationNeeds(query);

  return _buildPanel(
    icon: Icons.medication_liquid_rounded,
    title: 'Medication Needs',
    onViewAll: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicationNeedsViewAllScreen(
            medicines: medicationNeeds,
          ),
        ),
      );
    },
    child: medicines.isEmpty
        ? _buildEmptyState('No matching medicines found.')
        : Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: medicines.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 74,
                endIndent: 14,
                color: Color(0xFFE9EEF6),
              ),
              itemBuilder: (context, index) {
                final item = medicines[index];
                final name = (item['name'] ?? '').toString();
                final amount = (item['amount'] ?? '').toString();
                final risk = (item['risk'] ?? '').toString();
                final riskColor = _riskColor(risk);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: riskColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          color: riskColor,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: deepNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              amount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 96,
                          maxWidth: 112,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: riskColor.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                risk,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: riskColor.withValues(alpha: 0.75),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
  );
}

 Widget _buildDriversSection(String query) {
  final drivers = _filteredDrivers(query);

  return _buildPanel(
    icon: Icons.trending_up_rounded,
    title: 'Key Drivers',
    onViewAll: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KeyDriversViewAllScreen(
            drivers: keyDrivers,
          ),
        ),
      );
    },
    child: drivers.isEmpty
        ? _buildEmptyState('No matching drivers found.')
        : LayoutBuilder(
            builder: (context, constraints) {
              final bool twoColumns = constraints.maxWidth >= 520;

              return GridView.builder(
                itemCount: drivers.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoColumns ? 2 : 1,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 12,
                  childAspectRatio: twoColumns ? 3.45 : 5.2,
                ),
                itemBuilder: (context, index) {
                  final driver = drivers[index];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: softBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _driverIcon(driver),
                            color: primaryBlue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            driver,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.28,
                              fontWeight: FontWeight.w700,
                              color: deepNavy,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF98A2B3),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
  );
}


  Widget _buildPanel({
  required IconData icon,
  required String title,
  required Widget child,
  VoidCallback? onViewAll,
  bool showViewAll = true,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    primaryBlue,
                    Color(0xFF075EE5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: deepNavy,
                ),
              ),
            ),

            if (showViewAll && onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                    ),
                  ],
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

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: mutedText,
          ),
        ),
      ),
    );
  }
}