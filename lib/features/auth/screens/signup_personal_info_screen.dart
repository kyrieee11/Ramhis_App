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
          const SizedBox(height: 8),
          _buildLabel('Email'),
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          _buildLabel('Contact number'),
          _buildTextField(
            controller: _contactController,
            hintText: 'Enter your contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            _buildLabel('Department'),
            _buildDepartmentField(),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 49,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.chevron_right_rounded, size: 27),
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
      padding: const EdgeInsets.only(left: 5, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF182A52),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.15,
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
        fillColor: const Color(0xFFF7F1E2),
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
            border: const Border(
              right: BorderSide(
                color: Color(0xFFD9C27A),
                width: 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFE9D9A5),
            size: 23,
          ),
        ),
        suffixIcon: suffixIcon == null
            ? null
            : const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF8B806A),
                size: 22,
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
      ),
    );
  }

  Widget _buildDepartmentField() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
      decoration: InputDecoration(
        hintText: 'Select your department',
        hintStyle: const TextStyle(
          color: Color(0xFF8B806A),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F1E2),
        prefixIcon: Container(
          margin: const EdgeInsets.all(3),
          width: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF17479C),
                Color(0xFF0A2B6B),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            color: Color(0xFFE9D9A5),
            size: 23,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
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
      ),
      dropdownColor: const Color(0xFFF7F1E2),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF806B3B),
        size: 26,
      ),
      items: _departments.map((department) {
        return DropdownMenuItem<String>(
          value: department,
          child: Text(
            department,
            style: const TextStyle(
              color: Color(0xFF3D382E),
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MarblePainter(),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFF8F3E5).withValues(alpha: 0.88),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: child,
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
              letterSpacing: 0.2,
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
                  flex: 1,
                  child: Container(color: const Color(0xFFB9232B)),
                ),
                Expanded(
                  flex: 3,
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

class _MarblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF8DA8C8).withValues(alpha: 0.22);

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
