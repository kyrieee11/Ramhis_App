import 'package:flutter/material.dart';

import 'package:ramhis_app/features/auth/screens/signup_personal_info_screen.dart';
import 'package:ramhis_app/features/auth/screens/signup_verification_screen.dart';

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
            hintText: 'Password',
            obscureText: !_passwordVisible1,
            onToggle: () {
              setState(() {
                _passwordVisible1 = !_passwordVisible1;
              });
            },
          ),
          const SizedBox(height: 5),
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Text(
              'Use at least 8 characters',
              style: TextStyle(
                color: Color(0xFF8A7C60),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFA88B4E),
                width: 1.3,
              ),
            ),
            child: CheckboxListTile(
              value: _useSamePassword,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              activeColor: const Color(0xFF17479C),
              checkColor: const Color(0xFFF7F1E2),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Use same password for confirmation',
                style: TextStyle(
                  color: Color(0xFF5A4A2B),
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
          const SizedBox(height: 14),
          _buildLabel('Confirm password'),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hintText: 'Confirm password',
            enabled: !_useSamePassword,
            obscureText: !_passwordVisible2,
            onToggle: () {
              setState(() {
                _passwordVisible2 = !_passwordVisible2;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordRequirements(),
          const SizedBox(height: 17),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(
                Icons.chevron_right_rounded,
                size: 27,
              ),
              label: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB9232B),
                foregroundColor: const Color(0xFFF8F1DB),
                elevation: 8,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(
                    color: Color(0xFFD9C27A),
                    width: 1.4,
                  ),
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
      padding: const EdgeInsets.only(left: 6, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF182A52),
          fontSize: 14,
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
        color: Color(0xFF3D382E),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8B806A),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: enabled
            ? const Color(0xFFF7F1E2)
            : const Color(0xFFE9E1CF),
        prefixIcon: Container(
          margin: const EdgeInsets.all(3),
          width: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF17479C),
                Color(0xFF0A2B6B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFFE9D9A5),
            size: 22,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF8D7B50),
            size: 23,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFA88B4E),
            width: 1.7,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF17479C),
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFA88B4E),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD0B66F),
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: Color(0xFF17479C),
            size: 24,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Use at least 8 characters with uppercase, lowercase, a number, and a special character.',
              style: TextStyle(
                color: Color(0xFF5C5140),
                fontSize: 11.5,
                height: 1.35,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF123F91),
              Color(0xFF082B6B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(progress),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F1E2),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: _MarbleBackground(),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Color(0xFFF7F1E2),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          18,
                          24,
                          28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 430),
                            child: child,
                          ),
                        ),
                      ),
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

  Widget _buildHeader(double progress) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF17479C),
            Color(0xFF0B2E73),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD9C27A),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                      color: Color(0xFFE7D59D),
                      size: 28,
                    ),
                  ),
                ),
                const Text(
                  'Create',
                  style: TextStyle(
                    color: Color(0xFFEFE2BB),
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            accountName,
            style: const TextStyle(
              color: Color(0xFFF1E2AE),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: currentStep,
                  child: Container(color: const Color(0xFFB9232B)),
                ),
                Expanded(
                  flex: totalSteps - currentStep,
                  child: Container(color: const Color(0xFFD9C27A)),
                ),
              ],
            ),
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
      ..color = const Color(0xFF7392B7).withValues(alpha: 0.20);

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
