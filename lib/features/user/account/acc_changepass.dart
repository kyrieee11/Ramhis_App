import 'package:flutter/material.dart';

import 'package:ramhis_app/services/api/user_service.dart';

const _kNavy = Color(0xFF123F91);
const _kNavyDark = Color(0xFF082B6B);
const _kGold = Color(0xFFD9C27A);
const _kGoldDark = Color(0xFF9D7D2F);
const _kCream = Color(0xFFF7F2E5);
const _kInk = Color(0xFF24304A);
const _kMuted = Color(0xFF77746D);

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
      fillColor: _kCream.withValues(alpha: 0.94),
      prefixIcon: Container(
        margin: const EdgeInsets.all(6),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kNavy, _kNavyDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGold, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(prefixIcon, color: _kCream, size: 24),
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _kGoldDark,
        ),
      ),
      hintStyle: const TextStyle(
        color: _kMuted,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _kGoldDark, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _kNavy, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _kGoldDark, width: 1.3),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _kGoldDark, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
        if (mounted) setState(() {});
      },
      style: const TextStyle(
        color: _kInk,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        hintText: hintText,
        prefixIcon: Icons.lock_rounded,
        obscureText: obscureText,
        toggle: toggle,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: _kInk,
          fontSize: 15,
          fontWeight: FontWeight.w500,
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
    if (level == 1) return const Color(0xFFB84242);
    if (level == 2) return const Color(0xFFC49A38);
    if (level == 3) return _kNavy;
    return const Color(0xFF3E8C59);
  }

  Widget _passwordStrengthIndicator() {
    final value = newPasswordController.text;
    final level = _passwordStrengthLevel(value);
    final color = _passwordStrengthColor(value);
    final label = _passwordStrengthLabel(value);

    return Column(
      children: [
        const SizedBox(height: 9),
        Row(
          children: List.generate(4, (index) {
            final active = index < level;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 5,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  color: active ? color : const Color(0xFFD8CBA8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text(
              'Password strength',
              style: TextStyle(
                color: _kInk,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 17),
      decoration: BoxDecoration(
        color: _kCream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _kGold, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_kGold, _kGoldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _kNavy, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 13,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _kGoldDark, width: 1),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: _kNavy,
                size: 54,
              ),
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'Update Your Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w500,
              color: _kInk,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Enter your current password and choose a\nnew secure password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kInk,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: _kCream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _kGoldDark, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.11),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
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
                colors: [_kNavy, _kNavyDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isSaving ? const Color(0xFF8E99B2) : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGoldDark, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSaving ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: _kCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _kCream,
                ),
              )
            : const Text(
                'Update Password',
                style: TextStyle(
                  color: _kCream,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildSecurityTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kCream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _kGoldDark, width: 1.2),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_rounded,
            color: _kNavy,
            size: 24,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Use at least 8 characters with a mix of letters\nand numbers.',
              style: TextStyle(
                color: _kInk,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
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
        backgroundColor: _kCream,
        appBar: AppBar(
          title: const Text(
            'Change Password',
            style: TextStyle(
              color: _kCream,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: _kGold,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _kGold,
              size: 21,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kNavy, _kNavyDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: _kGold, width: 1.3),
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kCream, Color(0xFFF4EDDA), _kCream],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MarbleBackgroundPainter(),
                ),
              ),
              SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 14),
                      _buildPasswordCard(),
                      const SizedBox(height: 15),
                      _buildUpdateButton(),
                      const SizedBox(height: 14),
                      _buildSecurityTip(),
                    ],
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

class _MarbleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = _kCream;
    canvas.drawRect(Offset.zero & size, base);

    final vein = Paint()
      ..color = const Color(0xFF9EA9B8).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final soft = Paint()
      ..color = const Color(0xFFBDC5D0).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    final paths = <Path>[
      Path()
        ..moveTo(size.width * .03, size.height * .02)
        ..cubicTo(
          size.width * .28, size.height * .14,
          size.width * .08, size.height * .27,
          size.width * .39, size.height * .36,
        )
        ..cubicTo(
          size.width * .62, size.height * .44,
          size.width * .36, size.height * .59,
          size.width * .67, size.height * .70,
        )
        ..cubicTo(
          size.width * .83, size.height * .77,
          size.width * .61, size.height * .91,
          size.width * .94, size.height,
        ),
      Path()
        ..moveTo(size.width * .96, size.height * .02)
        ..cubicTo(
          size.width * .72, size.height * .16,
          size.width * .89, size.height * .29,
          size.width * .65, size.height * .41,
        )
        ..cubicTo(
          size.width * .48, size.height * .50,
          size.width * .73, size.height * .62,
          size.width * .44, size.height * .81,
        ),
    ];

    for (final path in paths) {
      canvas.drawPath(path, vein);
    }

    canvas.drawPath(
      Path()
        ..moveTo(size.width * .02, size.height * .20)
        ..cubicTo(
          size.width * .27, size.height * .25,
          size.width * .12, size.height * .35,
          size.width * .45, size.height * .40,
        )
        ..cubicTo(
          size.width * .66, size.height * .47,
          size.width * .42, size.height * .58,
          size.width * .74, size.height * .67,
        ),
      soft,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
