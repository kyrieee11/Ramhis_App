import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/auth_token_session_flow.dart';

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
      final response = await AuthApi.get('/admin/content');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = List<Map<String, dynamic>>.from(decoded);

        final item = data.cast<Map<String, dynamic>?>().firstWhere(
              (e) => e?['slug'] == 'homepage_content',
              orElse: () => null,
            );

        if (item != null) {
          homepageContent = item;
          _fillForm(item);
        } else {
          homepageContent = null;
          _fillForm(const {
            'title': 'Homepage Content',
            'body': '',
            'sections': {},
          });
        }
      } else {
        _showSnackBar('Failed to load homepage content.');
      }
    } catch (_) {
      _showSnackBar('Connection error while loading content.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _fillForm(Map<String, dynamic> item) {
    titleController.text = (item['title'] ?? '').toString();
    bodyController.text = (item['body'] ?? '').toString();

    for (final c in topConditions) {
      c.dispose();
    }
    topConditions.clear();

    for (final m in medicationNeeds) {
      m.dispose();
    }
    medicationNeeds.clear();

    for (final k in keyDrivers) {
      k.dispose();
    }
    keyDrivers.clear();

    final sections = Map<String, dynamic>.from(item['sections'] ?? {});

    final topList = List<Map<String, dynamic>>.from(
      sections['top_conditions'] ?? [],
    );

    for (final t in topList) {
      topConditions.add(
        _TopConditionForm(
          percent: (t['percent'] ?? '').toString(),
          change: (t['change'] ?? '').toString(),
          title: (t['title'] ?? '').toString(),
          color: (t['color'] ?? 'warning').toString(),
        ),
      );
    }

    final medList = List<Map<String, dynamic>>.from(
      sections['medication_needs'] ?? [],
    );

    for (final m in medList) {
      medicationNeeds.add(
        _MedicationForm(
          name: (m['name'] ?? '').toString(),
          amount: (m['amount'] ?? '').toString(),
          risk: (m['risk'] ?? '').toString(),
        ),
      );
    }

    final drivers = List.from(sections['key_drivers'] ?? []);

    for (final d in drivers) {
      keyDrivers.add(TextEditingController(text: d.toString()));
    }

    if (topConditions.isEmpty) topConditions.add(_TopConditionForm());
    if (medicationNeeds.isEmpty) medicationNeeds.add(_MedicationForm());
    if (keyDrivers.isEmpty) keyDrivers.add(TextEditingController());
  }

  Future<void> saveHomepageContent() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showSnackBar('Title and body are required.');
      return;
    }

    setState(() => isSaving = true);

    final sections = {
      'top_conditions': topConditions.map((e) => e.toJson()).toList(),
      'medication_needs': medicationNeeds.map((e) => e.toJson()).toList(),
      'key_drivers': keyDrivers
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };

    try {
      if (homepageContent == null) {
        final response = await AuthApi.post(
          '/admin/content',
          body: {
            'slug': 'homepage_content',
            'title': title,
            'body': body,
            'sections': sections,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSnackBar('Homepage content created.');
          await fetchHomepageContent();
        } else {
          _showSnackBar('Failed to create homepage content.');
        }
      } else {
        final id = (homepageContent!['_id'] ?? '').toString();

        final response = await AuthApi.put(
          '/admin/content/$id',
          body: {
            'slug': 'homepage_content',
            'title': title,
            'body': body,
            'sections': sections,
          },
        );

        if (response.statusCode == 200) {
          _showSnackBar('Homepage content updated.');
          await fetchHomepageContent();
        } else {
          _showSnackBar('Failed to update homepage content.');
        }
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

  void _removeTopCondition(int index) {
    if (topConditions.length == 1) return;

    setState(() {
      topConditions[index].dispose();
      topConditions.removeAt(index);
    });
  }

  void _addMedication() {
    setState(() => medicationNeeds.add(_MedicationForm()));
  }

  void _removeMedication(int index) {
    if (medicationNeeds.length == 1) return;

    setState(() {
      medicationNeeds[index].dispose();
      medicationNeeds.removeAt(index);
    });
  }

  void _addDriver() {
    setState(() => keyDrivers.add(TextEditingController()));
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4766C7),
        title: const Text('Homepage CMS'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchHomepageContent,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: isSaving ? null : saveHomepageContent,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _modernCard(
                    title: 'Main Content',
                    child: Column(
                      children: [
                        _input(titleController, 'Title'),
                        _input(bodyController, 'Body', maxLines: 3),
                      ],
                    ),
                  ),
                  _modernCard(
                    title: 'Top Conditions',
                    onAdd: _addTopCondition,
                    child: Column(
                      children: List.generate(topConditions.length, (index) {
                        final item = topConditions[index];

                        return _itemBox(
                          title: 'Condition ${index + 1}',
                          onRemove: () => _removeTopCondition(index),
                          child: Column(
                            children: [
                              _input(item.percentController, 'Percent'),
                              _input(item.changeController, 'Change'),
                              _input(item.titleController, 'Title'),
                              _input(item.colorController, 'Color'),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  _modernCard(
                    title: 'Medication Needs',
                    onAdd: _addMedication,
                    child: Column(
                      children: List.generate(medicationNeeds.length, (index) {
                        final item = medicationNeeds[index];

                        return _itemBox(
                          title: 'Medication ${index + 1}',
                          onRemove: () => _removeMedication(index),
                          child: Column(
                            children: [
                              _input(item.nameController, 'Name'),
                              _input(item.amountController, 'Amount'),
                              _input(item.riskController, 'Risk'),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  _modernCard(
                    title: 'Key Drivers',
                    onAdd: _addDriver,
                    child: Column(
                      children: List.generate(keyDrivers.length, (index) {
                        return _itemBox(
                          title: 'Driver ${index + 1}',
                          onRemove: () => _removeDriver(index),
                          child: _input(keyDrivers[index], 'Driver'),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveHomepageContent,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        isSaving ? 'Saving...' : 'Save Homepage Content',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF4766C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _modernCard({
    required String title,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onAdd != null)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF4766C7),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _itemBox({
    required String title,
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE3F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4766C7), width: 1.5),
          ),
        ),
      ),
    );
  }
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
  })  : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount),
        riskController = TextEditingController(text: risk);

  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController riskController;

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text.trim(),
      'amount': amountController.text.trim(),
      'risk': riskController.text.trim(),
    };
  }

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    riskController.dispose();
  }
}