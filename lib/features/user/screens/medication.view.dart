import 'package:flutter/material.dart';


class MedicationNeedsViewAllScreen extends StatefulWidget {
  final List<Map<String, dynamic>> medicines;

  const MedicationNeedsViewAllScreen({
    super.key,
    required this.medicines,
  });

  @override
  State<MedicationNeedsViewAllScreen> createState() =>
      _MedicationNeedsViewAllScreenState();
}

class _MedicationNeedsViewAllScreenState
    extends State<MedicationNeedsViewAllScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  static const Color primaryBlue = Color(0xFF0B6BFF);
  static const Color deepNavy = Color(0xFF071A4D);
  static const Color pageBg = Color(0xFFF7FAFF);
  static const Color borderColor = Color(0xFFE1EAF6);
  static const Color mutedText = Color(0xFF667085);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get filteredMedicines {
    if (searchQuery.isEmpty) return widget.medicines;

    return widget.medicines.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final amount = (item['amount'] ?? '').toString().toLowerCase();
      final risk = (item['risk'] ?? '').toString().toLowerCase();

      return name.contains(searchQuery) ||
          amount.contains(searchQuery) ||
          risk.contains(searchQuery);
    }).toList();
  }

  int _countRisk(String risk) {
    return widget.medicines.where((item) {
      return (item['risk'] ?? '').toString().toLowerCase() ==
          risk.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final medicines = filteredMedicines;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context: context,
              title: 'Medication Needs',
              subtitle:
                  'List of medications with their required amounts and risk levels.',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _buildSearchAndFilter(
                    hint: 'Search medication, risk, amount...',
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRiskSummaryCard(
                          title: 'High Risk',
                          count: _countRisk('High Risk'),
                          color: const Color(0xFFFF2F45),
                          icon: Icons.error_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildRiskSummaryCard(
                          title: 'Medium Risk',
                          count: _countRisk('Medium Risk'),
                          color: const Color(0xFFFF8A00),
                          icon: Icons.warning_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildRiskSummaryCard(
                          title: 'Low Risk',
                          count: _countRisk('Low Risk'),
                          color: const Color(0xFF16B364),
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildListHeader(
                    leftText: 'Total ${medicines.length} medications',
                    rightText: 'Sorted by Risk',
                  ),
                  const SizedBox(height: 14),
                  if (medicines.isEmpty)
                    _buildEmptyState('No medication found.')
                  else
                    ...medicines.map(_buildMedicineCard),
                  const SizedBox(height: 18),
                  _buildInfoBox(
                    text:
                        'Risk levels are based on predicted demand, stock availability, and consumption trends.',
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

  Widget _buildRiskSummaryCard({
  required String title,
  required int count,
  required Color color,
  required IconData icon,
}) {
  return Container(
    height: 128,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.12)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: deepNavy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 21,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count == 1 ? 'Item' : 'Items',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
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

  Widget _buildMedicineCard(Map<String, dynamic> item) {
    final name = (item['name'] ?? '').toString();
    final amount = (item['amount'] ?? '').toString();
    final risk = (item['risk'] ?? '').toString();
    final color = _riskColor(risk);

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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_rounded,
              color: color,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: deepNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Color(0xFF50618C),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Medicine supply',
                  style: TextStyle(
                    color: Color(0xFF50618C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              risk,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF98A2B3),
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