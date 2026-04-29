import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ramhis_app/core/session_manager.dart';

class AdminDoctorsVerificationConnectedWidget extends StatefulWidget {
  const AdminDoctorsVerificationConnectedWidget({super.key});

  @override
  State<AdminDoctorsVerificationConnectedWidget> createState() =>
      _AdminDoctorsVerificationConnectedWidgetState();
}

class _AdminDoctorsVerificationConnectedWidgetState
    extends State<AdminDoctorsVerificationConnectedWidget> {
  bool isLoading = true;
  bool isProcessing = false;

  String selectedStatus = 'All';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> doctors = [];

  final List<String> statuses = const [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
    fetchDoctors();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredDoctors {
    return doctors.where((doctor) {
      final name = (doctor['full_name'] ?? '').toString().toLowerCase();
      final email = (doctor['email'] ?? '').toString().toLowerCase();
      final specialty = (doctor['specialty'] ?? '').toString().toLowerCase();
      final license =
          (doctor['prc_license_number'] ?? '').toString().toLowerCase();
      final status = _status(doctor);

      final matchesQuery = searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          email.contains(searchQuery) ||
          specialty.contains(searchQuery) ||
          license.contains(searchQuery);

      final matchesStatus = selectedStatus == 'All' || status == selectedStatus;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> fetchDoctors() async {
    setState(() => isLoading = true);

    try {
      final response = await AuthApi.get('/admin/doctors');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          doctors = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        _showSnackBar('Failed to load doctors.');
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> approveDoctor(String userId) async {
    await _handleDecision(
      endpoint: '/admin/doctors/$userId/approve',
      successMessage: 'Doctor approved successfully.',
    );
  }

  Future<void> rejectDoctor(String userId) async {
    await _handleDecision(
      endpoint: '/admin/doctors/$userId/reject',
      successMessage: 'Doctor rejected successfully.',
    );
  }

  Future<void> _handleDecision({
    required String endpoint,
    required String successMessage,
  }) async {
    setState(() => isProcessing = true);

    try {
      final response = await AuthApi.put(endpoint);

      if (response.statusCode == 200) {
        _showSnackBar(successMessage);
        await fetchDoctors();
      } else {
        _showSnackBar('Action failed.');
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> openDocument(String url) async {
    if (url.trim().isEmpty) {
      _showSnackBar('No document uploaded.');
      return;
    }

    final fullUrl = url.startsWith('http')
        ? url
        : '${AuthApi.baseUrl}$url';

    final uri = Uri.parse(fullUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not open document.');
    }
  }

  String _status(Map<String, dynamic> doctor) {
    final raw = (doctor['verification_status'] ??
            doctor['status'] ??
            'Pending')
        .toString()
        .toLowerCase();

    if (raw == 'active' || raw == 'approved') return 'Approved';
    if (raw == 'rejected') return 'Rejected';
    return 'Pending';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF16A34A);
      case 'Rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) {
    final userId = (doctor['user_id'] ?? doctor['_id'] ?? '').toString();
    final proofUrl = (doctor['license_proof_url'] ??
            doctor['proof_url'] ??
            doctor['document_url'] ??
            '')
        .toString();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
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
                          radius: 28,
                          backgroundColor: Color(0xFFDBEDFB),
                          child: Icon(
                            Icons.local_hospital_rounded,
                            color: Color(0xFF3F5FBE),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (doctor['full_name'] ?? 'Doctor').toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2559),
                            ),
                          ),
                        ),
                        _buildStatusBadge(_status(doctor)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _detailItem('Email', doctor['email']),
                    _detailItem('Contact Number', doctor['contact_number']),
                    _detailItem('Birthdate', doctor['birthdate']),
                    _detailItem('Specialty', doctor['specialty']),
                    _detailItem('PRC License No.', doctor['prc_license_number']),
                    _detailItem('Hospital / Clinic', doctor['hospital_clinic']),
                    const SizedBox(height: 16),
                    const Text(
                      'License Proof',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2559),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _proofPreview(proofUrl),
                          
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  approveDoctor(userId);
                                },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  rejectDoctor(userId);
                                },
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
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

  Widget _proofPreview(String proofUrl) {
  if (proofUrl.trim().isEmpty) {
    return const Text('No uploaded proof found.');
  }

  final fullUrl = proofUrl.startsWith('http')
      ? proofUrl
      : '${AuthApi.baseUrl}$proofUrl';

  final isPdf = fullUrl.toLowerCase().endsWith('.pdf');

  if (isPdf) {
    return OutlinedButton.icon(
      onPressed: () => openDocument(proofUrl),
      icon: const Icon(Icons.picture_as_pdf_rounded),
      label: const Text('Open PDF Proof'),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          fullUrl,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => openDocument(proofUrl),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('View Full Image'),
      ),
    ],
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.13),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2559),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, specialty, or license no.',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: statuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedStatus = value ?? 'All');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final userId = (doctor['user_id'] ?? doctor['_id'] ?? '').toString();
    final fullName = (doctor['full_name'] ?? 'Unknown Doctor').toString();
    final email = (doctor['email'] ?? '').toString();
    final specialty = (doctor['specialty'] ?? 'No specialty').toString();
    final license =
        (doctor['prc_license_number'] ?? 'No license number').toString();
    final hospital =
        (doctor['hospital_clinic'] ?? 'No hospital / clinic').toString();
    final status = _status(doctor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFDBEDFB),
            child: Icon(
              Icons.local_hospital_rounded,
              color: Color(0xFF3F5FBE),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1B2559),
                  ),
                ),
                const SizedBox(height: 4),
                Text(email),
                const SizedBox(height: 4),
                Text(
                  hospital,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Expanded(child: Text(specialty)),
          Expanded(child: Text(license)),
          _buildStatusBadge(status),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: () => _showDoctorDetails(doctor),
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text('License Proof'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Approve',
            onPressed: isProcessing ? null : () => approveDoctor(userId),
            icon: const Icon(Icons.check, color: Color(0xFF16A34A)),
          ),
          IconButton(
            tooltip: 'Reject',
            onPressed: isProcessing ? null : () => rejectDoctor(userId),
            icon: const Icon(Icons.close, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        doctors.where((doctor) => _status(doctor) == 'Pending').length;
    final approved =
        doctors.where((doctor) => _status(doctor) == 'Approved').length;
    final rejected =
        doctors.where((doctor) => _status(doctor) == 'Rejected').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Doctor Verification',
          style: TextStyle(
            color: Color(0xFF1B2559),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchDoctors,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF1B2559),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review and verify doctor registrations and credentials.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildStatCard(
                        title: 'Total Doctors',
                        value: '${doctors.length}',
                        icon: Icons.medical_services_rounded,
                        color: const Color(0xFF3F5FBE),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'Pending Review',
                        value: '$pending',
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'Approved',
                        value: '$approved',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'Rejected',
                        value: '$rejected',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  if (filteredDoctors.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text('No doctors found.'),
                      ),
                    )
                  else
                    ...filteredDoctors.map(_buildDoctorCard),
                ],
              ),
            ),
    );
  }
}