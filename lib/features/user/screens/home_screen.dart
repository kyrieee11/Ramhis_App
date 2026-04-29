import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ramhis_app/models/content_model.dart';
import 'package:ramhis_app/models/user_model.dart';
import 'package:ramhis_app/services/api/content_service.dart';
import 'package:ramhis_app/services/api/user_service.dart';
import 'package:ramhis_app/services/socket/socket_service.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  final UserService _userService = UserService();
  final ContentService _contentService = ContentService();
  final SocketService socketService = SocketService();

  final ValueNotifier<String> searchNotifier = ValueNotifier<String>('');
  Timer? _searchDebounce;

  bool isLoading = true;
  String userName = 'User';
  String accountType = 'Volunteer';
  String homepageTitle = '';
  String homepageBody = '';

  List<TopCondition> topConditions = [];
  List<MedicationNeed> medicationNeeds = [];
  List<String> keyDrivers = [];

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);

    socketService.connect();

    socketService.listenContentUpdate((data) {
  if (!mounted || isLoading) return;
  debugPrint('📡 Homepage updated from admin');
  _loadHomeData();
});

    Future.microtask(_loadHomeData);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    searchNotifier.dispose();

    socketService.removeContentUpdateListener();

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
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final results = await Future.wait<dynamic>([
        _userService.getProfile(),
        _contentService.getHomepageContent(),
      ]);

      final user = results[0] as UserModel?;
      final content = results[1] as HomepageContentModel?;

      if (user != null) {
        userName = user.fullName.isEmpty ? 'User' : user.fullName;
        accountType =
            user.accountType.isEmpty ? 'Volunteer' : _capitalize(user.accountType);
      }

      if (content != null) {
        homepageTitle = content.title;
        homepageBody = content.body;
        topConditions = content.topConditions;
        medicationNeeds = content.medicationNeeds;
        keyDrivers = content.keyDrivers;
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
      TopCondition(
        percent: 30,
        change: 10,
        title: 'Respiratory Infections',
        color: 'warning',
      ),
      TopCondition(
        percent: 24,
        change: 6,
        title: 'Hypertension Cases',
        color: 'danger',
      ),
    ];

    medicationNeeds = [
      MedicationNeed(
        name: 'Amoxicillin',
        amount: '1,200 doses',
        risk: 'High Risk',
      ),
      MedicationNeed(
        name: 'Paracetamol',
        amount: '900 doses',
        risk: 'Medium Risk',
      ),
    ];

    keyDrivers = [
      'Increased antibiotic use',
      'Seasonal respiratory cases',
    ];
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  List<MedicationNeed> _filteredMedicationNeeds(String query) {
    if (query.isEmpty) return medicationNeeds;

    return medicationNeeds.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.risk.toLowerCase().contains(query) ||
          item.amount.toLowerCase().contains(query);
    }).toList();
  }

  List<String> _filteredDrivers(String query) {
    if (query.isEmpty) return keyDrivers;

    return keyDrivers.where((item) => item.toLowerCase().contains(query)).toList();
  }

  List<TopCondition> _filteredConditions(String query) {
    if (query.isEmpty) return topConditions;

    return topConditions.where((item) {
      return item.title.toLowerCase().contains(query);
    }).toList();
  }

  Color _conditionColor(String key) {
    switch (key.toLowerCase()) {
      case 'red':
      case 'danger':
        return const Color(0xFFFF6B6B);
      case 'green':
      case 'success':
        return const Color(0xFF20C997);
      case 'blue':
        return const Color(0xFF74C0FC);
      case 'yellow':
      case 'warning':
      default:
        return const Color(0xFFFFC857);
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high risk':
        return const Color(0xFFD94F5C);
      case 'medium risk':
        return const Color(0xFFFFA62B);
      case 'low risk':
      default:
        return const Color(0xFF22C55E);
    }
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
        backgroundColor: const Color(0xFF3E5EBE),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopHeader(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHomeData,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
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
                                        const SizedBox(height: 14),
                                        _buildSearchBar(),
                                        const SizedBox(height: 18),
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
                                                        _buildConditionsSection(query),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    flex: 5,
                                                    child:
                                                        _buildMedicationSection(query),
                                                  ),
                                                ],
                                              );
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                _buildConditionsSection(query),
                                                const SizedBox(height: 14),
                                                _buildMedicationSection(query),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 14),
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
      color: const Color(0xFF4766C7),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF5B76D1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/ramhis_logo.png',
                fit: BoxFit.cover,
                cacheWidth: 92,
                cacheHeight: 92,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 26,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'RAMHIS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF5B76D1),
              borderRadius: BorderRadius.circular(12),
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
        ? 'Signed in as $accountType. This dashboard reads secure profile and admin-managed homepage content.'
        : homepageBody;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF4766C7),
            Color(0xFF5B76D1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFEAF0FF),
                    height: 1.4,
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
        return TextFormField(
          controller: searchController,
          focusNode: searchFocusNode,
          style: const TextStyle(color: Color(0xFF1B2559)),
          decoration: InputDecoration(
            hintText: 'Search conditions, medicines, or drivers',
            hintStyle: const TextStyle(color: Color(0xFF8A94B5)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF5B76D1),
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF5B76D1)),
                    onPressed: searchController.clear,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
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
              height: 155,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: conditions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = conditions[index];

                  return Container(
                    width: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _conditionColor(item.color),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${item.percent}%',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${item.change}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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
          : ListView.builder(
              itemCount: medicines.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = medicines[index];

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x11000000)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.amount,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _riskColor(item.risk),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.risk,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
          : ListView.builder(
              itemCount: drivers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final driver = drivers[index];

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x11000000)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEDFB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF3F5FBE),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(driver)),
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
    return Material(
      color: Colors.transparent,
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2559),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}