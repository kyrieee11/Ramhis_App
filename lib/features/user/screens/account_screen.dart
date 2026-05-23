import 'package:flutter/material.dart';

import 'package:ramhis_app/models/user_model.dart';
import 'package:ramhis_app/services/api/auth_service.dart';
import 'package:ramhis_app/core/app_config.dart';

import 'package:ramhis_app/features/auth/screens/landing_page.dart';

import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';
import 'package:ramhis_app/core/session_manager.dart';

import 'package:ramhis_app/features/user/account/acc_about.dart';
import 'package:ramhis_app/features/user/account/acc_changepass.dart';
import 'package:ramhis_app/features/user/account/acc_privacy_policy.dart';
import 'package:ramhis_app/features/user/account/acc_termsand_conditions.dart';
import 'package:ramhis_app/features/user/account/acc_username.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({super.key});

  @override
  State<AccountWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoading = true;

  String fullName = 'User';
  String email = '';
  String accountType = 'Volunteer';

  UserModel? currentUser;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
  if (!mounted) return;

  setState(() => isLoading = true);

  try {
    final userData = await AuthService.fetchMe();

    final Map<String, dynamic> resolvedUserData =
        userData['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(userData['user'])
            : userData['data'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(userData['data'])
                : Map<String, dynamic>.from(userData);

    final UserModel user = UserModel.fromJson(resolvedUserData);

    currentUser = user;

    fullName = user.fullName.isEmpty ? 'User' : user.fullName;
    email = user.email;

    accountType = user.accountType.isEmpty
        ? 'Volunteer'
        : _capitalize(user.accountType);
  } catch (error) {
    debugPrint('❌ Failed to load profile: $error');

    final sessionUser = AuthSession.currentUser;

    if (sessionUser != null) {
      final firstName = (sessionUser['first_name'] ?? '').toString();
      final lastName = (sessionUser['last_name'] ?? '').toString();
      final sessionFullName =
          (sessionUser['full_name'] ?? '$firstName $lastName').toString();

      fullName = sessionFullName.trim().isEmpty ? 'User' : sessionFullName;
      email = (sessionUser['email'] ?? '').toString();

      final type = (sessionUser['account_type'] ??
              sessionUser['role'] ??
              'Volunteer')
          .toString();

      accountType = _capitalize(type);
    }
  }

  if (!mounted) return;

  setState(() => isLoading = false);
}

 Future<void> _openUserInformation() async {
  final sessionUser = AuthSession.currentUser;

  final String userId = currentUser?.id.isNotEmpty == true
      ? currentUser!.id
      : (sessionUser?['_id'] ?? sessionUser?['id'] ?? '').toString();

  if (userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User profile is not ready. Please refresh and try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AccUsernameWidget(
        userData: {
          '_id': userId,
          'full_name': currentUser?.fullName.isNotEmpty == true
              ? currentUser!.fullName
              : (sessionUser?['full_name'] ?? fullName).toString(),
          'email': currentUser?.email.isNotEmpty == true
              ? currentUser!.email
              : (sessionUser?['email'] ?? email).toString(),
          'contact_number': currentUser?.contactNumber.isNotEmpty == true
              ? currentUser!.contactNumber
              : (sessionUser?['contact_number'] ?? '').toString(),
          'birthdate': currentUser?.birthdate.isNotEmpty == true
              ? currentUser!.birthdate
              : (sessionUser?['birthdate'] ?? '').toString(),
          'profile_image_url': currentUser?.profileImageUrl.isNotEmpty == true
              ? currentUser!.profileImageUrl
              : (sessionUser?['profile_image_url'] ?? '').toString(),
        },
      ),
    ),
  );

  await _loadProfile();
}

  Future<void> _logout() async {
    try {
      await AuthService.logout();
    } catch (error) {
      debugPrint(
        '❌ Logout error: $error',
      );
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LandingpageWidget(),
      ),
      (route) => false,
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  String _resolveProfileImageUrl(
    String imageUrl,
  ) {
    if (imageUrl.isEmpty) {
      return '';
    }

    if (imageUrl.startsWith(
          'http://',
        ) ||
        imageUrl.startsWith(
          'https://',
        )) {
      return imageUrl;
    }

    return '${AppConfig.baseUrl}$imageUrl';
  }

  Color _roleColor(String role) {
    final normalized = role.toLowerCase();

    if (normalized.contains('doctor')) {
      return const Color(0xFF1976D2);
    }

    if (normalized.contains('volunteer')) {
      return const Color(0xFF388E3C);
    }

    if (normalized.contains('pharmacist')) {
      return const Color(0xFF7B1FA2);
    }

    if (normalized.contains('admin')) {
      return const Color(0xFFD32F2F);
    }

    return const Color(0xFF3949AB);
  }

  Color _avatarFallbackColor(String name) {
    final first = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

    if ('ABCDE'.contains(first)) {
      return const Color(0xFFF44336);
    }

    if ('FGHIJ'.contains(first)) {
      return const Color(0xFF9C27B0);
    }

    if ('KLMNO'.contains(first)) {
      return const Color(0xFF2196F3);
    }

    if ('PQRST'.contains(first)) {
      return const Color(0xFF4CAF50);
    }

    return const Color(0xFFFF9800);
  }

  String _initials(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      return 'U';
    }

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Widget _buildAvatar() {
    final imageUrl = currentUser?.profileImageUrl ?? '';

    if (imageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.12,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 44,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(
            _resolveProfileImageUrl(
              imageUrl,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.12,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 44,
        backgroundColor: _avatarFallbackColor(fullName),
        child: Text(
          _initials(fullName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF0F2FF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 230,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF5B76F7),
                      Color(0xFF4564E8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4564E8),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            8,
                            18,
                            20,
                          ),
                          child: Column(
                            children: [
                              _buildProfileCard(),
                              const SizedBox(height: 22),
                              _buildMenuSection(),
                              const SizedBox(height: 22),
                              _buildLogoutButton(),
                              const SizedBox(height: 22),
                              _buildVersionInfo(),
                            ],
                          ),
                        ),
                ),
                const CustomNavBar(
                  currentIndex: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      20,
      18,
      20,
      14,
    ),
    child: Row(
      children: [
        const SizedBox(width: 54),
        const Expanded(
          child: Text(
            'Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color.fromARGB(255, 255, 255, 255),
              letterSpacing: -1,
            ),
          ),
        ),
        SizedBox(
          width: 54,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {},
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 249, 249, 249).withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Color(0xFF4B63D2),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildProfileCard() {
    final roleColor = _roleColor(accountType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B76F7),
            Color(0xFF4564E8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B76F7).withValues(
              alpha: 0.30,
            ),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -44,
            bottom: -48,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.06,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 34,
            top: 38,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 15,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -42,
            top: -44,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _openUserInformation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  width: 1.2,
                                ),
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: roleColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            accountType,
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Account Settings'),
        const SizedBox(height: 8),
        _menuGroup(
          children: [
            _menuTile(
  title: 'User Information',
  icon: Icons.person_outline_rounded,
  iconColor: const Color(0xFF4B63D2),
  iconBg: const Color(0xFFE8EEFF),
  onTap: _openUserInformation,
),
            _divider(),
            _menuTile(
              title: 'Change Password',
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFF4B63D2),
              iconBg: const Color(0xFFE8EEFF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountChangePasswordScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('Legal & Info'),
        const SizedBox(height: 8),
        _menuGroup(
          children: [
            _menuTile(
              title: 'Privacy Policy',
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF2BBE9B),
              iconBg: const Color(0xFFE8FFF8),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccPrivacyPolicyWidget(),
                ),
              ),
            ),
            _divider(),
            _menuTile(
              title: 'Terms & Conditions',
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF7A5AF8),
              iconBg: const Color(0xFFF1ECFF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccTermsandConditionsWidget(),
                ),
              ),
            ),
            _divider(),
            _menuTile(
              title: 'About',
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF5B76F7),
              iconBg: const Color(0xFFEAF0FF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccAboutWidget(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF7B739A),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _menuGroup({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 82),
      child: Container(
        height: 1,
        color: const Color(0xFFE9ECF5),
      ),
    );
  }

  Widget _menuTile({
  required String title,
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B2559),
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF7B739A),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              bool isLoggingOut = false;

              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFF1B2559),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    content: const Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(
                        color: Color(0xFF7B739A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    actions: [
                      TextButton(
                        onPressed: isLoggingOut
                            ? null
                            : () {
                                Navigator.pop(dialogContext);
                              },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF7B739A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isLoggingOut
                            ? null
                            : () async {
                                setDialogState(() {
                                  isLoggingOut = true;
                                });

                                await _logout();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE84D63),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoggingOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Log Out',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        icon: const Icon(
          Icons.logout_rounded,
          color: Color(0xFFE84D63),
        ),
        label: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE84D63),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFE84D63),
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 17,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return const Column(
      children: [
        Text(
          'RAMHIS v1.0.0',
          style: TextStyle(
            color: Color(0xFF7B739A),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Remote Area Medical Health Information System',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9AA3BD),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}