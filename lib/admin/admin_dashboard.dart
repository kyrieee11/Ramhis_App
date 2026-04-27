import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/auth_token_session_flow.dart';

class AdminDashboardWidget extends StatefulWidget {
  const AdminDashboardWidget({super.key});

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget> {
  bool isLoading = true;

  int totalUsers = 0;
  int totalDoctors = 0;
  int totalVolunteers = 0;
  int pendingVerification = 0;

  List<Map<String, dynamic>> recentUsers = [];
  List<Map<String, dynamic>> upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() => isLoading = true);

    try {
      final response = await AuthApi.get('/admin/dashboard');

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));

        setState(() {
          totalUsers = (data['total_users'] ?? 0) as int;
          totalDoctors = (data['total_doctors'] ?? 0) as int;
          totalVolunteers = (data['total_volunteers'] ?? 0) as int;
          pendingVerification = (data['pending_verification'] ?? 0) as int;

          recentUsers = List<Map<String, dynamic>>.from(
            data['recent_users'] ?? [],
          );

          upcomingEvents = List<Map<String, dynamic>>.from(
            data['upcoming_events'] ?? [],
          );

          isLoading = false;
        });
      } else {
        _showSnackBar('Failed to load dashboard data.');
        setState(() => isLoading = false);
      }
    } catch (_) {
      _showSnackBar('Connection error while loading dashboard.');
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F8FC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: RefreshIndicator(
        onRefresh: fetchDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _buildStatCard(
                  title: 'Total Users',
                  value: '$totalUsers',
                  icon: Icons.people_alt_rounded,
                ),
                _buildStatCard(
                  title: 'Doctors',
                  value: '$totalDoctors',
                  icon: Icons.local_hospital_rounded,
                ),
                _buildStatCard(
                  title: 'Volunteers',
                  value: '$totalVolunteers',
                  icon: Icons.volunteer_activism_rounded,
                ),
                _buildStatCard(
                  title: 'Pending Verification',
                  value: '$pendingVerification',
                  icon: Icons.verified_user_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Recent Registrations'),
            const SizedBox(height: 10),
            _buildTableCard(
              child: recentUsers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No recent users found.'),
                      ),
                    )
                  : Column(
                      children: [
                        _buildTableHeader(
                          const ['Name', 'Role', 'Status', 'Date'],
                        ),
                        ...recentUsers.map(_buildUserRow),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Upcoming Events'),
            const SizedBox(height: 10),
            if (upcomingEvents.isEmpty)
              _buildTableCard(
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No upcoming events found.'),
                  ),
                ),
              )
            else
              ...upcomingEvents.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEventCard(event),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
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
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Monitor users, approvals, and upcoming missions from one dashboard.',
                  style: TextStyle(
                    color: Color(0xFFE5ECFF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              'assets/images/ramhis_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B2559),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEDFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3F5FBE),
            ),
          ),
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
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: child,
    );
  }

  Widget _buildTableHeader(List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final status = (user['status'] ?? 'Pending').toString();

    final statusColor =
        status.toLowerCase() == 'approved' || status.toLowerCase() == 'active'
            ? const Color(0xFF16A34A)
            : const Color(0xFFD14C59);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text((user['name'] ?? '').toString()),
          ),
          Expanded(
            child: Text((user['role'] ?? '').toString()),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
              ),
            ),
          ),
          Expanded(
            child: Text((user['date'] ?? '').toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  (event['title'] ?? '').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1B2559),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEDFB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (event['date'] ?? '').toString(),
                  style: const TextStyle(
                    color: Color(0xFF3F5FBE),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (event['location'] ?? '').toString(),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.group_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (event['participants'] ?? '').toString(),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}