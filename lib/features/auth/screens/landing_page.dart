import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/features/user/screens/home_screen.dart';
import 'package:ramhis_app/features/auth/screens/welcome_screen.dart';
import 'package:ramhis_app/features/auth/screens/forgot_password_screen.dart';
import 'package:ramhis_app/services/api/auth_service.dart';

// RAMHIS Medical Blue Theme
const _kPrimary = Color(0xFF10539B);
const _kPrimarySoft = Color(0xFFEBF3FA);
const _kPrimaryLight = Color(0xFFE3F2FD);
const _kBackground = Color(0xFFF8FAFC);
const _kTextPrimary = Color(0xFF102A43);
const _kTextSecondary = Color(0xFF526579);
const _kTextMuted = Color(0xFF8292A6);
const _kBorder = Color(0xFFCDE1EC);
const _kWarning = Color(0xFFFFB800);
const _kDanger = Color(0xFFD95C5C);
const _kSoftRose = Color(0xFFFFEFEF);

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
          iconColor: _kTextMuted,
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
          iconColor: _kWarning,
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
          iconColor: _kDanger,
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
          iconColor: _kDanger,
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
          iconColor: _kPrimary,
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
          iconColor: _kPrimary,
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
          iconColor: _kWarning,
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
          iconColor: _kDanger,
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
                      backgroundColor: _kPrimary,
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBackground,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Stack(
            children: [
              // Soft flowing background inspired by the reference.
              Positioned.fill(
                child: CustomPaint(
                  painter: _LoginBackgroundPainter(),
                ),
              ),

              // Main login content.
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 36,
                    vertical: isMobile ? 18 : 28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 430,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: isMobile ? 20 : 30,
                          ),

                          // ─────────────────────────
                          // LOGO
                          // ─────────────────────────
                          _buildLogo(),

                          SizedBox(
                            height: isMobile ? 10 : 0,
                          ),

                          // ─────────────────────────
                          // WELCOME TEXT
                          // ─────────────────────────
                          Text(
                            'Welcome Back!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: isMobile ? 29 : 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Log in to your account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF60758A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(
                            height: isMobile ? 28 : 34,
                          ),

                          // ─────────────────────────
                          // EMAIL
                          // ─────────────────────────
                          _buildLoginInput(
                            controller: emailController,
                            hintText: 'Email Address',
                            prefixIcon: Icons.email_rounded,
                            keyboardType:
                                TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 14),

                          // ─────────────────────────
                          // PASSWORD
                          // ─────────────────────────
                          _buildLoginInput(
                            controller: passwordController,
                            hintText: 'Password',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword =
                                      !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: _kTextSecondary,
                                size: 21,
                              ),
                            ),
                          ),

                          // ─────────────────────────
                          // FORGOT PASSWORD
                          // ─────────────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  left: 8,
                                  bottom: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF2066A8),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: isMobile ? 13 : 18,
                          ),

                          // ─────────────────────────
                          // LOGIN BUTTON
                          // ─────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _kPrimary,
                                disabledBackgroundColor:
                                    _kBorder,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor: _kPrimary.withValues(alpha: 0.22),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(28),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 180),
                                child: isLoading
                                    ? Row(
                                        key: const ValueKey('loading'),
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 19,
                                            height: 19,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              loadingText,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        key: const ValueKey('login'),
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Log In',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight:
                                                  FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 21,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ─────────────────────────
                          // SIGN UP
                          // ─────────────────────────
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Color(0xFF303E50),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                const TextSpan(
                                  text: "Don't have an account? ",
                                ),
                                WidgetSpan(
                                  alignment:
                                      PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const WelcomeScreenWidget(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Color(0xFF2066A8),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: isMobile ? 30 : 38,
                          ),

                          // ─────────────────────────
                          // SOCIAL LOGIN VISUAL AREA
                          // ─────────────────────────
                          // No new functionality is added here.
                          // Existing authentication behavior remains
                          // exactly as implemented above.
                         

                          // ─────────────────────────
                          // BOTTOM BRANDING
                          // ─────────────────────────
                          const Text(
                            'REMOTE AREA MEDICAL HEALTH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF60758A),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'INFORMATION SYSTEM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF2066A8),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),

                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 200,
      height: 250,
      child: Image.asset(
        'assets/images/ramhis_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.health_and_safety_rounded,
            color: Color(0xFF2066A8),
            size: 62,
          );
        },
      ),
    );
  }

  Widget _buildLoginInput({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _kBorder,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimary
                .withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF24364A),
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: _kPrimary,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF7D91A3),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 10,
          ),
          prefixIcon: Container(
            width: 46,
            height: 46,
            margin: const EdgeInsets.only(
              left: 6,
              right: 6,
            ),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              prefixIcon,
              color: _kPrimary,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 58,
            minHeight: 46,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSocialVisual({
    required Widget child,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        shape: BoxShape.circle,
        border: Border.all(
          color: _kPrimaryLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimary
                .withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: child,
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base gray-white surface.
    final backgroundPaint = Paint()
      ..color = _kBackground;

    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );

    // Top-left soft blue wave.
    final topBlue = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.55, 0)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.08,
        size.width * 0.58,
        size.height * 0.18,
        size.width * 0.45,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.31,
        size.width * 0.12,
        size.height * 0.25,
        0,
        size.height * 0.34,
      )
      ..close();

    canvas.drawPath(
      topBlue,
      Paint()
        ..color = _kPrimaryLight
        ..style = PaintingStyle.fill,
    );

    // Upper-right soft blue shape.
    final rightBlue = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.72, 0)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.10,
        size.width * 0.77,
        size.height * 0.18,
        size.width,
        size.height * 0.22,
      )
      ..close();

    canvas.drawPath(
      rightBlue,
      Paint()
        ..color = _kBorder
            .withValues(alpha: 0.22),
    );

    // Soft red accent on the right.
    final peachCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            size.width + 20,
            size.height * 0.35,
          ),
          radius: 90,
        ),
      );

    canvas.drawPath(
      peachCircle,
      Paint()
        ..color = _kSoftRose.withValues(alpha: 0.55),
    );

    // Bottom blue wave.
    final bottomBlue = Path()
      ..moveTo(0, size.height * 0.86)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.79,
        size.width * 0.36,
        size.height * 0.96,
        size.width * 0.56,
        size.height * 0.91,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.86,
        size.width * 0.86,
        size.height * 0.77,
        size.width,
        size.height * 0.81,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      bottomBlue,
      Paint()
        ..color = _kBorder
            .withValues(alpha: 0.30),
    );

    // Bottom red wave.
    final bottomRed = Path()
      ..moveTo(0, size.height * 0.94)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.86,
        size.width * 0.36,
        size.height * 0.96,
        size.width * 0.58,
        size.height * 0.93,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.90,
        size.width * 0.88,
        size.height * 0.83,
        size.width,
        size.height * 0.86,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      bottomRed,
      Paint()
        ..color = _kSoftRose.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(
    covariant _LoginBackgroundPainter oldDelegate,
  ) {
    return false;
  }
}