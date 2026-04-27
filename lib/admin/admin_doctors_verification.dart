import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth_token_session_flow.dart';

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
      final status = (doctor['verification_status'] ?? 'Pending').toString();

      final matchesQuery = searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          email.contains(searchQuery) ||
          specialty.contains(searchQuery);

      final matchesStatus =
          selectedStatus == 'All' || status == selectedStatus;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  // ✅ FIXED
  Future<void> fetchDoctors() async {
    setState(() => isLoading = true);

    try {
      final response = await AuthApi.get('/admin/doctors');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          doctors =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
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

  // ✅ FIXED
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
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not open document.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Verification'),
        actions: [
          IconButton(
            onPressed: fetchDoctors,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: filteredDoctors.map((doctor) {
                final userId = doctor['user_id'].toString();

                return Card(
                  child: ListTile(
                    title: Text(doctor['full_name'] ?? ''),
                    subtitle: Text(doctor['specialty'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => approveDoctor(userId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => rejectDoctor(userId),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}