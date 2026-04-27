import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../auth/landingpage.dart';
import '../widgets/bottom_nav.dart';
import 'account/acc_username.dart';
import 'account/acc_changepass.dart';
import 'account/acc_privacy_policy.dart';
import 'account/acc_termsand_conditions.dart';
import 'account/acc_about.dart';

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
        fullName = user.fullName.isEmpty ? 'User' : user.fullName;
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
      MaterialPageRoute(builder: (_) => const LandingpageWidget()),
      (route) => false,
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _resolveProfileImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return 'http://10.0.2.2:5000$imageUrl';
  }

  Widget _buildAvatar() {
    final imageUrl = currentUser?.profileImageUrl ?? '';

    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(_resolveProfileImageUrl(imageUrl)),
      );
    }

    return const CircleAvatar(
      radius: 36,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person,
        size: 36,
        color: Color(0xFF3F5FBE),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildMenuSection(),
                          const SizedBox(height: 16),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
            ),

            /// ✅ REPLACED NAVBAR HERE
            const CustomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: const Row(
        children: [
          Icon(Icons.person_rounded, color: Color(0xFF3F5FBE)),
          SizedBox(width: 10),
          Text(
            'Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2559),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F5FBE), Color(0xFF5C7AE6)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(color: Color(0xFFE5ECFF)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            accountType,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _menuTile(
          'User Information',
          Icons.person_outline,
          _openUserInformation,
        ),
        _menuTile(
          'Change Password',
          Icons.lock_outline,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccChangepassWidget()),
          ),
        ),
        _menuTile(
          'Privacy Policy',
          Icons.privacy_tip_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccPrivacyPolicyWidget()),
          ),
        ),
        _menuTile(
          'Terms & Conditions',
          Icons.description_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccTermsandConditionsWidget(),
            ),
          ),
        ),
        _menuTile(
          'About',
          Icons.info_outline,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccAboutWidget()),
          ),
        ),
      ],
    );
  }

  Widget _menuTile(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEDFB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF3F5FBE)),
                const SizedBox(width: 12),
                Expanded(child: Text(title)),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD14C59),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Text('Log Out'),
    );
  }
}