import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:ramhis_app/features/auth/screens/reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool loading = false;

  static const String baseUrl = 'http://10.0.2.2:5000';

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _tryDecodeMap(String body) {
    try {
      if (body.trim().isEmpty) return null;

      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return null;
    }
  }

  Future<void> submit() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      _show('Please enter your email.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _show('Please enter a valid email address.');
      return;
    }

    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Forgot Password STATUS: ${response.statusCode}');
      debugPrint('Forgot Password BODY: ${response.body}');

      final Map<String, dynamic>? data = _tryDecodeMap(response.body);

      if (!mounted) return;

      final String message = (data?['message'] ?? 'Request completed.')
          .toString();

      _show(message);

      if (response.statusCode == 200) {
        final String resetLink = (data?['resetLink'] ?? '').toString();

        if (resetLink.isNotEmpty) {
          final Uri? uri = Uri.tryParse(resetLink);
          final String? token = uri?.queryParameters['token'];

          if (token != null && token.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 500));

            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(token: token),
              ),
            );
          }
        }
      }
    } on http.ClientException catch (e) {
      if (!mounted) return;
      debugPrint('Client error: $e');
      _show('Unable to connect to server.');
    } on FormatException catch (e) {
      if (!mounted) return;
      debugPrint('Format error: $e');
      _show('Invalid server response.');
    } catch (e) {
      if (!mounted) return;
      debugPrint('Forgot password error: $e');
      _show('Connection error. Please try again.');
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
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
          title: const Text('Forgot Password'),
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
                      const Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your email address and we will send your password reset link.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5ECFF),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : submit,
                          icon: loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            loading ? 'Sending...' : 'Send Reset Link',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD95362),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
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