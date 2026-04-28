// CLEAN ADMIN SHELL (DASHBOARD REMOVED)

import 'package:flutter/material.dart';

import 'admin_users_management.dart';
import 'admin_doctors_verification.dart';
import 'admin_volunteer_management.dart';
import 'admin_events_management.dart';
import 'admin_content_management.dart';

class AdminShellWidget extends StatefulWidget {
  const AdminShellWidget({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminShellWidget> createState() => _AdminShellWidgetState();
}

class _AdminShellWidgetState extends State<AdminShellWidget> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex.clamp(0, navItems.length - 1);
  }

  List<_AdminNavItem> get navItems => [
  const _AdminNavItem(
    label: 'Users',
    icon: Icons.people_alt_rounded,
    page: AdminUsersManagementConnectedWidget(),
  ),
  const _AdminNavItem(
    label: 'Doctors',
    icon: Icons.local_hospital_rounded,
    page: AdminDoctorsVerificationConnectedWidget(),
  ),
  const _AdminNavItem(
    label: 'Volunteers',
    icon: Icons.volunteer_activism_rounded,
    page: AdminVolunteerManagementConnectedWidget(),
  ),
  const _AdminNavItem(
    label: 'Events',
    icon: Icons.event_rounded,
    page: AdminEventsManagementConnectedWidget(),
  ),
  const _AdminNavItem(
    label: 'Content',
    icon: Icons.description_rounded,
    page: AdminContentManagementConnectedWidget(),
  ),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 230,
            color: const Color(0xFF4267D6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

Center(
  child: Image.asset(
    'assets/images/ramhis_logo.png',
    width: 82,
    height: 82,
    fit: BoxFit.contain,
  ),
),

const SizedBox(height: 12),

const Center(
  child: Text(
    'RAMHIS Admin',
    style: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const Center(
  child: Text(
    'Management Portal',
    style: TextStyle(
      color: Colors.white70,
      fontSize: 12,
    ),
  ),
),

const SizedBox(height: 28),

                ...List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = selectedIndex == index;

                  return ListTile(
                    leading: Icon(item.icon,
                        color: isSelected ? Colors.white : Colors.white70),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.white.withValues(alpha: 0.15),
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                  );
                }),

                const Spacer(),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Logout',
                      style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: navItems[selectedIndex].page,
          ),
        ],
      ),
    );
  }
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final Widget page;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.page,
  });
}
