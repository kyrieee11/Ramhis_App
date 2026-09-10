import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:ramhis_app/features/auth/screens/signup_terms_screen.dart';

class SignupProfessionalVerificationWidget extends StatefulWidget {
  const SignupProfessionalVerificationWidget({
    super.key,
    required this.accountType,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.birthdate,
    required this.password,
    required this.confirmPassword,
    this.prcLicenseNumber = '',
    this.specialty = '',
    this.hospitalClinic = '',
    this.organization = '',
    this.skills = '',
    this.department = '',
  });

  final String accountType;
  final String fullName;
  final String email;
  final String contactNumber;
  final String birthdate;
  final String password;
  final String confirmPassword;
  final String prcLicenseNumber;
  final String specialty;
  final String hospitalClinic;
  final String organization;
  final String skills;
  final String department;

  @override
  State<SignupProfessionalVerificationWidget> createState() =>
      _SignupProfessionalVerificationWidgetState();
}

class _SignupProfessionalVerificationWidgetState
    extends State<SignupProfessionalVerificationWidget> {
  late final TextEditingController _licenseController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _hospitalController;
  late final TextEditingController _organizationController;
  late final TextEditingController _skillsController;

  File? selectedFile;
  String? selectedFileName;

  bool get _isDoctor => widget.accountType == 'doctor';
  bool get _isVolunteer => widget.accountType == 'volunteer';

  String get _accountTitle {
    if (_isDoctor) return 'Doctor Account';
    if (_isVolunteer) return 'Volunteer Account';
    return 'User Account';
  }

  @override
  void initState() {
    super.initState();
    _licenseController = TextEditingController(text: widget.prcLicenseNumber);
    _specialtyController = TextEditingController(text: widget.specialty);
    _hospitalController = TextEditingController(text: widget.hospitalClinic);
    _organizationController = TextEditingController(text: widget.organization);
    _skillsController = TextEditingController(text: widget.skills);
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _organizationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null) return;

    final file = result.files.single;

    if (file.path == null) return;

    if (file.size > 5 * 1024 * 1024) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File must be 5MB or smaller.'),
        ),
      );
      return;
    }

    setState(() {
      selectedFile = File(file.path!);
      selectedFileName = file.name;
    });
  }

  void _removeFile() {
    setState(() {
      selectedFile = null;
      selectedFileName = null;
    });
  }

  void _goNext() {
    final prcLicenseNumber = _licenseController.text.trim();
    final specialty = _specialtyController.text.trim();
    final hospitalClinic = _hospitalController.text.trim();
    final organization = _organizationController.text.trim();
    final skills = _skillsController.text.trim();

    if (_isDoctor) {
      if (prcLicenseNumber.isEmpty ||
          specialty.isEmpty ||
          hospitalClinic.isEmpty ||
          selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete all doctor fields and upload license proof.',
            ),
          ),
        );
        return;
      }
    }

    if (_isVolunteer) {
      if (organization.isEmpty ||
          skills.isEmpty ||
          selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete all volunteer fields and upload a valid ID.',
            ),
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupTermsConditionsWidget(
          accountType: widget.accountType,
          fullName: widget.fullName,
          email: widget.email,
          contactNumber: widget.contactNumber,
          birthdate: widget.birthdate,
          password: widget.password,
          confirmPassword: widget.confirmPassword,
          department: widget.department,
          prcLicenseNumber: prcLicenseNumber,
          specialty: specialty,
          hospitalClinic: hospitalClinic,
          organization: organization,
          skills: skills,
          proofFile: selectedFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SignupStepScaffold(
      accountName: _accountTitle,
      stepLabel: _isDoctor
          ? 'Professional Verification'
          : _isVolunteer
              ? 'Volunteer Verification'
              : 'Account Verification',
      currentStep: 3,
      totalSteps: 4,
      onBack: () => Navigator.pop(context),
      child: _isDoctor
          ? _buildDoctorFields()
          : _isVolunteer
              ? _buildVolunteerFields()
              : _buildRegularUserFields(),
    );
  }

  Widget _buildDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('PRC License Number'),
        _input(
          _licenseController,
          'Enter PRC license number',
          Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        _label('Upload License Proof'),
        _buildUploadBox(
          emptyTitle: 'Upload Image or PDF',
          onTap: _pickFile,
        ),
        if (selectedFileName != null) _buildUploadedStatus(),
        const SizedBox(height: 12),
        _label('Specialty'),
        _input(
          _specialtyController,
          'Enter medical specialty',
          Icons.medical_services_outlined,
        ),
        const SizedBox(height: 12),
        _label('Hospital / Clinic'),
        _input(
          _hospitalController,
          'Enter hospital or clinic',
          Icons.local_hospital_outlined,
        ),
        const SizedBox(height: 16),
        _nextButton(),
      ],
    );
  }

  Widget _buildVolunteerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Valid ID'),
        _buildUploadBox(
          emptyTitle: 'Upload Valid ID',
          onTap: _pickFile,
        ),
        if (selectedFileName != null) _buildUploadedStatus(),
        const SizedBox(height: 12),
        _label('Organization'),
        _input(
          _organizationController,
          'Enter organization name',
          Icons.groups_outlined,
        ),
        const SizedBox(height: 12),
        _label('Skills'),
        _input(
          _skillsController,
          'Ex. logistics, registration, first aid',
          Icons.volunteer_activism_outlined,
        ),
        const SizedBox(height: 16),
        _nextButton(),
      ],
    );
  }

  Widget _buildRegularUserFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'No additional verification is required for regular users.',
          style: TextStyle(
            color: Color(0xFF243B73),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        _nextButton(),
      ],
    );
  }

  Widget _buildUploadBox({
    required String emptyTitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 124),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1E2),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: const Color(0xFFA88B4E),
            width: 1.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: selectedFileName == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF8E7137),
                    size: 38,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    emptyTitle,
                    style: const TextStyle(
                      color: Color(0xFF765E2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JPG, PNG or PDF (max. 5MB)',
                    style: TextStyle(
                      color: Color(0xFF9B8D72),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF17479C),
                          Color(0xFF0A2B6B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_outlined,
                      color: Color(0xFFE9D9A5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedFileName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3D382E),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _removeFile,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFB9232B),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUploadedStatus() {
    return const Padding(
      padding: EdgeInsets.only(left: 5, top: 5),
      child: Text(
        '✓ File uploaded successfully',
        style: TextStyle(
          color: Color(0xFF267A45),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: double.infinity,
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
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 5),
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

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Color(0xFF3D382E),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
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
          child: Icon(
            icon,
            color: const Color(0xFFE9D9A5),
            size: 22,
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
              _buildHeader(),
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
                          color: const Color(0xFFF7F1E2),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          17,
                          24,
                          25,
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

  Widget _buildHeader() {
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
