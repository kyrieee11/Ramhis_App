import 'package:flutter/material.dart';
import 'package:ramhis_app/services/api/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email =
        _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(
        'Please enter your email.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response =
          await AuthService.forgotPassword(
        email: email,
      );

      if (!mounted) return;

      final token =
          response['resetToken']?.toString() ??
              '';

      _showSnackBar(
        response['message'] ??
            'Reset instructions sent.',
      );

      if (token.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: token,
        );
      }
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
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller:
                    _emailController,
                keyboardType:
                    TextInputType
                        .emailAddress,
                decoration:
                    const InputDecoration(
                  labelText: 'Email',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : _handleForgotPassword,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color:
                              Colors.white,
                        )
                      : const Text(
                          'Send Reset Link',
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