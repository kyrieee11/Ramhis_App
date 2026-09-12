import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:ramhis_app/features/auth/screens/signup_terms_screen.dart';
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
const _kSuccess = Color(0xFF22A06B);


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
        const SizedBox(height: 17),
        _label('Upload License Proof'),
        _buildUploadBox(
          emptyTitle: 'Upload Image or PDF',
          onTap: _pickFile,
        ),
        if (selectedFileName != null) _buildUploadedStatus(),
        const SizedBox(height: 17),
        _label('Specialty'),
        _input(
          _specialtyController,
          'Enter medical specialty',
          Icons.medical_services_outlined,
        ),
        const SizedBox(height: 17),
        _label('Hospital / Clinic'),
        _input(
          _hospitalController,
          'Enter hospital or clinic',
          Icons.local_hospital_outlined,
        ),
        const SizedBox(height: 25),
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
        const SizedBox(height: 17),
        _label('Organization'),
        _input(
          _organizationController,
          'Enter organization name',
          Icons.groups_outlined,
        ),
        const SizedBox(height: 17),
        _label('Skills'),
        _input(
          _skillsController,
          'Ex. logistics, registration, first aid',
          Icons.volunteer_activism_outlined,
        ),
        const SizedBox(height: 25),
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
            color: _kTextSecondary,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: _kSoftBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _kBorder,
            width: 1.6,
          ),
        ),
        child: selectedFileName == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: _kPrimary,
                      size: 29,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptyTitle,
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JPG, PNG or PDF (max. 5MB)',
                    style: TextStyle(
                      color: _kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_outlined,
                      color: _kPrimary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedFileName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _removeFile,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUploadedStatus() {
    return const Padding(
      padding: EdgeInsets.only(left: 4, top: 6),
      child: Text(
        '✓ File uploaded successfully',
        style: TextStyle(
          color: _kSuccess,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _goNext,
        icon: const Icon(
          Icons.chevron_right_rounded,
          size: 30,
        ),
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
    );
  }

  Widget _label(String text) {
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

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: _kText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
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
                      child: Container(
                        color: _kPageBg.withValues(alpha: 0.97),
                      ),
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
