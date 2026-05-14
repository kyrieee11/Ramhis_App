import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:ramhis_app/core/session_manager.dart';

class AdminUsersManagementConnectedWidget extends StatefulWidget {
  const AdminUsersManagementConnectedWidget({super.key});

  @override
  State<AdminUsersManagementConnectedWidget> createState() =>
      _AdminUsersManagementConnectedWidgetState();
}

class _AdminUsersManagementConnectedWidgetState
    extends State<AdminUsersManagementConnectedWidget> {
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  bool isProcessing = false;

  String selectedRole = 'All Roles';
  String selectedStatus = 'All Status';
  String searchQuery = '';

  List<Map<String, dynamic>> users = [];

  static const Color primary = Color(0xFF2563EB);
  static const Color bg = Color(0xFFF6F8FC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F1B3D);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    fetchUsers();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.trim().toLowerCase();
    });
  }

  List<Map<String, dynamic>> get filteredUsers {
    return users.where((user) {
      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = _displayRole(user);
      final status = _displayStatus(user);

      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          email.contains(searchQuery) ||
          role.toLowerCase().contains(searchQuery);

      final matchesRole = selectedRole == 'All Roles' || role == selectedRole;
      final matchesStatus =
          selectedStatus == 'All Status' || status == selectedStatus;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  int get doctorCount =>
      users.where((user) => _displayRole(user) == 'Doctor').length;

  int get volunteerCount =>
      users.where((user) => _displayRole(user) == 'Volunteer').length;

  int get pendingCount =>
      users.where((user) => _displayStatus(user) == 'Pending').length;

  Future<void> fetchUsers() async {
    if (mounted) setState(() => isLoading = true);

    try {
      debugPrint('ACCESS TOKEN BEFORE ADMIN USERS: ${AuthSession.accessToken}');
debugPrint('HEADERS BEFORE ADMIN USERS: ${AuthSession.headers()}');

     final response = await http.get(
  Uri.parse('${AuthSession.baseUrl}/admin/users'),
  headers: AuthSession.headers(),
);
debugPrint('ADMIN USERS STATUS: ${response.statusCode}');
debugPrint('ADMIN USERS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          users = data.map((item) => Map<String, dynamic>.from(item)).toList();
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

  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    if (userId.isEmpty) {
      _showSnackBar('Invalid user ID.');
      return;
    }

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
  Uri.parse('${AuthSession.baseUrl}/admin/users/$userId/status'),
  headers: AuthSession.headers(),
  body: jsonEncode({
    'status': status.toLowerCase(),
  }),
);

      if (response.statusCode == 200) {
        _showSnackBar('User updated to $status.');
        await fetchUsers();
      } else {
        _showSnackBar('Failed to update user.');
      }
    } catch (_) {
      _showSnackBar('Connection error while updating user.');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  String _displayRole(Map<String, dynamic> user) {
    final role = (user['role'] ?? '').toString().toLowerCase();
    final type = (user['account_type'] ?? '').toString().toLowerCase();

    if (role == 'admin') return 'Admin';
    if (type == 'doctor') return 'Doctor';
    if (type == 'volunteer') return 'Volunteer';

    return 'User';
  }

  String _displayStatus(Map<String, dynamic> user) {
    final raw = (user['status'] ?? 'active').toString().trim().toLowerCase();

    if (raw == 'pending') return 'Pending';
    if (raw == 'suspended') return 'Suspended';
    if (raw == 'disabled') return 'Disabled';

    return 'Active';
  }

  DateTime? _joinedDate(Map<String, dynamic> user) {
    final raw = (user['createdAt'] ?? user['created_at'] ?? '').toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _formatJoined(DateTime? date) {
    if (date == null) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
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
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topHeader(),
                  const SizedBox(height: 26),
                  _statsGrid(),
                  const SizedBox(height: 24),
                  _usersPanel(),
                ],
              ),
            ),
    );
  }

  Widget _topHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;

        const title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Users Management',
              style: TextStyle(
                color: textDark,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Manage registered users and their account details.',
              style: TextStyle(
                color: Color(0xFF53668D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _refreshButton(),
            const SizedBox(width: 12),
            _addUserButton(),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 16),
              actions,
            ],
          );
        }

        return Row(
          children: [
            const Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }

  Widget _statsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 640
            ? 1
            : width < 980
                ? 2
                : 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: width < 640 ? 3.8 : 2.65,
          children: [
            _statCard(
              icon: Icons.person_outline_rounded,
              title: 'Total Users',
              value: users.length.toString(),
              note: 'All registered accounts',
              color: const Color(0xFF4F46E5),
              bgColor: const Color(0xFFEEF2FF),
            ),
            _statCard(
              icon: Icons.medical_services_outlined,
              title: 'Doctors',
              value: doctorCount.toString(),
              note: 'Verified health accounts',
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
            ),
            _statCard(
              icon: Icons.volunteer_activism_outlined,
              title: 'Volunteers',
              value: volunteerCount.toString(),
              note: 'Community responders',
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFDCFCE7),
            ),
            _statCard(
              icon: Icons.schedule_rounded,
              title: 'Pending',
              value: pendingCount.toString(),
              note: 'Needs review',
              color: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFEF3C7),
            ),
          ],
        );
      },
    );
  }

  Widget _usersPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _toolbar(),
          const SizedBox(height: 24),
          _responsiveUserList(),
          const SizedBox(height: 18),
          _footerInfo(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 780;

        final search = SizedBox(
          width: isNarrow ? double.infinity : 400,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
              ),
              hintText: 'Search by name, email, or role...',
              hintStyle: const TextStyle(
                color: Color(0xFF8A9AB8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD6E0F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primary, width: 1.4),
              ),
            ),
          ),
        );

        final filters = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterDropdown(
              value: selectedRole,
              values: const [
                'All Roles',
                'Admin',
                'Doctor',
                'Volunteer',
                'User',
              ],
              onChanged: (value) => setState(() => selectedRole = value),
            ),
            const SizedBox(width: 12),
            _filterDropdown(
              value: selectedStatus,
              values: const [
                'All Status',
                'Active',
                'Pending',
                'Suspended',
                'Disabled',
              ],
              onChanged: (value) => setState(() => selectedStatus = value),
            ),
            const SizedBox(width: 12),
            _filterIconButton(),
          ],
        );

        if (isNarrow) {
          return Column(
            children: [
              search,
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: filters,
              ),
            ],
          );
        }

        return Row(
          children: [
            search,
            const Spacer(),
            filters,
          ],
        );
      },
    );
  }

  Widget _responsiveUserList() {
    if (filteredUsers.isEmpty) {
      return _emptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return Column(
            children: filteredUsers.map(_mobileUserCard).toList(),
          );
        }

        return _userTable();
      },
    );
  }

  Widget _userTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 58,
              color: const Color(0xFFFAFCFF),
              child: const Row(
                children: [
                  Expanded(flex: 4, child: _TableHeading('User')),
                  Expanded(flex: 2, child: _TableHeading('Role')),
                  Expanded(flex: 2, child: _TableHeading('Status')),
                  Expanded(flex: 2, child: _TableHeading('Joined')),
                  SizedBox(width: 88, child: _TableHeading('Actions')),
                ],
              ),
            ),
            ...List.generate(filteredUsers.length, (index) {
              final user = filteredUsers[index];
              return _userRow(
                user,
                isLast: index == filteredUsers.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _userRow(Map<String, dynamic> user, {required bool isLast}) {
    final role = _displayRole(user);
    final status = _displayStatus(user);
    final joined = _formatJoined(_joinedDate(user));

    return Container(
      height: 78,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE8EEF7)),
              ),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _userIdentity(user)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _roleBadge(role),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(status),
            ),
          ),
          Expanded(flex: 2, child: Text(joined, style: _tableTextStyle)),
          SizedBox(width: 88, child: Center(child: _actionsMenu(user))),
        ],
      ),
    );
  }

  Widget _mobileUserCard(Map<String, dynamic> user) {
    final role = _displayRole(user);
    final status = _displayStatus(user);
    final joined = _formatJoined(_joinedDate(user));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _userIdentity(user, compact: true)),
              _actionsMenu(user),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _roleBadge(role),
              _statusBadge(status),
              _datePill(joined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userIdentity(Map<String, dynamic> user, {bool compact = false}) {
    final name = (user['full_name'] ?? 'Unknown User').toString();
    final email = (user['email'] ?? 'No email').toString();
    final initials = _initials(name);
    final colorSet = _avatarColor(name);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorSet.bg,
            child: Text(
              initials,
              style: TextStyle(
                color: colorSet.fg,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    final color = role == 'Doctor'
        ? primary
        : role == 'Volunteer'
            ? const Color(0xFF0F9F6E)
            : role == 'Admin'
                ? const Color(0xFF7C3AED)
                : const Color(0xFF64748B);

    final bgColor = role == 'Doctor'
        ? const Color(0xFFEAF2FF)
        : role == 'Volunteer'
            ? const Color(0xFFE1F7EE)
            : role == 'Admin'
                ? const Color(0xFFF3E8FF)
                : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final isActive = normalized == 'active';
    final isPending = normalized == 'pending';

    final color = isActive
        ? const Color(0xFF16A34A)
        : isPending
            ? const Color(0xFFF97316)
            : const Color(0xFFE11D48);

    final bgColor = isActive
        ? const Color(0xFFDFF7EA)
        : isPending
            ? const Color(0xFFFFEDD5)
            : const Color(0xFFFFE4E6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePill(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(date, style: _tableTextStyle),
    );
  }

  Widget _actionsMenu(Map<String, dynamic> user) {
    final userId = (user['_id'] ?? '').toString();

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6E0F0)),
      ),
      child: PopupMenuButton<String>(
        enabled: !isProcessing && userId.isNotEmpty,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: Color(0xFF38517D),
        ),
        onSelected: (value) => updateUserStatus(
          userId: userId,
          status: value,
        ),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'Active', child: Text('Activate')),
          PopupMenuItem(value: 'Pending', child: Text('Mark Pending')),
          PopupMenuItem(value: 'Suspended', child: Text('Suspend')),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String note,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 150,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF53668D),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refreshButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: isProcessing ? null : fetchUsers,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text('Refresh'),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFC7D7F8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _addUserButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _showSnackBar('Add user action is not configured yet.'),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add User'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 160,
      height: 48,
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD6E0F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 1.3),
          ),
        ),
        style: const TextStyle(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        items: values.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _filterIconButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6E0F0)),
      ),
      child: const Icon(
        Icons.filter_alt_outlined,
        color: Color(0xFF38517D),
      ),
    );
  }

  Widget _footerInfo() {
    final count = filteredUsers.length;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing ${count == 0 ? 0 : 1} to $count of ${users.length} users',
            style: const TextStyle(
              color: Color(0xFF53668D),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (count > 0) _paginationMock(),
      ],
    );
  }

  Widget _paginationMock() {
    return Row(
      children: [
        _pageButton(Icons.chevron_left_rounded),
        const SizedBox(width: 8),
        _pageNumber('1', active: true),
        const SizedBox(width: 8),
        _pageNumber('2'),
        const SizedBox(width: 8),
        _pageNumber('3'),
        const SizedBox(width: 8),
        _pageNumber('...'),
        const SizedBox(width: 8),
        _pageButton(Icons.chevron_right_rounded),
      ],
    );
  }

  Widget _pageButton(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6E0F0)),
      ),
      child: Icon(icon, color: const Color(0xFF38517D), size: 20),
    );
  }

  Widget _pageNumber(String text, {bool active = false}) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? primary : const Color(0xFFD6E0F0)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : textDark,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 54),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 54,
            color: Color(0xFF8A9AB8),
          ),
          SizedBox(height: 14),
          Text(
            'No users found',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing your search or filter options.',
            style: TextStyle(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      final first = parts.first;
      return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  _AvatarColor _avatarColor(String value) {
    const colors = [
      _AvatarColor(Color(0xFFEEF2FF), Color(0xFF4F46E5)),
      _AvatarColor(Color(0xFFE0F2FE), Color(0xFF0284C7)),
      _AvatarColor(Color(0xFFDCFCE7), Color(0xFF16A34A)),
      _AvatarColor(Color(0xFFFFF7ED), Color(0xFFF97316)),
      _AvatarColor(Color(0xFFF3E8FF), Color(0xFF7C3AED)),
    ];

    final index =
        value.codeUnits.fold<int>(0, (sum, code) => sum + code) % colors.length;

    return colors[index];
  }

  static const TextStyle _tableTextStyle = TextStyle(
    color: Color(0xFF53668D),
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
}

class _TableHeading extends StatelessWidget {
  const _TableHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AvatarColor {
  const _AvatarColor(this.bg, this.fg);

  final Color bg;
  final Color fg;
}
