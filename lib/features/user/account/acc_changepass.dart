import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:ramhis_app/core/session_manager.dart';

class AccChangepassWidget extends StatefulWidget {
  const AccChangepassWidget({super.key});

  @override
  State<AccChangepassWidget> createState() => _AccChangepassWidgetState();
}

class _AccChangepassWidgetState extends State<AccChangepassWidget> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isSaving = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
  final currentPassword = currentPasswordController.text.trim();
  final newPassword = newPasswordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();

  if (currentPassword.isEmpty ||
      newPassword.isEmpty ||
      confirmPassword.isEmpty) {
    _showSnackBar('Please complete all password fields.');
    return;
  }

  if (newPassword.length < 8) {
    _showSnackBar('New password must be at least 8 characters.');
    return;
  }

  if (newPassword != confirmPassword) {
    _showSnackBar('New password and confirm password do not match.');
    return;
  }

  setState(() => isSaving = true);

  try {
    final response = await AuthApi.put(
      '/me/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    if (!mounted) return;

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      _showSnackBar(data['message'] ?? 'Password changed successfully.');
      Navigator.pop(context);
    } else {
      _showSnackBar(data['message'] ?? 'Failed to change password.');
    }
  } catch (e) {
    if (!mounted) return;
    _showSnackBar('Connection error. Please try again.');
  } finally {
    if (mounted) {
      setState(() => isSaving = false);
    }
  }
}

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF3F5FBE)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF1B2559),
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Material(
                  color: Colors.transparent,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEDFB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Update your password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F5FBE),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text('Current password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          decoration: _inputDecoration(
                            hintText: 'Enter current password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: obscureCurrent,
                            onToggle: () {
                              setState(() =>
                                  obscureCurrent = !obscureCurrent);
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text('New password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          decoration: _inputDecoration(
                            hintText: 'Enter new password',
                            icon: Icons.password_rounded,
                            obscureText: obscureNew,
                            onToggle: () {
                              setState(() =>
                                  obscureNew = !obscureNew);
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text('Confirm password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: _inputDecoration(
                            hintText: 'Confirm new password',
                            icon: Icons.verified_user_outlined,
                            obscureText: obscureConfirm,
                            onToggle: () {
                              setState(() =>
                                  obscureConfirm = !obscureConfirm);
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: isSaving ? null : _submit,
                          child: Text(
                              isSaving ? 'Saving...' : 'Save Password'),
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back'),
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
}