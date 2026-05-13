import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:ramhis_app/core/session_manager.dart';

class AdminVolunteerManagementConnectedWidget extends StatefulWidget {
  const AdminVolunteerManagementConnectedWidget({super.key});

  @override
  State<AdminVolunteerManagementConnectedWidget> createState() =>
      _AdminVolunteerManagementConnectedWidgetState();
}

class _AdminVolunteerManagementConnectedWidgetState
    extends State<AdminVolunteerManagementConnectedWidget> {
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  bool isProcessing = false;

  String searchQuery = '';
  String selectedStatus = 'All';
  String selectedSkill = 'All';

  List<Map<String, dynamic>> volunteers = [];

  final List<String> statuses = const [
    'All',
    'Active',
    'Pending',
    'Rejected',
    'Inactive',
  ];

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });

    fetchVolunteers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> get availableSkills {
    final values = volunteers
        .map((v) => (v['skills'] ?? 'General Volunteer').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...values];
  }

  List<Map<String, dynamic>> get filteredVolunteers {
    return volunteers.where((volunteer) {
      final name = (volunteer['full_name'] ?? '').toString().toLowerCase();
      final email = (volunteer['email'] ?? '').toString().toLowerCase();
      final org = (volunteer['organization'] ?? '').toString().toLowerCase();
      final skills = (volunteer['skills'] ?? 'General Volunteer').toString();
      final status = _displayStatus(volunteer);

      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          email.contains(searchQuery) ||
          org.contains(searchQuery);

      final matchesStatus = selectedStatus == 'All' || status == selectedStatus;
      final matchesSkill = selectedSkill == 'All' || skills == selectedSkill;

      return matchesSearch && matchesStatus && matchesSkill;
    }).toList();
  }

  Future<void> fetchVolunteers() async {
    setState(() => isLoading = true);

    try {
     final response = await http.get(
  Uri.parse('${AuthSession.baseUrl}/admin/volunteers'),
  headers: AuthSession.headers(),
);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          volunteers = data.map((e) => Map<String, dynamic>.from(e)).toList();

          if (!availableSkills.contains(selectedSkill)) {
            selectedSkill = 'All';
          }
        });
      } else {
        _showSnackBar('Failed to load volunteers.');
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> updateVolunteerStatus({
    required String userId,
    required String status,
  }) async {
    setState(() => isProcessing = true);

    try {
      final response = await http.put(
  Uri.parse('${AuthSession.baseUrl}/admin/volunteers/$userId/status'),
  headers: AuthSession.headers(),
  body: jsonEncode({
    'status': status.toLowerCase(),
  }),
);

      if (response.statusCode == 200) {
        _showSnackBar('Volunteer updated to $status.');
        await fetchVolunteers();
      } else {
        _showSnackBar('Failed to update volunteer.');
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  String _displayStatus(Map<String, dynamic> volunteer) {
    final raw = (volunteer['status'] ?? 'active').toString().toLowerCase();
    if (raw.isEmpty) return 'Active';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'inactive':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFD97706);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showVolunteerDetails(Map<String, dynamic> volunteer) {
    final userId = (volunteer['user_id'] ?? volunteer['_id'] ?? '').toString();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFFDBEDFB),
                          child: Icon(
                            Icons.volunteer_activism_rounded,
                            color: Color(0xFF3F5FBE),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (volunteer['full_name'] ?? 'Volunteer').toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2559),
                            ),
                          ),
                        ),
                        _buildStatusBadge(_displayStatus(volunteer)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _detailItem('Email', volunteer['email']),
                    _detailItem('Contact Number', volunteer['contact_number']),
                    _detailItem('Birthdate', volunteer['birthdate']),
                    _detailItem('Organization', volunteer['organization']),
                    _detailItem('Skills', volunteer['skills']),
                    _detailItem('Status', _displayStatus(volunteer)),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  updateVolunteerStatus(
                                    userId: userId,
                                    status: 'Active',
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  updateVolunteerStatus(
                                    userId: userId,
                                    status: 'Rejected',
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$label: ${(value ?? 'N/A').toString()}',
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F5FBE), Color(0xFF5C7AE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Volunteers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Review volunteer records, organizations, skills, and statuses.',
            style: TextStyle(
              color: Color(0xFFE5ECFF),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2559),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475467),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search & Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2559),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or organization',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF3F5FBE)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Status',
                  value: selectedStatus,
                  items: statuses,
                  onChanged: (value) {
                    setState(() => selectedStatus = value ?? 'All');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Skill / Role',
                  value: selectedSkill,
                  items: availableSkills,
                  onChanged: (value) {
                    setState(() => selectedSkill = value ?? 'All');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVolunteerCard(Map<String, dynamic> volunteer) {
    final userId = (volunteer['user_id'] ?? volunteer['_id'] ?? '').toString();
    final status = _displayStatus(volunteer);
    final skills = (volunteer['skills'] ?? 'General Volunteer').toString();
    final fullName = (volunteer['full_name'] ?? 'Unknown Volunteer').toString();
    final email = (volunteer['email'] ?? '').toString();
    final organization =
        (volunteer['organization'] ?? 'No organization').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFDBEDFB),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFF3F5FBE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2559),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(skills),
                backgroundColor: const Color(0xFFDBEDFB),
                labelStyle: const TextStyle(
                  color: Color(0xFF3F5FBE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.groups_2_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  organization,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _showVolunteerDetails(volunteer),
                child: const Text('View'),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: isProcessing
                    ? null
                    : (value) {
                        updateVolunteerStatus(userId: userId, status: value);
                      },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Active', child: Text('Approve')),
                  PopupMenuItem(value: 'Rejected', child: Text('Reject')),
                  PopupMenuItem(value: 'Pending', child: Text('Set Pending')),
                  PopupMenuItem(value: 'Inactive', child: Text('Deactivate')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isProcessing
                        ? Colors.grey.shade200
                        : const Color(0xFF3F5FBE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isProcessing ? 'Processing...' : 'Update',
                    style: TextStyle(
                      color: isProcessing ? Colors.black54 : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = volunteers.length;
    final activeCount =
        volunteers.where((v) => _displayStatus(v) == 'Active').length;
    final pendingCount =
        volunteers.where((v) => _displayStatus(v) == 'Pending').length;
    final rejectedCount =
        volunteers.where((v) => _displayStatus(v) == 'Rejected').length;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Volunteer Management',
            style: TextStyle(
              color: Color(0xFF1B2559),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: isLoading ? null : fetchVolunteers,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF1B2559),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              'All Volunteers',
                              '$totalCount',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStat(
                              'Active',
                              '$activeCount',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStat(
                              'Pending',
                              '$pendingCount',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStat(
                              'Rejected',
                              '$rejectedCount',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFilterCard(),
                      const SizedBox(height: 16),
                      if (filteredVolunteers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No volunteers found.',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredVolunteers.map(_buildVolunteerCard),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}