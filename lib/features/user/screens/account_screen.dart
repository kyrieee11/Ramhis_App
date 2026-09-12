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

const _kNavy = Color(0xFF10539B);
const _kNavyDark = Color(0xFF1863B5);
const _kBlueAccent = Color(0xFF8EC1DA);
const _kBlueAccentDark = Color(0xFF1863B5);
const _kCream = Color(0xFFF8FAFC);
const _kInk = Color(0xFF102A43);
const _kMuted = Color(0xFF8292A6);
const _kMedBlue = Color(0xFF5D8FC8);
const _kLightBlue = Color(0xFFEBF3FA);
const _kGray = Color(0xFFEDEDED);
const _kLightRed = Color(0xFFFFEFEF);
const _kMedRed = Color(0xFFE58B8B);
const _kDarkRed = Color(0xFFD95C5C);


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
    if (normalized.contains('doctor')) return _kNavy;
    if (normalized.contains('volunteer')) return _kNavy;
    if (normalized.contains('pharmacist')) return _kMedBlue;
    if (normalized.contains('admin')) return _kDarkRed;
    return _kNavy;
  }

  Color _avatarFallbackColor(String name) {
    final first = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    if ('ABCDE'.contains(first)) return _kMedRed;
    if ('FGHIJ'.contains(first)) return _kMedBlue;
    if ('KLMNO'.contains(first)) return _kNavy;
    if ('PQRST'.contains(first)) return _kNavy;
    return _kMedRed;
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
        bottom: false,
        child: Column(
          children: [
            _buildProfileHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kNavy),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      child: Column(
                        children: [
                          _buildMenuSection(),
                          const SizedBox(height: 18),
                          _buildLogoutButton(),
                          const SizedBox(height: 14),
                          _buildVersionInfo(),
                        ],
                      ),
                    ),
            ),
            const CustomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final roleColor = _roleColor(accountType);

    return SizedBox(
      height: 224,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AccountHeaderPainter(),
            ),
          ),
          Positioned(
            top: 10,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.maybePop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 72,
            child: isLoading
                ? const SizedBox(
                    height: 105,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 7),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              const SizedBox(height: 9),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  accountType,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
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
        _sectionTitle('Account'),
        const SizedBox(height: 8),
        _menuGroup(
          children: [
            _menuTile(
              title: 'User Information',
              icon: Icons.person_outline_rounded,
              onTap: _openUserInformation,
            ),
            _divider(),
            _menuTile(
              title: 'Change Password',
              icon: Icons.lock_outline_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountChangePasswordScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('Legal & Information'),
        const SizedBox(height: 8),
        _menuGroup(
          children: [
            _menuTile(
              title: 'Privacy Policy',
              icon: Icons.shield_outlined,
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
        title,
        style: const TextStyle(
          color: _kNavy,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _menuGroup({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _kLightBlue.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68, right: 16),
      child: Container(
        height: 1,
        color: _kGray,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kLightBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: _kNavy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF202333),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB7BCC5),
                size: 23,
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
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () {
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
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Color(0xFF202333),
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isLoggingOut
                              ? null
                              : () async {
                                  setDialogState(
                                    () => isLoggingOut = true,
                                  );
                                  await _logout();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kDarkRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: isLoggingOut
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
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
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: _kDarkRed,
                  size: 19,
                ),
                SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: _kDarkRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Remote Area Medical Health Information System',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AccountHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [_kNavy, _kBlueAccentDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.66)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.88,
        size.width * 0.58,
        size.height * 0.94,
        size.width * 0.38,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.64,
        size.width * 0.08,
        size.height * 0.72,
        0,
        size.height * 0.56,
      )
      ..close();

    canvas.drawPath(path, paint);

    final highlight = Paint()
      ..color = _kBlueAccent.withValues(alpha: 0.24);

    final highlightPath = Path()
      ..moveTo(size.width * 0.62, 0)
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.18,
        size.width * 0.74,
        size.height * 0.40,
        size.width,
        size.height * 0.46,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(highlightPath, highlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarbleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = _kCream;
    canvas.drawRect(Offset.zero & size, base);

    final line = Paint()
      ..color = _kLightBlue.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path()
      ..moveTo(0, size.height * .22)
      ..cubicTo(
        size.width * .25,
        size.height * .12,
        size.width * .18,
        size.height * .42,
        size.width * .48,
        size.height * .52,
      )
      ..cubicTo(
        size.width * .70,
        size.height * .60,
        size.width * .62,
        size.height * .82,
        size.width,
        size.height * .72,
      );

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
