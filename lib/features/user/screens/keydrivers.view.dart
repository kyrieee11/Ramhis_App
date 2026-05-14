import 'package:flutter/material.dart';

class KeyDriversViewAllScreen extends StatefulWidget {
  final List<String> drivers;

  const KeyDriversViewAllScreen({
    super.key,
    required this.drivers,
  });

  @override
  State<KeyDriversViewAllScreen> createState() =>
      _KeyDriversViewAllScreenState();
}

class _KeyDriversViewAllScreenState extends State<KeyDriversViewAllScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  static const Color primaryBlue = Color(0xFF0B6BFF);
  static const Color deepNavy = Color(0xFF071A4D);
  static const Color pageBg = Color(0xFFF7FAFF);
  static const Color softBlue = Color(0xFFEAF3FF);
  static const Color borderColor = Color(0xFFE1EAF6);
  static const Color mutedText = Color(0xFF667085);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> get filteredDrivers {
    if (searchQuery.isEmpty) return widget.drivers;

    return widget.drivers.where((driver) {
      return driver.toLowerCase().contains(searchQuery);
    }).toList();
  }

  IconData _driverIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('weather')) {
      return Icons.cloud_rounded;
    } else if (lower.contains('seasonal') || lower.contains('respiratory')) {
      return Icons.air_rounded;
    } else if (lower.contains('population')) {
      return Icons.groups_rounded;
    } else if (lower.contains('antibiotic')) {
      return Icons.medication_rounded;
    } else if (lower.contains('healthcare')) {
      return Icons.local_hospital_rounded;
    } else if (lower.contains('sanitation')) {
      return Icons.water_drop_rounded;
    } else if (lower.contains('vaccination')) {
      return Icons.shield_rounded;
    } else if (lower.contains('awareness')) {
      return Icons.campaign_rounded;
    }

    return Icons.trending_up_rounded;
  }

  String _driverDescription(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('antibiotic')) {
      return 'High consumption leading to resistance risk.';
    } else if (lower.contains('seasonal') || lower.contains('respiratory')) {
      return 'Rising cases during cold and flu season.';
    } else if (lower.contains('population')) {
      return 'Higher crowding increases disease transmission.';
    } else if (lower.contains('weather')) {
      return 'Weather variability affecting health conditions.';
    } else if (lower.contains('healthcare')) {
      return 'Insufficient facilities in rural areas.';
    } else if (lower.contains('sanitation')) {
      return 'Inadequate sanitation increasing infection risk.';
    } else if (lower.contains('vaccination')) {
      return 'Low immunization leading to outbreak risks.';
    } else if (lower.contains('awareness')) {
      return 'Lack of awareness on prevention and hygiene.';
    }

    return 'Factor contributing to community health trends.';
  }

  String _impactLevel(int index) {
    if (index <= 2) return 'High Impact';
    if (index <= 5) return 'Medium Impact';
    return 'Low Impact';
  }

  Color _impactColor(String impact) {
    if (impact.toLowerCase().contains('high')) {
      return primaryBlue;
    } else if (impact.toLowerCase().contains('medium')) {
      return const Color(0xFFFF8A00);
    }

    return const Color(0xFF16B364);
  }

  @override
  Widget build(BuildContext context) {
    final drivers = filteredDrivers;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context: context,
              title: 'Key Drivers',
              subtitle:
                  'Factors contributing to health trends and community conditions.',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _buildSearchAndFilter(
                    hint: 'Search drivers...',
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildListHeader(
                    leftText: 'Total ${drivers.length} drivers',
                    rightText: 'Sorted by Impact',
                  ),
                  const SizedBox(height: 14),
                  if (drivers.isEmpty)
                    _buildEmptyState('No key driver found.')
                  else
                    ...drivers.asMap().entries.map((entry) {
                      return _buildDriverCard(
                        title: entry.value,
                        index: entry.key,
                      );
                    }),
                  const SizedBox(height: 18),
                  _buildInfoBox(
                    text:
                        'Impact levels indicate how strongly each factor influences community health trends.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 34,
                  color: deepNavy,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: deepNavy,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF50618C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: Color(0xFF50618C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF667085),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryBlue.withValues(alpha: 0.45)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: primaryBlue,
                size: 21,
              ),
              SizedBox(width: 6),
              Text(
                'Filters',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader({
    required String leftText,
    required String rightText,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            leftText,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667085),
            ),
          ),
        ),
        Row(
          children: [
            Text(
              rightText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF667085),
              size: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverCard({
    required String title,
    required int index,
  }) {
    final impact = _impactLevel(index);
    final impactColor = _impactColor(impact);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _driverIcon(title),
              color: primaryBlue,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: deepNavy,
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _driverDescription(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF50618C),
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: impactColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  impact,
                  style: TextStyle(
                    color: impactColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: primaryBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: mutedText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}