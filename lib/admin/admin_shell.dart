import 'package:flutter/material.dart';
import '../core/auth_token_session_flow.dart';

import 'admin_dashboard.dart';
import 'admin_users_management.dart';
import 'admin_doctors_verification.dart';
import 'admin_events_management.dart';
import 'admin_volunteer_management.dart';
import 'admin_content_management.dart';
import 'admin_login.dart';

class AdminShellWidget extends StatefulWidget {
  const AdminShellWidget({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<AdminShellWidget> createState() => _AdminShellWidgetState();
}

class _AdminShellWidgetState extends State<AdminShellWidget> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  List<_AdminNavItem> get navItems => const [
        _AdminNavItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          page: AdminDashboardWidget(),
        ),
        _AdminNavItem(
          label: 'Users',
          icon: Icons.people_alt_rounded,
          page: AdminUsersManagementConnectedWidget(),
        ),
        _AdminNavItem(
          label: 'Doctors',
          icon: Icons.local_hospital_rounded,
          page: AdminDoctorsVerificationConnectedWidget(),
        ),
        _AdminNavItem(
          label: 'Volunteers',
          icon: Icons.volunteer_activism_rounded,
          page: AdminVolunteerManagementConnectedWidget(),
        ),
        _AdminNavItem(
          label: 'Events',
          icon: Icons.event_rounded,
          page: AdminEventsManagementConnectedWidget(),
        ),
        _AdminNavItem(
          label: 'Content',
          icon: Icons.description_rounded,
          page: AdminContentManagementConnectedWidget(),
        ),
      ];

  Future<void> _logout() async {
    await AuthApi.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginWidget()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F8FC),
            body: SafeArea(
              child: Row(
                children: [
                  _buildSidebar(compact: false),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(showMenu: false),
                        Expanded(child: navItems[selectedIndex].page),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FC),
          drawer: Drawer(
            child: SafeArea(
              child: _buildSidebar(compact: true),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(showMenu: true),
                Expanded(child: navItems[selectedIndex].page),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar({required bool showMenu}) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
          Expanded(
            child: Text(
              navItems[selectedIndex].label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2559),
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool compact}) {
    return Container(
      width: compact ? double.infinity : 260,
      color: Colors.white,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF3F5FBE),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFF3F5FBE),
                    size: 28,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'RAMHIS Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Management Portal',
                  style: TextStyle(color: Color(0xFFE5ECFF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(navItems.length, (index) {
            final item = navItems[index];
            final selected = selectedIndex == index;

            return ListTile(
              leading: Icon(
                item.icon,
                color: selected
                    ? const Color(0xFF3F5FBE)
                    : const Color(0xFF6B7280),
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF3F5FBE)
                      : const Color(0xFF374151),
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: selected,
              selectedTileColor: const Color(0xFFEFF4FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                setState(() => selectedIndex = index);
                if (compact) Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}