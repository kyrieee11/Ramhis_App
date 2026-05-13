import 'package:flutter/material.dart';

import 'package:ramhis_app/services/api/user_service.dart';

class AccountChangePasswordScreen extends StatefulWidget {
  const AccountChangePasswordScreen({super.key});

  @override
  State<AccountChangePasswordScreen> createState() =>
      _AccountChangePasswordScreenState();
}

class _AccountChangePasswordScreenState
    extends State<AccountChangePasswordScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isSaving = false;

  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('Please complete all fields.');
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
      await UserService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      _showSnackBar('Password changed successfully.');
    } catch (error) {
      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
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
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF4169D8),
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD95362),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: !isSaving,
      decoration: _inputDecoration(
        hintText: hintText,
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: obscureText,
        toggle: toggle,
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
          title: const Text('Change Password'),
          backgroundColor: const Color(0xFF4169D8),
          foregroundColor: Colors.white,
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
                        size: 70,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Update Your Password',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your current password and choose a new secure password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5ECFF),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildPasswordField(
                        controller: currentPasswordController,
                        hintText: 'Current Password',
                        obscureText: obscureCurrentPassword,
                        toggle: () {
                          setState(() {
                            obscureCurrentPassword =
                                !obscureCurrentPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(
                        controller: newPasswordController,
                        hintText: 'New Password',
                        obscureText: obscureNewPassword,
                        toggle: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        hintText: 'Confirm New Password',
                        obscureText: obscureConfirmPassword,
                        toggle: () {
                          setState(() {
                            obscureConfirmPassword =
                                !obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : _changePassword,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isSaving
                                ? 'Updating...'
                                : 'Update Password',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD95362),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
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