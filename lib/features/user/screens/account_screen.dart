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

const _kNavy = Color(0xFF123F91);
const _kNavyDark = Color(0xFF082B6B);
const _kGold = Color(0xFFD9C27A);
const _kGoldDark = Color(0xFF9D7D2F);
const _kCream = Color(0xFFF7F2E5);
const _kInk = Color(0xFF24304A);
const _kMuted = Color(0xFF6F7480);

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

      fullName = user.fullName.isNotEmpty
          ? user.fullName
          : _resolveFullName(resolvedUserData);

      email = user.email.isNotEmpty
          ? user.email
          : _readString(resolvedUserData, ['email']);

      accountType = user.accountType.isNotEmpty
          ? _capitalize(user.accountType)
          : _resolveAccountType(resolvedUserData);
    } catch (error) {
      debugPrint('❌ Failed to load profile: $error');

      final sessionUser = AuthSession.currentUser;

      if (sessionUser != null) {
        fullName = _resolveFullName(sessionUser);
        email = _readString(sessionUser, ['email']);
        accountType = _resolveAccountType(sessionUser);
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
          content: Text(
              'User profile is not ready. Please refresh and try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccUsernameWidget(
          userData: {
            '_id': userId,
            'id': userId,
            'full_name': currentUser?.fullName.isNotEmpty == true
                ? currentUser!.fullName
                : (sessionUser?['full_name'] ??
                        sessionUser?['fullName'] ??
                        sessionUser?['name'] ??
                        fullName)
                    .toString(),
            'fullName': currentUser?.fullName.isNotEmpty == true
                ? currentUser!.fullName
                : (sessionUser?['fullName'] ??
                        sessionUser?['full_name'] ??
                        sessionUser?['name'] ??
                        fullName)
                    .toString(),
            'name': currentUser?.fullName.isNotEmpty == true
                ? currentUser!.fullName
                : (sessionUser?['name'] ??
                        sessionUser?['full_name'] ??
                        sessionUser?['fullName'] ??
                        fullName)
                    .toString(),
            'email': currentUser?.email.isNotEmpty == true
                ? currentUser!.email
                : (sessionUser?['email'] ?? email).toString(),
            'contact_number': currentUser?.contactNumber.isNotEmpty == true
                ? currentUser!.contactNumber
                : (sessionUser?['contact_number'] ??
                        sessionUser?['contactNumber'] ??
                        sessionUser?['phone'] ??
                        sessionUser?['phoneNumber'] ??
                        '')
                    .toString(),
            'contactNumber': currentUser?.contactNumber.isNotEmpty == true
                ? currentUser!.contactNumber
                : (sessionUser?['contactNumber'] ??
                        sessionUser?['contact_number'] ??
                        sessionUser?['phone'] ??
                        sessionUser?['phoneNumber'] ??
                        '')
                    .toString(),
            'birthDate': currentUser?.birthdate.isNotEmpty == true
                ? currentUser!.birthdate
                : (sessionUser?['birthDate'] ??
                        sessionUser?['birthdate'] ??
                        sessionUser?['birthday'] ??
                        sessionUser?['bdate'] ??
                        '')
                    .toString(),
            'birthday': currentUser?.birthdate.isNotEmpty == true
                ? currentUser!.birthdate
                : (sessionUser?['birthday'] ??
                        sessionUser?['birthdate'] ??
                        sessionUser?['birthDate'] ??
                        sessionUser?['bdate'] ??
                        '')
                    .toString(),
            'bdate': currentUser?.birthdate.isNotEmpty == true
                ? currentUser!.birthdate
                : (sessionUser?['bdate'] ??
                        sessionUser?['birthdate'] ??
                        sessionUser?['birthDate'] ??
                        sessionUser?['birthday'] ??
                        '')
                    .toString(),
            'profile_image_url':
                currentUser?.profileImageUrl.isNotEmpty == true
                    ? currentUser!.profileImageUrl
                    : (sessionUser?['profile_image_url'] ??
                            sessionUser?['profileImageUrl'] ??
                            sessionUser?['profileImage'] ??
                            '')
                        .toString(),
          },
        ),
      ),
    );

    if (updatedUser is Map) {
      final syncedUser = Map<String, dynamic>.from(updatedUser);

      await AuthSession.updateCurrentUser(syncedUser);

      if (!mounted) return;

      setState(() {
        currentUser = UserModel.fromJson(syncedUser);
        fullName = _resolveFullName(syncedUser);
        email = _readString(syncedUser, ['email']);
        accountType = _resolveAccountType(syncedUser);
      });
    }

    await _loadProfile();
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
    } catch (error) {
      debugPrint('❌ Logout error: $error');
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
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _readString(
    Map<String, dynamic>? data,
    List<String> keys, [
    String fallback = '',
  ]) {
    if (data == null) return fallback;
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  String _resolveFullName(Map<String, dynamic>? data) {
    final direct = _readString(data, ['full_name', 'name', 'fullName']);
    if (direct.isNotEmpty) return direct;
    final firstName = _readString(data, ['first_name', 'firstName']);
    final lastName = _readString(data, ['last_name', 'lastName']);
    final combined = '$firstName $lastName'.trim();
    return combined.isEmpty ? 'User' : combined;
  }

  String _resolveAccountType(Map<String, dynamic>? data) {
    final value = _readString(
        data, ['account_type', 'role', 'accountType'], 'Volunteer');
    return _capitalize(value);
  }

  String _resolveProfileImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }
  final path = imageUrl.startsWith('/uploads')
      ? imageUrl.substring('/uploads'.length)
      : (imageUrl.startsWith('/') ? imageUrl : '/$imageUrl');
  return '${AppConfig.uploadsBaseUrl}$path';
}

  Color _roleColor(String role) {
    final normalized = role.toLowerCase();
    if (normalized.contains('doctor')) return const Color(0xFF1976D2);
    if (normalized.contains('volunteer')) return const Color(0xFF388E3C);
    if (normalized.contains('pharmacist')) return const Color(0xFF7B1FA2);
    if (normalized.contains('admin')) return const Color(0xFFD32F2F);
    return const Color(0xFF3949AB);
  }

  Color _avatarFallbackColor(String name) {
    final first = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    if ('ABCDE'.contains(first)) return const Color(0xFFF44336);
    if ('FGHIJ'.contains(first)) return const Color(0xFF9C27B0);
    if ('KLMNO'.contains(first)) return const Color(0xFF2196F3);
    if ('PQRST'.contains(first)) return const Color(0xFF4CAF50);
    return const Color(0xFFFF9800);
  }

  String _initials(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Widget _buildAvatar() {
    final imageUrl = currentUser?.profileImageUrl ?? '';

    if (imageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 44,
          backgroundColor: Colors.white,
          backgroundImage:
              NetworkImage(_resolveProfileImageUrl(imageUrl)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
      backgroundColor: _kCream,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MarbleBackgroundPainter(),
              ),
            ),
            Column(
              children: [
                _buildHeader(),
                _buildProfileCard(),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _kGoldDark,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                          child: Column(
                            children: [
                              _buildMenuSection(),
                              const SizedBox(height: 16),
                              _buildLogoutButton(),
                              const SizedBox(height: 16),
                              _buildVersionInfo(),
                            ],
                          ),
                        ),
                ),
                const CustomNavBar(currentIndex: 3),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: _kGold, width: 1.4),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _kGold,
                  size: 21,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kCream,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final roleColor = _roleColor(accountType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: _kGold, width: 1.2),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 118,
              child: Center(
                child: CircularProgressIndicator(color: _kGold),
              ),
            )
          : Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kCream,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _kCream,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: _kGold, width: 1),
                        ),
                        child: Text(
                          accountType,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
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
        const SizedBox(height: 7),
        _menuGroup(
          children: [
            _menuTile(
              title: 'User Information',
              icon: Icons.person_rounded,
              onTap: _openUserInformation,
            ),
            _divider(),
            _menuTile(
              title: 'Change Password',
              icon: Icons.lock_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountChangePasswordScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _sectionTitle('Legal & Info'),
        const SizedBox(height: 7),
        _menuGroup(
          children: [
            _menuTile(
              title: 'Privacy Policy',
              icon: Icons.shield_rounded,
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
              icon: Icons.description_rounded,
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
              icon: Icons.info_rounded,
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
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _kInk,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _menuGroup({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCream.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGoldDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 84, right: 14),
      child: Container(
        height: 1,
        color: _kNavy.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _menuTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kNavy, _kNavyDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _kGold, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: _kCream,
                  size: 29,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _kGoldDark,
                size: 19,
              ),
            ],
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
                    backgroundColor: _kCream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: _kGold, width: 1.2),
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: _kInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    content: const Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(
                        color: _kMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    actionsPadding:
                        const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    actions: [
                      TextButton(
                        onPressed: isLoggingOut
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: _kMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isLoggingOut
                            ? null
                            : () async {
                                setDialogState(() => isLoggingOut = true);
                                await _logout();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA72B2B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                style: TextStyle(fontWeight: FontWeight.w800),
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
          color: Color(0xFFA72B2B),
        ),
        label: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFFA72B2B),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kGoldDark, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: _kCream.withValues(alpha: 0.96),
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
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Remote Area Medical Health Information System',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}

class _MarbleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = _kCream;
    canvas.drawRect(Offset.zero & size, base);

    final vein = Paint()
      ..color = const Color(0xFF9EA9B8).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final veinSoft = Paint()
      ..color = const Color(0xFFBFC6D0).withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    final paths = <Path>[
      Path()
        ..moveTo(size.width * .10, 0)
        ..cubicTo(size.width * .26, size.height * .12,
            size.width * .10, size.height * .22,
            size.width * .38, size.height * .32)
        ..cubicTo(size.width * .60, size.height * .40,
            size.width * .36, size.height * .55,
            size.width * .64, size.height * .67)
        ..cubicTo(size.width * .80, size.height * .75,
            size.width * .62, size.height * .90,
            size.width * .90, size.height),
      Path()
        ..moveTo(size.width * .92, size.height * .02)
        ..cubicTo(size.width * .74, size.height * .16,
            size.width * .88, size.height * .27,
            size.width * .65, size.height * .39)
        ..cubicTo(size.width * .48, size.height * .48,
            size.width * .72, size.height * .61,
            size.width * .45, size.height * .80),
      Path()
        ..moveTo(size.width * .02, size.height * .72)
        ..cubicTo(size.width * .20, size.height * .66,
            size.width * .16, size.height * .84,
            size.width * .02, size.height * .94),
    ];

    for (final path in paths) {
      canvas.drawPath(path, vein);
    }

    canvas.drawPath(
      Path()
        ..moveTo(size.width * .04, size.height * .15)
        ..cubicTo(size.width * .32, size.height * .21,
            size.width * .13, size.height * .31,
            size.width * .44, size.height * .38)
        ..cubicTo(size.width * .65, size.height * .44,
            size.width * .43, size.height * .56,
            size.width * .72, size.height * .65),
      veinSoft,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
