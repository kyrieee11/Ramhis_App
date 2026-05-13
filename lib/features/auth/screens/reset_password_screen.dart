import 'package:flutter/material.dart';

import 'package:ramhis_app/services/api/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.token,
  });

  // Token may come from:
  // 1. direct constructor param
  // 2. deep link parsing
  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? token;

  @override
  void initState() {
    super.initState();

    token = _resolveToken();
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Extract token ──────────────────────────────────────────────────────────
  String? _resolveToken() {
    // Priority 1: constructor token
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token;
    }

    // Priority 2: deep link
    //
    // Example:
    // myapp://reset-password?token=abc123
    //
    // Works on Flutter web/mobile deep links.
    final uri = Uri.base;

    if (uri.queryParameters.containsKey('token')) {
      return uri.queryParameters['token'];
    }

    return null;
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8;
  }

  Future<void> submit() async {
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (token == null || token!.isEmpty) {
      _show('Invalid or missing reset token.');
      return;
    }

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _show('Please complete all password fields.');
      return;
    }

    if (!_isStrongPassword(newPassword)) {
      _show('Password must be at least 8 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      _show('Passwords do not match.');
      return;
    }

    setState(() => loading = true);

    try {
      final data = await AuthService.resetPassword(
        token: token!,
        newPassword: newPassword,
      );

      if (!mounted) return;

      final message =
          (data['message'] ?? 'Password reset successful.').toString();

      _show(message);

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      _show(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _show(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback toggle,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF94A3B8),
        size: 18,
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: const Color(0xFF94A3B8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD95362),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: const Text('Reset Password'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4766C7),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Create New Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your new password below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5ECFF),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        enabled: !loading,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'New password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: obscurePassword,
                          toggle: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        enabled: !loading,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Confirm password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: obscureConfirmPassword,
                          toggle: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : submit,
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            loading ? 'Resetting...' : 'Reset Password',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD95362),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
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
    );
  }
}