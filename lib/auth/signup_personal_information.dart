import 'package:flutter/material.dart';
import 'signup_account_security.dart';

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

  String get _accountName =>
      widget.accountType == 'doctor' ? 'Doctor Account' : 'Volunteer Account';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _birthdateController.text =
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  void _goNext() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    final birthdate = _birthdateController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        contact.isEmpty ||
        birthdate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

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
          const SizedBox(height: 22),

          _buildLabel('Email'),
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),

          _buildLabel('Contact number'),
          _buildTextField(
            controller: _contactController,
            hintText: 'Enter your contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 22),

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

          const SizedBox(height: 32),

          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.navigate_next_rounded, size: 28),
              label: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 21,
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
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF243B73),
          fontSize: 16,
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
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8A8A8A),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4267D6),
          size: 28,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(
                suffixIcon,
                color: const Color(0xFF7A7A7A),
                size: 24,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF4267D6),
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 38),

                    const Text(
                      'Create',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFEAF0FF),
                        fontSize: 34,
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      accountName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 34),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.28),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFF05261),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step $currentStep of $totalSteps',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stepLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 34),

                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: child,
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