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
      fillColor: const Color(0xFFF8F9FE),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF5B76F7),
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: const Color(0xFF7B8BB2),
        ),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA6C5),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE2E7F3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF5B76F7),
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE2E7F3),
          width: 1,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE2E7F3),
          width: 1,
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
      onChanged: (_) {
        if (mounted) {
          setState(() {});
        }
      },
      style: const TextStyle(
        color: Color(0xFF1B2559),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        hintText: hintText,
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: obscureText,
        toggle: toggle,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7B8BB2),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _labeledPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback toggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        _buildPasswordField(
          controller: controller,
          hintText: hintText,
          obscureText: obscureText,
          toggle: toggle,
        ),
      ],
    );
  }

  int _passwordStrengthLevel(String value) {
    final length = value.trim().length;

    if (length <= 4) return 1;
    if (length <= 7) return 2;
    if (length <= 11) return 3;
    return 4;
  }

  String _passwordStrengthLabel(String value) {
    final level = _passwordStrengthLevel(value);

    if (level == 1) return 'Weak';
    if (level == 2) return 'Fair';
    if (level == 3) return 'Good';
    return 'Strong';
  }

  Color _passwordStrengthColor(String value) {
    final level = _passwordStrengthLevel(value);

    if (level == 1) return const Color(0xFFEF4444);
    if (level == 2) return const Color(0xFFF59E0B);
    if (level == 3) return const Color(0xFF5B76F7);
    return const Color(0xFF22C55E);
  }

  Widget _passwordStrengthIndicator() {
    final value = newPasswordController.text;
    final level = _passwordStrengthLevel(value);
    final color = _passwordStrengthColor(value);
    final label = _passwordStrengthLabel(value);

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: List.generate(4, (index) {
            final active = index < level;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 5,
                margin: EdgeInsets.only(
                  right: index == 3 ? 0 : 6,
                ),
                decoration: BoxDecoration(
                  color: active ? color : const Color(0xFFE2E7F3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              'Password strength',
              style: TextStyle(
                color: const Color(0xFF7B8BB2).withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5B76F7),
                  Color(0xFF4564E8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4564E8).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Update Your Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2559),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your current password and choose a new secure password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8BB2),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _labeledPasswordField(
            label: 'Current Password',
            controller: currentPasswordController,
            hintText: 'Enter current password',
            obscureText: obscureCurrentPassword,
            toggle: () {
              setState(() {
                obscureCurrentPassword = !obscureCurrentPassword;
              });
            },
          ),
          const SizedBox(height: 18),
          _labeledPasswordField(
            label: 'New Password',
            controller: newPasswordController,
            hintText: 'Enter new password',
            obscureText: obscureNewPassword,
            toggle: () {
              setState(() {
                obscureNewPassword = !obscureNewPassword;
              });
            },
          ),
          _passwordStrengthIndicator(),
          const SizedBox(height: 18),
          _labeledPasswordField(
            label: 'Confirm New Password',
            controller: confirmPasswordController,
            hintText: 'Confirm new password',
            obscureText: obscureConfirmPassword,
            toggle: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: isSaving
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF5B76F7),
                  Color(0xFF4564E8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isSaving ? const Color(0xFFB8C2EA) : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSaving
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF4564E8).withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isSaving ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Update Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  Widget _buildSecurityTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDE5FF),
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_rounded,
            color: Color(0xFF5B76F7),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use at least 8 characters with a mix of letters and numbers',
              style: TextStyle(
                color: Color(0xFF1B2559),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2FF),
        appBar: AppBar(
          title: const Text(
            'Change Password',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5B76F7),
                  Color(0xFF4564E8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFEAF0FF),
                Color(0xFFF0F2FF),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 18),
                      _buildPasswordCard(),
                      const SizedBox(height: 24),
                      _buildUpdateButton(),
                      const SizedBox(height: 16),
                      _buildSecurityTip(),
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