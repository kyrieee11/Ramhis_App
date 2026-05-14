import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/models/user_model.dart';
import 'package:ramhis_app/services/api/auth_service.dart';
import 'package:ramhis_app/services/api/content_service.dart';
import 'package:ramhis_app/core/session_manager.dart';

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
        return const Color(0xFFFFE5E7);
      case 'blue':
        return const Color(0xFFE7F0FF);
      case 'green':
      case 'success':
        return const Color(0xFFE8FFF1);
      case 'yellow':
      case 'warning':
      default:
        return const Color(0xFFFFF6DD);
    }
  }

  Color _conditionAccent(String key) {
    switch (key.toLowerCase()) {
      case 'red':
      case 'danger':
        return const Color(0xFFE53935);
      case 'blue':
        return const Color(0xFF1E88E5);
      case 'green':
      case 'success':
        return const Color(0xFF22C55E);
      case 'yellow':
      case 'warning':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high risk':
        return const Color(0xFFE53935);
      case 'medium risk':
        return const Color(0xFFF59E0B);
      case 'low risk':
      default:
        return const Color(0xFF22C55E);
    }
  }

  IconData _conditionIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('respiratory')) {
      return Icons.air;
    } else if (lower.contains('hypertension')) {
      return Icons.favorite;
    } else if (lower.contains('gastro')) {
      return Icons.medical_services;
    }

    return Icons.health_and_safety_rounded;
  }

  IconData _driverIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('weather')) {
      return Icons.cloud;
    } else if (lower.contains('seasonal')) {
      return Icons.ac_unit;
    } else if (lower.contains('population')) {
      return Icons.groups_rounded;
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
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopHeader(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4766C7),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF4766C7),
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4766C7),
            Color(0xFF5E7BDA),
          ],
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/ramhis_logo.png',
                fit: BoxFit.cover,
                cacheWidth: 100,
                cacheHeight: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 28,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RAMHIS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Healthcare Monitoring Dashboard',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE6ECFF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: _loadHomeData,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final String title =
        homepageTitle.trim().isEmpty ? 'Welcome back, $userName' : homepageTitle;

    final String body = homepageBody.trim().isEmpty
        ? 'Signed in as $accountType. Monitor healthcare predictions and medication demands in real time.'
        : homepageBody;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4766C7),
            Color(0xFF6A82E8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4766C7).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
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

  Widget _buildSearchBar() {
    return ValueListenableBuilder<String>(
      valueListenable: searchNotifier,
      builder: (context, query, _) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: searchController,
            focusNode: searchFocusNode,
            style: const TextStyle(
              color: Color(0xFF1B2559),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search conditions, medicines, or drivers',
              hintStyle: const TextStyle(
                color: Color(0xFF9AA3B2),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF4766C7),
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF4766C7),
                      ),
                      onPressed: searchController.clear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: Color(0xFF4766C7),
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
      title: 'Top Conditions Predicted',
      child: conditions.isEmpty
          ? _buildEmptyState('No matching conditions found.')
          : SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: conditions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = conditions[index];
                  final color = (item['color'] ?? 'warning').toString();
                  final title = (item['title'] ?? '').toString();
                  final percent = (item['percent'] ?? 0).toString();
                  final change = (item['change'] ?? 0).toString();

                  final Color bg = _conditionColor(color);
                  final Color accent = _conditionAccent(color);

                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _conditionIcon(title),
                            color: accent,
                            size: 32,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$change%',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
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
      title: 'Medication Needs',
      child: medicines.isEmpty
          ? _buildEmptyState('No matching medicines found.')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medicines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = medicines[index];
                final name = (item['name'] ?? '').toString();
                final amount = (item['amount'] ?? '').toString();
                final risk = (item['risk'] ?? '').toString();
                final riskColor = _riskColor(risk);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          color: riskColor,
                          size: 28,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              amount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 82,
                          maxWidth: 95,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          risk,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDriversSection(String query) {
    final drivers = _filteredDrivers(query);

    return _buildPanel(
      title: 'Key Drivers',
      child: drivers.isEmpty
          ? _buildEmptyState('No matching drivers found.')
          : GridView.builder(
              itemCount: drivers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                final driver = drivers[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F0FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _driverIcon(driver),
                          color: const Color(0xFF2563EB),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          driver,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPanel({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFE9EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1F3B),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}