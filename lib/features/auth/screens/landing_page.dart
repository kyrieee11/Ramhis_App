import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final bool loginSuccess =
          result['ok'] == true ||
          result['success'] == true ||
          result['accessToken'] != null ||
          result['access_token'] != null ||
          result['token'] != null ||
          result['user'] != null;

      if (!loginSuccess) {
        setState(() => isLoading = false);
        _showSnackBar((result['message'] ?? 'Login failed.').toString());
        return;
      }

      try {
        await AuthService.fetchMe();
      } catch (e) {
        debugPrint('fetchMe error: $e');
      }

      final Map<String, dynamic>? user =
          AuthSession.currentUser ??
          (result['user'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(result['user'])
              : null);

      if (user == null) {
        setState(() => isLoading = false);
        _showSnackBar('Failed to load user session.');
        return;
      }

      final String role =
          (user['role'] ?? user['account_type'] ?? '')
              .toString()
              .toLowerCase();

      final String status =
          (user['status'] ?? 'active')
              .toString()
              .toLowerCase();

      setState(() => isLoading = false);

      if (status == 'pending') {
        _showSnackBar('Your account is pending admin approval.');
        return;
      }

      if (status == 'suspended') {
        _showSnackBar('Your account is suspended. Please contact support.');
        return;
      }

      if (role == 'admin') {
        await AuthSession.clearSession();
        _showSnackBar('Admin accounts must use the web dashboard.');
        return;
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      debugPrint('Login error: $e');

      _showSnackBar('Connection error. Please try again.');
    }
  }

  Future<void> _handleDebugLogin() async {
    try {
      await AuthSession.saveSession(
        access: 'debug-token',
        refresh: 'debug-refresh-token',
        user: {
          'id': 'debug-id-123',
          'name': 'Debug User',
          'email': 'debug@ramhis.com',
          'role': 'user',
        },
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Debug login error: $e');
      _showSnackBar('Failed to start debug session.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 26 : 32,
                      vertical: isMobile ? 34 : 40,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4167D4)
                          .withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 32,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildLogo(),

                        const SizedBox(height: 26),

                        const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 26),

                        _buildLabel('Email'),

                        const SizedBox(height: 8),

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

                        const SizedBox(height: 18),

                        _buildLabel('Password'),

                        const SizedBox(height: 8),

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

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
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
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : _handleLogin,
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
                              isLoading
                                  ? 'Loading...'
                                  : 'Log in',
                              style: const TextStyle(
                                fontSize: 20,
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

                        if (kDebugMode) ...[
                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: _handleDebugLogin,
                              icon: const Icon(
                                Icons.bug_report_outlined,
                                size: 22,
                              ),
                              label: const Text(
                                '[ DEBUG ] Skip Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orangeAccent,
                                side: const BorderSide(
                                  color: Colors.orangeAccent,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 26),

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

                        const SizedBox(height: 22),

                        const Text(
                          'Don’t have an account?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: 210,
                          height: 48,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 200,
      height: 150,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
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