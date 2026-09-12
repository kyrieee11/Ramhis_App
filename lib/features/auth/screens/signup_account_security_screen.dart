import 'package:flutter/material.dart';

import 'package:ramhis_app/features/auth/screens/signup_personal_info_screen.dart';
import 'package:ramhis_app/features/auth/screens/signup_verification_screen.dart';

// RAMHIS Medical Blue Theme
const _kPrimary = Color(0xFF10539B);
const _kPrimaryDark = Color(0xFF0B4380);
const _kBlue = Color(0xFF1863B5);
const _kLightBlue = Color(0xFFE3F2FD);
const _kSoftBlue = Color(0xFFEBF3FA);
const _kPageBg = Color(0xFFF8FAFC);
const _kText = Color(0xFF102A43);
const _kTextSecondary = Color(0xFF526579);
const _kMuted = Color(0xFF8292A6);
const _kBorder = Color(0xFFCDE1EC);

class SignupAccountSecurityWidget extends StatefulWidget {
  const SignupAccountSecurityWidget({
    super.key,
    required this.accountType,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.birthdate,
    this.password = '',
    this.confirmPassword = '',
    this.department = '',
  });

  final String accountType;
  final String fullName;
  final String email;
  final String contactNumber;
  final String birthdate;
  final String password;
  final String confirmPassword;
  final String department;

  @override
  State<SignupAccountSecurityWidget> createState() =>
      _SignupAccountSecurityWidgetState();
}

class _SignupAccountSecurityWidgetState
    extends State<SignupAccountSecurityWidget> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _passwordVisible1 = false;
  bool _passwordVisible2 = false;
  bool _useSamePassword = false;

  String get _accountName {
    if (widget.accountType == 'doctor') return 'Doctor Account';
    if (widget.accountType == 'volunteer') return 'Volunteer Account';
    return 'User Account';
  }

  @override
  void initState() {
    super.initState();

    _passwordController =
        TextEditingController(text: widget.password);

    _confirmPasswordController =
        TextEditingController(text: widget.confirmPassword);

    _passwordController.addListener(() {
      if (_useSamePassword) {
        _confirmPasswordController.text =
            _passwordController.text;
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignupPersonalInformationWidget(
          accountType: widget.accountType,
          fullName: widget.fullName,
          email: widget.email,
          contactNumber: widget.contactNumber,
          birthdate: widget.birthdate,
          department: widget.department,
        ),
      ),
    );
  }

  void _goNext() {
    final password = _passwordController.text.trim();
    final confirmPassword =
        _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete both password fields.',
          ),
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 8 characters long.',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one uppercase letter',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one lowercase letter',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one number',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'[!@#\$%^&*]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least one special character (!@#\$%^&*)',
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SignupProfessionalVerificationWidget(
          accountType: widget.accountType,
          fullName: widget.fullName,
          email: widget.email,
          contactNumber: widget.contactNumber,
          birthdate: widget.birthdate,
          password: password,
          confirmPassword: confirmPassword,
          department: widget.department,
          prcLicenseNumber: '',
          specialty: '',
          hospitalClinic: '',
          organization: '',
          skills: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SignupStepScaffold(
      accountName: _accountName,
      stepLabel: 'Account Security',
      currentStep: 2,
      totalSteps: 4,
      onBack: _goBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel('Password'),
          _buildPasswordField(
            controller: _passwordController,
            hintText: 'Enter your password',
            obscureText: !_passwordVisible1,
            onToggle: () {
              setState(() {
                _passwordVisible1 = !_passwordVisible1;
              });
            },
          ),
          const SizedBox(height: 7),
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              'Use at least 8 characters',
              style: TextStyle(
                color: _kMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: _kSoftBlue,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder, width: 1),
            ),
            child: CheckboxListTile(
              value: _useSamePassword,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              activeColor: _kPrimary,
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Use same password for confirmation',
                style: TextStyle(
                  color: _kText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _useSamePassword = value ?? false;
                  if (_useSamePassword) {
                    _confirmPasswordController.text =
                        _passwordController.text;
                  } else {
                    _confirmPasswordController.clear();
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('Confirm password'),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hintText: 'Confirm your password',
            enabled: !_useSamePassword,
            obscureText: !_passwordVisible2,
            onToggle: () {
              setState(() {
                _passwordVisible2 = !_passwordVisible2;
              });
            },
          ),
          const SizedBox(height: 22),
          _buildPasswordRequirements(),
          const SizedBox(height: 25),
          SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.chevron_right_rounded, size: 30),
              label: const Text(
                'Next',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: _kPrimary.withValues(alpha: 0.24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: _kText,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      style: const TextStyle(
        color: _kText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _kMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : _kLightBlue,
        prefixIcon: Container(
          margin: const EdgeInsets.all(3),
          width: 48,
          decoration: BoxDecoration(
            color: _kSoftBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: _kPrimary,
            size: 22,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _kTextSecondary,
            size: 22,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _kBorder, width: 1.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _kBorder, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: _kSoftBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: _kPrimary, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Use at least 8 characters with uppercase, lowercase, a number, and a special character.',
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _SignupStepScaffold extends StatelessWidget {
  const _SignupStepScaffold({
    required this.accountName,
    required this.stepLabel,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.child,
  });

  final String accountName;
  final String stepLabel;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _kPageBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kPrimary, _kPrimaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(progress),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _MarblePainter()),
                    ),
                    Positioned.fill(
                      child: Container(color: _kPageBg.withValues(alpha: 0.97)),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPrimary.withValues(alpha: 0.10),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.only(bottom: 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -45,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kLightBlue.withValues(alpha: 0.13),
                  width: 30,
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const Text(
                      'Create',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                accountName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _buildStepIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = [
      'Personal\nInformation',
      'Account\nSecurity',
      'Professional\nVerification',
      'Review',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final active = index == currentStep - 1;
              final completed = index < currentStep - 1;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? Colors.white : Colors.transparent,
                        border: Border.all(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.28),
                          width: active ? 4 : 3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: active
                              ? _kPrimary
                              : Colors.white.withValues(alpha: 0.55),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: completed
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: labels.asMap().entries.map((entry) {
              final active = entry.key == currentStep - 1;
              return Expanded(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.60),
                    fontSize: 13,
                    height: 1.18,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MarbleBackground extends StatelessWidget {
  const _MarbleBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MarblePainter(),
    );
  }
}

class _MarblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _kBlue.withValues(alpha: 0.08);

    final path1 = Path()
      ..moveTo(-30, 90)
      ..cubicTo(70, 15, 105, 160, 190, 82)
      ..cubicTo(260, 18, 310, 120, 410, 48);

    final path2 = Path()
      ..moveTo(-30, 310)
      ..cubicTo(70, 240, 135, 390, 225, 305)
      ..cubicTo(300, 235, 350, 350, 470, 270);

    final path3 = Path()
      ..moveTo(20, size.height - 90)
      ..cubicTo(
        120,
        size.height - 180,
        190,
        size.height - 20,
        290,
        size.height - 110,
      )
      ..cubicTo(
        360,
        size.height - 170,
        420,
        size.height - 45,
        size.width + 30,
        size.height - 115,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant _MarblePainter oldDelegate) => false;
}
