import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:ramhis_app/core/session_manager.dart';


class AdminContentManagementConnectedWidget extends StatefulWidget {
  const AdminContentManagementConnectedWidget({super.key});

  @override
  State<AdminContentManagementConnectedWidget> createState() =>
      _AdminContentManagementConnectedWidgetState();
}

class _AdminContentManagementConnectedWidgetState
    extends State<AdminContentManagementConnectedWidget> {
  bool isLoading = true;
  bool isSaving = false;
  Map<String, dynamic>? homepageContent;

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  final List<_TopConditionForm> topConditions = [];
  final List<_MedicationForm> medicationNeeds = [];
  final List<TextEditingController> keyDrivers = [];

  static const Color primary = Color(0xFF2563EB);
  static const Color bg = Color(0xFFF6F8FC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F1B3D);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    fetchHomepageContent();
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();

    for (final item in topConditions) {
      item.dispose();
    }
    for (final item in medicationNeeds) {
      item.dispose();
    }
    for (final item in keyDrivers) {
      item.dispose();
    }

    super.dispose();
  }

  Future<void> fetchHomepageContent() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final response = await http.get(
  Uri.parse('${AuthSession.baseUrl}/admin/content'),
  headers: AuthSession.headers(),
);

      if (response.statusCode != 200) {
        _showSnackBar('Failed to load homepage content.');
        return;
      }

      final decoded = jsonDecode(response.body);

final List<dynamic> rawList =
    decoded is List
        ? decoded
        : decoded['contents'] ?? [];

final data = rawList
    .map((e) => Map<String, dynamic>.from(e))
    .toList();

      final item = data.cast<Map<String, dynamic>?>().firstWhere(
            (content) => content?['slug'] == 'homepage_content',
            orElse: () => null,
          );

      homepageContent = item;
      _fillForm(
        item ??
            const {
              'title': 'Homepage Content',
              'body': 'Manage the content that will appear on the homepage.',
              'sections': {},
            },
      );
    } catch (error) {
  debugPrint(error.toString());
} finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _fillForm(Map<String, dynamic> item) {
    titleController.text = (item['title'] ?? 'Homepage Content').toString();
    bodyController.text = (item['body'] ?? '').toString();

    _clearForms();

    final sections = Map<String, dynamic>.from(item['sections'] ?? {});

    final topList = List<Map<String, dynamic>>.from(
  sections['topConditions'] ?? sections['top_conditions'] ?? [],
);
    for (final condition in topList) {
      topConditions.add(
        _TopConditionForm(
          percent: (condition['percent'] ?? '').toString(),
          change: (condition['change'] ?? '').toString(),
          title: (condition['title'] ?? '').toString(),
          color: (condition['color'] ?? 'warning').toString(),
        ),
      );
    }

    final medList = List<Map<String, dynamic>>.from(
  sections['medicationNeeds'] ?? sections['medication_needs'] ?? [],
);
    for (final medication in medList) {
      medicationNeeds.add(
        _MedicationForm(
          name: (medication['name'] ?? '').toString(),
          amount: (medication['amount'] ?? '').toString(),
          risk: (medication['risk'] ?? '').toString(),
          riskLevel: (medication['riskLevel'] ?? 'low').toString(),
        ),
      );
    }

    final drivers = List.from(
  sections['keyDrivers'] ?? sections['key_drivers'] ?? [],
);
    for (final driver in drivers) {
      keyDrivers.add(TextEditingController(text: driver.toString()));
    }

    _ensureDefaultRows();
  }

  void _clearForms() {
    for (final item in topConditions) {
      item.dispose();
    }
    topConditions.clear();

    for (final item in medicationNeeds) {
      item.dispose();
    }
    medicationNeeds.clear();

    for (final item in keyDrivers) {
      item.dispose();
    }
    keyDrivers.clear();
  }

  void _ensureDefaultRows() {
    if (topConditions.isEmpty) {
      topConditions.addAll([
        _TopConditionForm(
          percent: '10.2%',
          change: '+15%',
          title: 'Hypertension',
          color: 'warning',
        ),
        _TopConditionForm(
          percent: '16.2%',
          change: '+6%',
          title: 'Diabetes',
          color: 'danger',
        ),
        _TopConditionForm(
          percent: '8.2%',
          change: '+2%',
          title: 'Asthma',
          color: 'info',
        ),
        _TopConditionForm(
          percent: '10.3%',
          change: '-1%',
          title: 'Cancer',
          color: 'success',
        ),
      ]);
    }

    if (medicationNeeds.isEmpty) {
      medicationNeeds.addAll([
        _MedicationForm(
          name: 'Maintenance Medicines',
          amount: '500',
          risk: 'Low Risk',
          riskLevel: 'low',
        ),
        _MedicationForm(
          name: 'Insulin',
          amount: '1,000',
          risk: 'Medium Risk',
          riskLevel: 'medium',
        ),
        _MedicationForm(
          name: 'Maintenance Medicines',
          amount: '2,000',
          risk: 'High Risk',
          riskLevel: 'high',
        ),
      ]);
    }

    if (keyDrivers.isEmpty) {
      keyDrivers.addAll([
        TextEditingController(text: 'Aging Population'),
        TextEditingController(text: 'Rising Chronic Conditions'),
        TextEditingController(text: 'Economic Inflation'),
        TextEditingController(text: 'Limited Healthcare Access'),
        TextEditingController(text: 'Supply Chain Disruptions'),
      ]);
    }
  }

  Future<void> saveHomepageContent() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showSnackBar('Title and body are required.');
      return;
    }

    setState(() => isSaving = true);

    final payload = {
      'slug': 'homepage_content',
      'title': title,
      'body': body,
      'sections': {
  'topConditions': topConditions.map((item) => item.toJson()).toList(),
  'medicationNeeds': medicationNeeds.map((item) => item.toJson()).toList(),
  'keyDrivers': keyDrivers
      .map((controller) => controller.text.trim())
      .where((text) => text.isNotEmpty)
      .toList(),
},
    };

    try {
      final http.Response response = homepageContent == null
    ? await http.post(
        Uri.parse('${AuthSession.baseUrl}/admin/content'),
        headers: {
  ...AuthSession.headers(),
  'Content-Type': 'application/json',
},
        body: jsonEncode(payload),
      )
    : await http.put(
        Uri.parse('${AuthSession.baseUrl}/admin/content/${homepageContent!['_id']}'),
        headers: {
  ...AuthSession.headers(),
  'Content-Type': 'application/json',
},
        body: jsonEncode(payload),
      );

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        _showSnackBar(
          homepageContent == null
              ? 'Homepage content created.'
              : 'Homepage content updated.',
        );
        await fetchHomepageContent();
      } else {
        _showSnackBar(
          homepageContent == null
              ? 'Failed to create homepage content.'
              : 'Failed to update homepage content.',
        );
      }
    } catch (_) {
      _showSnackBar('Connection error while saving content.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _addTopCondition() {
    setState(() => topConditions.add(_TopConditionForm()));
  }

  void _addMedication() {
    setState(() => medicationNeeds.add(_MedicationForm()));
  }

  void _addDriver() {
    setState(() => keyDrivers.add(TextEditingController()));
  }

  void _removeTopCondition(int index) {
    if (topConditions.length == 1) return;
    setState(() {
      topConditions[index].dispose();
      topConditions.removeAt(index);
    });
  }

  void _removeMedication(int index) {
    if (medicationNeeds.length == 1) return;
    setState(() {
      medicationNeeds[index].dispose();
      medicationNeeds.removeAt(index);
    });
  }

  void _removeDriver(int index) {
    if (keyDrivers.length == 1) return;
    setState(() {
      keyDrivers[index].dispose();
      keyDrivers.removeAt(index);
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topHeader(),
                  const SizedBox(height: 20),
                  _editorColumn(),
                ],
              ),
            ),
    );
  }

  Widget _topHeader() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content Management',
                style: TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage homepage content and sections',
                style: TextStyle(
                  color: Color(0xFF53668D),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'Last updated: Apr 28, 2026 10:09 AM',
          style: TextStyle(
            color: Color(0xFF53668D),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        _saveButton(),
      ],
    );
  }

  Widget _editorColumn() {
    return Column(
      children: [
        _pageInfoCard(),
        const SizedBox(height: 16),
        _topConditionsCard(),
        const SizedBox(height: 16),
        _medicationCard(),
        const SizedBox(height: 16),
        _driversCard(),
      ],
    );
  }

  Widget _pageInfoCard() {
    return _flatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Page Information', style: _sectionTitleStyle),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              if (isNarrow) {
                return Column(
                  children: [
                    _field(titleController, 'Title'),
                    const SizedBox(height: 14),
                    _field(
                      bodyController,
                      'Body / Description',
                      maxLength: 255,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _field(titleController, 'Title')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _field(
                      bodyController,
                      'Body / Description',
                      maxLength: 255,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _topConditionsCard() {
    return _sectionCard(
      icon: Icons.monitor_heart_outlined,
      title: 'Top Conditions',
      subtitle: 'Statistics cards shown on homepage',
      addLabel: 'Add Condition',
      onAdd: _addTopCondition,
      child: Column(
        children: List.generate(topConditions.length, (index) {
          final item = topConditions[index];
          return _responsiveFormRow(
            isLast: index == topConditions.length - 1,
            children: [
              _field(item.percentController, 'Percentage'),
              _field(item.changeController, 'Change'),
              _field(item.titleController, 'Title'),
              _colorDropdown(item.colorController),
            ],
            onDelete: () => _removeTopCondition(index),
          );
        }),
      ),
    );
  }

  Widget _medicationCard() {
    return _sectionCard(
      icon: Icons.medication_liquid_outlined,
      title: 'Medication Needs',
      subtitle: 'Table content for medication needs section',
      addLabel: 'Add Medication',
      onAdd: _addMedication,
      child: Column(
        children: List.generate(medicationNeeds.length, (index) {
          final item = medicationNeeds[index];
          return _responsiveFormRow(
            isLast: index == medicationNeeds.length - 1,
            children: [
              _field(item.nameController, 'Medication / Supply'),
              _field(item.amountController, 'Amount Needed'),
              _field(item.riskController, 'At Risk Patients'),
              _riskLevelDropdown(item.riskLevelController),
            ],
            onDelete: () => _removeMedication(index),
          );
        }),
      ),
    );
  }

  Widget _driversCard() {
    return _sectionCard(
      icon: Icons.auto_awesome_outlined,
      title: 'Key Drivers',
      subtitle: 'List items for key drivers section',
      addLabel: 'Add Driver',
      onAdd: _addDriver,
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        children: [
          ...List.generate(keyDrivers.length, (index) {
            return SizedBox(
              width: 190,
              child: _chipField(
                keyDrivers[index],
                () => _removeDriver(index),
              ),
            );
          }),
          _addDriverChip(),
        ],
      ),
    );
  }

  Widget _responsiveFormRow({
    required List<Widget> children,
    required VoidCallback onDelete,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;

          if (isNarrow) {
            return Column(
              children: [
                for (final child in children) ...[
                  child,
                  const SizedBox(height: 10),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: _deleteButton(onDelete),
                ),
              ],
            );
          }

          return Row(
            children: [
              const Icon(
                Icons.drag_indicator_rounded,
                color: Color(0xFF8BA0C4),
                size: 20,
              ),
              const SizedBox(width: 10),
              for (int i = 0; i < children.length; i++) ...[
                Expanded(flex: _rowFlex(children.length, i), child: children[i]),
                const SizedBox(width: 10),
              ],
              _deleteButton(onDelete),
            ],
          );
        },
      ),
    );
  }

  int _rowFlex(int itemCount, int index) {
    if (itemCount == 4) {
      if (index == 0 || index == 2) return 2;
      return 1;
    }
    return index == 2 ? 2 : 1;
  }

  Widget _flatCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String addLabel,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    return _flatCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF6D5DF7), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _sectionTitleStyle),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _smallAddButton(addLabel, onAdd),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A5E85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            color: textDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: maxLength == null ? null : '${controller.text.length}/$maxLength',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD6E0F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: primary, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorDropdown(TextEditingController controller) {
    final selected = _validColor(controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'Color',
            style: TextStyle(
              color: Color(0xFF4A5E85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD6E0F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: primary, width: 1.3),
            ),
          ),
          style: const TextStyle(
            color: textDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: const [
            DropdownMenuItem(value: 'warning', child: Text('Warning')),
            DropdownMenuItem(value: 'danger', child: Text('Danger')),
            DropdownMenuItem(value: 'info', child: Text('Info')),
            DropdownMenuItem(value: 'success', child: Text('Success')),
          ],
          onChanged: (value) {
            setState(() => controller.text = value ?? 'warning');
          },
        ),
      ],
    );
  }


  Widget _riskLevelDropdown(TextEditingController controller) {
    final selected = _validRiskLevel(controller.text);
    final riskColor = _riskLevelColor(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'Risk Color',
            style: TextStyle(
              color: Color(0xFF4A5E85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: riskColor.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: riskColor.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: riskColor.text, width: 1.3),
            ),
          ),
          style: TextStyle(
            color: riskColor.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low Risk')),
            DropdownMenuItem(value: 'medium', child: Text('Medium Risk')),
            DropdownMenuItem(value: 'high', child: Text('High Risk')),
          ],
          onChanged: (value) {
            setState(() {
              controller.text = value ?? 'low';
            });
          },
        ),
      ],
    );
  }

  String _validColor(String value) {
    final clean = value.toLowerCase().trim();
    const validColors = ['warning', 'danger', 'info', 'success'];
    return validColors.contains(clean) ? clean : 'warning';
  }

  String _validRiskLevel(String value) {
    final clean = value.toLowerCase().trim();
    const validLevels = ['low', 'medium', 'high'];
    return validLevels.contains(clean) ? clean : 'low';
  }

  _RiskLevelColor _riskLevelColor(String value) {
    switch (_validRiskLevel(value)) {
      case 'high':
        return const _RiskLevelColor(
          text: Color(0xFFDC2626),
          bg: Color(0xFFFFF1F2),
          border: Color(0xFFFECACA),
        );
      case 'medium':
        return const _RiskLevelColor(
          text: Color(0xFFD97706),
          bg: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
        );
      default:
        return const _RiskLevelColor(
          text: Color(0xFF16A34A),
          bg: Color(0xFFF0FDF4),
          border: Color(0xFFBBF7D0),
        );
    }
  }

  Widget _deleteButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F7),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFFFD1D1)),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF4545),
          size: 18,
        ),
      ),
    );
  }

  Widget _smallAddButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: Color(0xFFD6E0F0)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : saveHomepageContent,
        icon: isSaving
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded, size: 16),
        label: Text(isSaving ? 'Saving...' : 'Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }

  Widget _chipField(TextEditingController controller, VoidCallback onRemove) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD6E0F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 12,
                color: textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF38517D),
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _addDriverChip() {
    return InkWell(
      onTap: _addDriver,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 130,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF9AB4E8)),
        ),
        child: const Center(
          child: Text(
            '+ Add new driver',
            style: TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _sectionTitleStyle = TextStyle(
    color: textDark,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  );
}

class _RiskLevelColor {
  const _RiskLevelColor({
    required this.text,
    required this.bg,
    required this.border,
  });

  final Color text;
  final Color bg;
  final Color border;
}

class _TopConditionForm {
  _TopConditionForm({
    String percent = '',
    String change = '',
    String title = '',
    String color = 'warning',
  })  : percentController = TextEditingController(text: percent),
        changeController = TextEditingController(text: change),
        titleController = TextEditingController(text: title),
        colorController = TextEditingController(text: color);

  final TextEditingController percentController;
  final TextEditingController changeController;
  final TextEditingController titleController;
  final TextEditingController colorController;

  Map<String, dynamic> toJson() {
    return {
      'percent': percentController.text.trim(),
      'change': changeController.text.trim(),
      'title': titleController.text.trim(),
      'color': colorController.text.trim(),
    };
  }

  void dispose() {
    percentController.dispose();
    changeController.dispose();
    titleController.dispose();
    colorController.dispose();
  }
}

class _MedicationForm {
  _MedicationForm({
    String name = '',
    String amount = '',
    String risk = '',
    String riskLevel = 'low',
  })  : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount),
        riskController = TextEditingController(text: risk),
        riskLevelController = TextEditingController(text: riskLevel);

  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController riskController;
  final TextEditingController riskLevelController;

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text.trim(),
      'amount': amountController.text.trim(),
      'risk': riskController.text.trim(),
      'riskLevel': riskLevelController.text.trim(),
    };
  }

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    riskController.dispose();
    riskLevelController.dispose();
  }
}
