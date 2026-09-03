import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/features/user/screens/home_screen.dart';
import 'package:ramhis_app/features/auth/screens/welcome_screen.dart';
import 'package:ramhis_app/features/auth/screens/forgot_password_screen.dart';
import 'package:ramhis_app/services/api/auth_service.dart';

class LandingpageWidget extends StatefulWidget {
  const LandingpageWidget({super.key});

  @override
  State<LandingpageWidget> createState() => _LandingpageWidgetState();
}

class _LandingpageWidgetState extends State<LandingpageWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  String loadingText = 'Log in';

  Timer? _loadingTimer10;
  Timer? _loadingTimer30;

  static const String _rememberEmailKey = 'remembered_email';
  
 
 

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _loadingTimer10?.cancel();
    _loadingTimer30?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedCredentials() async {
  final prefs = await SharedPreferences.getInstance();

  final savedEmail =
      prefs.getString(_rememberEmailKey) ?? '';

  if (!mounted) return;

  setState(() {
    emailController.text = savedEmail;
  });
}

  Future<void> _saveRememberedCredentials({
  required String email,
}) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    _rememberEmailKey,
    email,
  );
}

  

  void _startLoadingTimers() {
    _loadingTimer10?.cancel();
    _loadingTimer30?.cancel();

    loadingText = 'Logging in...';

    _loadingTimer10 = Timer(const Duration(seconds: 10), () {
      if (!mounted || !isLoading) return;
      setState(() {
        loadingText = 'Connecting to server...';
      });
    });

    _loadingTimer30 = Timer(const Duration(seconds: 30), () {
      if (!mounted || !isLoading) return;
      setState(() {
        loadingText = 'Server is starting up, please wait...';
      });
    });
  }

  void _stopLoading() {
    _loadingTimer10?.cancel();
    _loadingTimer30?.cancel();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      loadingText = 'Log in';
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      _showSnackBar('Please enter your password.');
      return;
    }

    if (password.length < 8) {
      _showSnackBar('Password must be at least 8 characters.');
      return;
    }

    setState(() {
      isLoading = true;
      loadingText = 'Logging in...';
    });

    _startLoadingTimers();

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 60));

      if (!mounted) return;

      final bool loginSuccess =
          result['ok'] == true ||
          result['success'] == true ||
          result['token'] != null ||
          result['accessToken'] != null ||
          result['access_token'] != null;

      final String message =
          (result['msg'] ?? result['message'] ?? result['error'] ?? '')
              .toString()
              .toLowerCase();

      final Map<String, dynamic>? user =
          result['user'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(result['user'])
              : AuthSession.currentUser;

      final String role =
          (user?['role'] ?? user?['account_type'] ?? '').toString().toLowerCase();

      final String status = (user?['status'] ?? '').toString().toLowerCase();

      final String verificationStatus =
          (user?['verificationStatus'] ?? '').toString().toLowerCase();

      final bool mustChangePassword = user?['mustChangePassword'] == true;

      if (!loginSuccess &&
          (message.contains('invalid') ||
              message.contains('credentials') ||
              message.contains('wrong') ||
              message.contains('incorrect') ||
              message.contains('not found'))) {
        _stopLoading();
        passwordController.clear();

        _showSnackBar(
          'Incorrect email or password. Please try again.',
        );
        return;
      }

      if (!loginSuccess &&
          (message.contains('no account') ||
              message.contains('not registered') ||
              message.contains('does not exist'))) {
        _stopLoading();

        _showAuthDialog(
          title: 'Account Not Found',
          icon: Icons.person_off,
          iconColor: Colors.grey,
          message:
              'No mobile account found with this email.\n\nPlease sign up first to create a mobile account.',
          buttonText: 'Try Again',
          secondButtonText: 'Sign Up',
          onSecondPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WelcomeScreenWidget(),
              ),
            );
          },
        );
        return;
      }

      if ((!loginSuccess &&
              (message.contains('pending') || message.contains('approval'))) ||
          verificationStatus == 'pending' ||
          status == 'pending') {
        _stopLoading();

        _showAuthDialog(
          title: 'Awaiting Approval',
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.orange,
          message:
              'Your account has been submitted and is waiting for admin approval.\n\nYou will be able to log in once an admin approves your account.\n\nPlease check back later.',
        );
        return;
      }

      if (verificationStatus == 'rejected' || status == 'rejected') {
        _stopLoading();

        _showAuthDialog(
          title: 'Account Not Approved',
          icon: Icons.cancel_rounded,
          iconColor: Colors.red,
          message:
              'Your registration was not approved by the admin.\n\nPlease contact the RAMHIS administrator for more information or sign up again with correct information.',
        );
        return;
      }

      if (verificationStatus == 'deactivated' ||
          status == 'deactivated' ||
          status == 'suspended' ||
          message.contains('deactivated') ||
          message.contains('suspended')) {
        _stopLoading();

        _showAuthDialog(
          title: 'Account Deactivated',
          icon: Icons.block_rounded,
          iconColor: Colors.red,
          message:
              'Your account has been deactivated by the administrator.\n\nPlease contact the RAMHIS admin to restore your account.',
        );
        return;
      }

      if (loginSuccess && (role == 'admin' || role == 'pharmacist')) {
        await AuthSession.clearSession();

        _stopLoading();

        _showAuthDialog(
          title: 'Wrong Platform',
          icon: Icons.computer,
          iconColor: Colors.blue,
          message:
              'This account type is not supported on the mobile app.\n\nPlease use the RAMHIS web dashboard to access your account:\n\nramhis-v2-1.onrender.com',
        );
        return;
      }

      final bool allowedMobileRole = role == 'doctor' || role == 'volunteer';

      if (!loginSuccess || user == null) {
        _stopLoading();

        _showSnackBar(
          message.isNotEmpty ? message : 'Login failed. Please try again.',
        );
        return;
      }

      if (!allowedMobileRole) {
        await AuthSession.clearSession();

        _stopLoading();

        _showAuthDialog(
          title: 'Wrong Platform',
          icon: Icons.computer,
          iconColor: Colors.blue,
          message:
              'This account type is not supported on the mobile app.\n\nPlease use the RAMHIS web dashboard to access your account.',
        );
        return;
      }

      if (mustChangePassword) {
        _stopLoading();

        _showSnackBar(
          'Please set a new password to continue.',
        );

        return;
      }

      await _saveRememberedCredentials(
  email: email,
);

      try {
        await AuthService.fetchMe();
      } catch (e) {
        debugPrint('fetchMe error: $e');
      }

      _stopLoading();

      final String name = (user['name'] ?? user['full_name'] ?? 'User').toString();

      _showSnackBar('Welcome back, $name! 👋');

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } on TimeoutException {
      _stopLoading();

      _showSnackBar(
        'Connection timed out. Server may be starting up. Please try again.',
      );
    } on SocketException {
      _stopLoading();

      _showSnackBar(
        'No internet connection. Please check your network and try again.',
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Login error: $e');

      final String errorMessage =
          e.toString().replaceFirst('Exception: ', '').toLowerCase();

      _stopLoading();

      if (errorMessage.contains('invalid') ||
          errorMessage.contains('credentials') ||
          errorMessage.contains('wrong') ||
          errorMessage.contains('incorrect') ||
          errorMessage.contains('not found')) {
        passwordController.clear();

        _showSnackBar(
          'Incorrect email or password. Please try again.',
        );
        return;
      }

      if (errorMessage.contains('pending') ||
          errorMessage.contains('approval') ||
          errorMessage.contains('awaiting')) {
        _showAuthDialog(
          title: 'Awaiting Approval',
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.orange,
          message:
              'Your account has been submitted and is waiting for admin approval.\n\nYou will be able to log in once an admin approves your account.\n\nPlease check back later.',
        );
        return;
      }

      if (errorMessage.contains('deactivated') ||
          errorMessage.contains('suspended')) {
        _showAuthDialog(
          title: 'Account Deactivated',
          icon: Icons.block_rounded,
          iconColor: Colors.red,
          message:
              'Your account has been deactivated by the administrator.\n\nPlease contact the RAMHIS admin to restore your account.',
        );
        return;
      }

      _showSnackBar(
        'Unable to reach server. Please try again in a moment.',
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAuthDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    String? secondButtonText,
    VoidCallback? onSecondPressed,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2559),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF7B8BB2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (secondButtonText != null) ...[
                    TextButton(
                      onPressed:
                          onSecondPressed ?? () => Navigator.pop(context),
                      child: Text(
                        secondButtonText,
                        style: const TextStyle(
                          color: Color(0xFF3949AB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3949AB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onPressed ?? () => Navigator.pop(context),
                    child: Text(buttonText),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4169D8),
                Color(0xFF234AB3),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: isMobile ? 20 : 28,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.center,
                          child: _buildLogo(),
                        ),
                      ),
                      Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: isMobile ? 30 : 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: isMobile ? 18 : 24),
                      _buildLabel('Email'),
                      SizedBox(height: isMobile ? 6 : 8),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF334155),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 18),
                      _buildLabel('Password'),
                      SizedBox(height: isMobile ? 6 : 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF334155),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF7D8EAD),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 14 : 22),
                      SizedBox(
                        width: double.infinity,
                        height: isMobile ? 52 : 58,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _handleLogin,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.login_rounded,
                                  size: 24,
                                ),
                          label: Text(
                            isLoading ? loadingText : 'Log in',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF05261),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 26),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.35),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: 0.65,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.35),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 14 : 22),
                      const Text(
                        'Don’t have an account?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: isMobile ? 10 : 14),
                      SizedBox(
                        width: 210,
                        height: isMobile ? 44 : 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const WelcomeScreenWidget(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 250,
      height: 250,
      child: Image.asset(
        'assets/images/ramhis_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.white,
              size: 42,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF7D8EAD),
        size: 24,
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(
          color: Color(0xFFF05261),
          width: 1.8,
        ),
      ),
    );
  }
}