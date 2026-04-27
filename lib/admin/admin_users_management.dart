import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/auth_token_session_flow.dart';

class AdminUsersManagementConnectedWidget extends StatefulWidget {
  const AdminUsersManagementConnectedWidget({super.key});

  @override
  State<AdminUsersManagementConnectedWidget> createState() =>
      _AdminUsersManagementConnectedWidgetState();
}

class _AdminUsersManagementConnectedWidgetState
    extends State<AdminUsersManagementConnectedWidget> {

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  bool isProcessing = false;

  String selectedRole = 'All';
  String selectedStatus = 'All';
  String searchQuery = '';

  final List<String> roles = const ['All', 'Admin', 'Doctor', 'Volunteer'];
  final List<String> statuses = const ['All', 'Active', 'Pending', 'Suspended'];

  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
    fetchUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredUsers {
    return users.where((user) {
      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = _displayRole(user);
      final status = _displayStatus(user);

      final matchesQuery = searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          email.contains(searchQuery);

      final matchesRole = selectedRole == 'All' || role == selectedRole;
      final matchesStatus = selectedStatus == 'All' || status == selectedStatus;

      return matchesQuery && matchesRole && matchesStatus;
    }).toList();
  }

  // ✅ FIXED: use AuthApi
  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    try {
      final response = await AuthApi.get('/admin/users');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          users = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        _showSnackBar('Failed to load users.');
      }
    } catch (_) {
      _showSnackBar('Connection error while loading users.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ FIXED: use AuthApi
  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    setState(() => isProcessing = true);

    try {
      final response = await AuthApi.put(
        '/admin/users/$userId/status',
        body: {'status': status.toLowerCase()},
      );

      if (response.statusCode == 200) {
        _showSnackBar('User updated to $status');
        await fetchUsers();
      } else {
        _showSnackBar('Failed to update user.');
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  String _displayRole(Map<String, dynamic> user) {
    final role = (user['role'] ?? '').toString().toLowerCase();
    if (role == 'admin') return 'Admin';

    final type = (user['account_type'] ?? '').toString().toLowerCase();
    if (type == 'doctor') return 'Doctor';
    if (type == 'volunteer') return 'Volunteer';

    return 'User';
  }

  String _displayStatus(Map<String, dynamic> user) {
    final raw = (user['status'] ?? 'active').toString();
    return raw[0].toUpperCase() + raw.substring(1);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Users Management'),
        actions: [
          IconButton(
            onPressed: fetchUsers,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: filteredUsers.map((user) {
                final userId = user['_id'].toString();

                return ListTile(
                  title: Text(user['full_name'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      updateUserStatus(userId: userId, status: value);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'Active', child: Text('Activate')),
                      PopupMenuItem(value: 'Pending', child: Text('Pending')),
                      PopupMenuItem(value: 'Suspended', child: Text('Suspend')),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}