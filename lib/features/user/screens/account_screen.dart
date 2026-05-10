import 'package:flutter/material.dart';

import 'package:ramhis_app/services/api/auth_service.dart';
import 'package:ramhis_app/services/api/user_service.dart';
import 'package:ramhis_app/models/user_model.dart';

import 'package:ramhis_app/features/auth/screens/landing_page.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';

import 'package:ramhis_app/features/user/account/acc_username.dart';
import 'package:ramhis_app/features/user/account/acc_changepass.dart';
import 'package:ramhis_app/features/user/account/acc_privacy_policy.dart';
import 'package:ramhis_app/features/user/account/acc_termsand_conditions.dart';
import 'package:ramhis_app/features/user/account/acc_about.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({super.key});

  @override
  State<AccountWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

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
      final UserModel? user = await _userService.getProfile();

      if (user != null) {
        currentUser = user;

        fullName = user.fullName.isEmpty
            ? 'User'
            : user.fullName;

        email = user.email;

        accountType = user.accountType.isEmpty
            ? 'Volunteer'
            : _capitalize(user.accountType);
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() => isLoading = false);
  }

  Future<void> _openUserInformation() async {
    if (currentUser == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccUsernameWidget(
          userData: {
            '_id': currentUser!.id,
            'full_name': currentUser!.fullName,
            'email': currentUser!.email,
            'contact_number': currentUser!.contactNumber,
            'birthdate': currentUser!.birthdate,
            'profile_image_url': currentUser!.profileImageUrl,
          },
        ),
      ),
    );

    await _loadProfile();
  }

  Future<void> _logout() async {
    await _authService.logout();

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

  String _resolveProfileImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';

    if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    return 'http://10.0.2.2:5000$imageUrl';
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
              color: Colors.black.withValues(alpha:0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 42,
          backgroundColor: Colors.white,
          backgroundImage:
              NetworkImage(_resolveProfileImageUrl(imageUrl)),
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
            color: Colors.black.withValues(alpha:0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 42,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person_rounded,
          size: 42,
          color: Color(0xFF3F5FBE),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            _buildHeader(),

            /// CONTENT
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        12,
                        18,
                        20,
                      ),
                      child: Column(
                        children: [

                          /// PROFILE CARD
                          _buildProfileCard(),

                          const SizedBox(height: 22),

                          /// MENU SECTION
                          _buildMenuSection(),

                          const SizedBox(height: 24),

                          /// LOGOUT BUTTON
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
            ),

            /// NAVIGATION BAR
            const CustomNavBar(currentIndex: 3),
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

          /// ICON CONTAINER
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF4B63D2),
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          /// TITLE
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2559),
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
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
            color: const Color(0xFF5B76F7)
               .withValues(alpha:0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: Stack(
        children: [

          /// DECORATION
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: -40,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),

          /// CONTENT
          Column(
            children: [

              _buildAvatar(),

              const SizedBox(height: 18),

              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFE5ECFF),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  accountType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [

          _menuTile(
            title: 'User Information',
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF4B63D2),
            iconBg: const Color(0xFFE8EEFF),
            onTap: _openUserInformation,
          ),

          _menuTile(
            title: 'Change Password',
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF4B63D2),
            iconBg: const Color(0xFFE8EEFF),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AccChangepassWidget(),
              ),
            ),
          ),

          _menuTile(
            title: 'Privacy Policy',
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF2BBE9B),
            iconBg: const Color(0xFFE8FFF8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AccPrivacyPolicyWidget(),
              ),
            ),
          ),

          _menuTile(
            title: 'Terms & Conditions',
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF7A5AF8),
            iconBg: const Color(0xFFF1ECFF),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AccTermsandConditionsWidget(),
              ),
            ),
          ),

          _menuTile(
            title: 'About',
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF5B76F7),
            iconBg: const Color(0xFFEAF0FF),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AccAboutWidget(),
              ),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [

                /// ICON
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 18),

                /// TITLE
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2559),
                    ),
                  ),
                ),

                /// ARROW
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFF1B2559),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE84D63)
                .withValues(alpha:0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _logout,

        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.white,
        ),

        label: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFE84D63),

          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}