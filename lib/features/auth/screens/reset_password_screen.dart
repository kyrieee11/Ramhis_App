import 'package:flutter/material.dart';
import 'package:ramhis_app/services/api/auth_service.dart';

class ResetPasswordScreen
    extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen>
      createState() =>
          _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final _passwordController =
      TextEditingController();

  final _confirmController =
      TextEditingController();

  bool _loading = false;

  bool _obscurePassword = true;

  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword()
      async {
    final password =
        _passwordController.text.trim();

    final confirm =
        _confirmController.text.trim();

    if (password.isEmpty ||
        confirm.isEmpty) {
      _showSnackBar(
        'Please complete all fields.',
      );
      return;
    }

    if (password.length < 6) {
      _showSnackBar(
        'Password must be at least 6 characters.',
      );
      return;
    }

    if (password != confirm) {
      _showSnackBar(
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response =
          await AuthService.resetPassword(
        token: widget.token,
        newPassword: password,
      );

      if (!mounted) return;

      _showSnackBar(
        response['message'] ??
            'Password reset successful.',
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),

              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller:
                    _passwordController,
                obscureText:
                    _obscurePassword,
                decoration:
                    InputDecoration(
                  labelText:
                      'New Password',
                  border:
                      const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller:
                    _confirmController,
                obscureText:
                    _obscureConfirm,
                decoration:
                    InputDecoration(
                  labelText:
                      'Confirm Password',
                  border:
                      const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm =
                            !_obscureConfirm;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : _handleResetPassword,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color:
                              Colors.white,
                        )
                      : const Text(
                          'Reset Password',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}