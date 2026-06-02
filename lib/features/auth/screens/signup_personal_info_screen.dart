import 'package:flutter/material.dart';
import 'package:ramhis_app/features/auth/screens/signup_account_security_screen.dart';

class SignupPersonalInformationWidget extends StatefulWidget {
  const SignupPersonalInformationWidget({
    super.key,
    required this.accountType,
    this.fullName = '',
    this.email = '',
    this.contactNumber = '',
    this.birthdate = '',
  });

  final String accountType;
  final String fullName;
  final String email;
  final String contactNumber;
  final String birthdate;

  @override
  State<SignupPersonalInformationWidget> createState() =>
      _SignupPersonalInformationWidgetState();
}

class _SignupPersonalInformationWidgetState
    extends State<SignupPersonalInformationWidget> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;
  late final TextEditingController _birthdateController;

  String get _accountName {
    if (widget.accountType == 'doctor') return 'Doctor Account';
    if (widget.accountType == 'volunteer') return 'Volunteer Account';
    return 'User Account';
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _contactController = TextEditingController(text: widget.contactNumber);
    _birthdateController = TextEditingController(text: widget.birthdate);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _birthdateController.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _goNext() {
    final fullName = _fullNameController.text.trim();

    final email = _emailController.text.trim().toLowerCase();

    final contact = _contactController.text.trim();

    final birthdate = _birthdateController.text.trim();

    // ───────────────── FULL NAME ─────────────────

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your full name.',
          ),
        ),
      );
      return;
    }

    if (fullName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Full name must be at least 3 characters.',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(fullName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Full name must contain letters only.',
          ),
        ),
      );
      return;
    }

    // ───────────────── EMAIL ─────────────────

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email address.',
          ),
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid email address.',
          ),
        ),
      );
      return;
    }

    // ───────────────── CONTACT ─────────────────

    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your contact number.',
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(contact)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid PH mobile number (e.g. 09123456789).',
          ),
        ),
      );
      return;
    }

    // ───────────────── BIRTHDATE ─────────────────

    if (birthdate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your birthdate.',
          ),
        ),
      );
      return;
    }

    // ───────────────── SUCCESS ─────────────────

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignupAccountSecurityWidget(
          accountType: widget.accountType,
          fullName: fullName,
          email: email,
          contactNumber: contact,
          birthdate: birthdate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SignupStepScaffold(
      accountName: _accountName,
      stepLabel: 'Personal Information',
      currentStep: 1,
      totalSteps: 4,
      onBack: () => Navigator.of(context).maybePop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel('Full name'),
          _buildTextField(
            controller: _fullNameController,
            hintText: 'Enter your full name',
            icon: Icons.person_outline_rounded,
          ),
         const SizedBox(height: 6),
          _buildLabel('Email'),
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _buildLabel('Contact number'),
          _buildTextField(
            controller: _contactController,
            hintText: 'Enter your contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
         const SizedBox(height: 10),
          _buildLabel('Birthdate'),
          GestureDetector(
            onTap: _pickBirthdate,
            child: AbsorbPointer(
              child: _buildTextField(
                controller: _birthdateController,
                hintText: 'Select your birthdate',
                icon: Icons.calendar_month_outlined,
                suffixIcon: Icons.calendar_today_outlined,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.navigate_next_rounded, size: 26),
              label: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF05261),
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
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
          color: Color(0xFF243B73),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    IconData? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8A8A8A),
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4267D6),
          size: 25,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(
                suffixIcon,
                color: const Color(0xFF7A7A7A),
                size: 22,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF4267D6),
            width: 1.5,
          ),
        ),
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
              Color(0xFF4169D8),
              Color(0xFF234AB3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
  mainAxisSize: MainAxisSize.max,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF4267D6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Create',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFEAF0FF),
                        fontSize: 25,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      accountName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: const Color(0xFFF05261),
                        backgroundColor: Colors.white24,
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 21,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Step $currentStep of $totalSteps\n$stepLabel',
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.25,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                      Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: SingleChildScrollView(
                        child: child,
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
    );
  }
}