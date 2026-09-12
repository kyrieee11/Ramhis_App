import 'package:flutter/material.dart';
import 'package:ramhis_app/features/auth/screens/signup_account_security_screen.dart';

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

class SignupPersonalInformationWidget extends StatefulWidget {
  const SignupPersonalInformationWidget({
    super.key,
    required this.accountType,
    this.fullName = '',
    this.email = '',
    this.contactNumber = '',
    this.birthdate = '',
    this.department = '',
  });

  final String accountType;
  final String fullName;
  final String email;
  final String contactNumber;
  final String birthdate;
  final String department;

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

  String _selectedDepartment = '';

  static const List<String> _departments = [
    'Pediatrics',
    'Neurology',
    'Pathology',
    'Circumcision',
    'Surgery',
    'PT',
    'OBGyn',
    'Dental',
    'Ophthalmology',
    'Dermatology',
    'AdultMed',
  ];

  String get _accountName {
    if (widget.accountType == 'doctor') return 'Doctor Account';
    if (widget.accountType == 'volunteer') return 'Volunteer Account';
    return 'User Account';
  }

  bool get _isDoctor => widget.accountType == 'doctor';

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _contactController = TextEditingController(text: widget.contactNumber);
    _birthdateController = TextEditingController(text: widget.birthdate);

    _selectedDepartment = widget.department;
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

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name.'),
        ),
      );
      return;
    }

    if (fullName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name must be at least 3 characters.'),
        ),
      );
      return;
    }

    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(fullName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name must contain letters only.'),
        ),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
        ),
      );
      return;
    }

    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your contact number.'),
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

    if (birthdate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your birthdate.'),
        ),
      );
      return;
    }

    if (_isDoctor && _selectedDepartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your department.'),
        ),
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
          department: _selectedDepartment,
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
          const SizedBox(height: 17),
          _buildLabel('Email'),
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 17),
          _buildLabel('Contact number'),
          _buildTextField(
            controller: _contactController,
            hintText: 'Enter your contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 17),
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
          if (_isDoctor) ...[
            const SizedBox(height: 17),
            _buildLabel('Department'),
            _buildDepartmentField(),
          ],
          const SizedBox(height: 25),
          SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.chevron_right_rounded, size: 30),
              label: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
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
          letterSpacing: 0.05,
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
        fillColor: Colors.white,
        prefixIcon: Container(
          margin: const EdgeInsets.all(3),
          width: 48,
          decoration: BoxDecoration(
            color: _kSoftBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: _kPrimary,
            size: 23,
          ),
        ),
        suffixIcon: suffixIcon == null
            ? null
            : const Icon(
                Icons.calendar_today_outlined,
                color: _kMuted,
                size: 22,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: _kBorder,
            width: 1.6,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: _kPrimary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentField() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
      decoration: InputDecoration(
        hintText: 'Select your department',
        hintStyle: const TextStyle(
          color: _kMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Container(
          margin: const EdgeInsets.all(3),
          width: 48,
          decoration: BoxDecoration(
            color: _kSoftBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            color: _kPrimary,
            size: 23,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: _kBorder,
            width: 1.6,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: _kPrimary,
            width: 2,
          ),
        ),
      ),
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _kTextSecondary,
        size: 27,
      ),
      items: _departments.map((department) {
        return DropdownMenuItem<String>(
          value: department,
          child: Text(
            department,
            style: const TextStyle(
              color: _kText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDepartment = value ?? '';
        });
      },
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
            colors: [
              _kPrimary,
              _kPrimaryDark,
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MarblePainter(),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: _kPageBg.withValues(alpha: 0.97),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Transform.translate(
                            offset: const Offset(0, -1),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
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
          colors: [
            _kPrimary,
            _kBlue,
          ],
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
                  letterSpacing: 0.1,
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
                          color: active ? _kPrimary : Colors.white.withValues(alpha: 0.55),
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
            children: labels.map((label) {
              final index = labels.indexOf(label);
              final active = index == currentStep - 1;

              return Expanded(
                child: Text(
                  label,
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

class _MarblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _kBlue.withValues(alpha: 0.08);

    final path1 = Path()
      ..moveTo(-30, 90)
      ..cubicTo(80, 10, 100, 160, 190, 80)
      ..cubicTo(250, 25, 300, 110, 390, 45)
      ..cubicTo(450, 5, 470, 100, 520, 65);

    final path2 = Path()
      ..moveTo(-40, 330)
      ..cubicTo(80, 250, 130, 400, 220, 310)
      ..cubicTo(290, 240, 340, 350, 450, 275);

    final path3 = Path()
      ..moveTo(40, size.height - 80)
      ..cubicTo(140, size.height - 170, 180, size.height - 25,
          290, size.height - 110)
      ..cubicTo(350, size.height - 165, 410, size.height - 55,
          size.width + 30, size.height - 120);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant _MarblePainter oldDelegate) => false;
}
