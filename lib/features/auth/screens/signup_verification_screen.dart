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

  String get _accountTitle =>
      _isDoctor ? 'Doctor Account' : 'Volunteer Account';

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
        const SnackBar(content: Text('File must be 5MB or smaller.')),
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
              'Please complete all fields and upload license proof.',
            ),
          ),
        );
        return;
      }
    } else {
      if (organization.isEmpty || skills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all volunteer fields.'),
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 82),

                    const Text(
                      'Create',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    Text(
                      _accountTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const LinearProgressIndicator(
                      value: 3 / 4,
                      color: Color(0xFFF05261),
                      backgroundColor: Colors.white24,
                      minHeight: 6,
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Step 3 of 4\n${_isDoctor ? 'Professional Verification' : 'Volunteer Verification'}',
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: _isDoctor
                              ? _buildDoctorFields()
                              : _buildVolunteerFields(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 58,
            left: 24,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF4267D6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('PRC License Number'),
        _input(
          _licenseController,
          'Enter PRC license number',
          Icons.badge_outlined,
        ),

        const SizedBox(height: 20),

        _label('Upload License Proof'),
        const SizedBox(height: 10),

        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4267D6),
                width: 1.5,
              ),
            ),
            child: selectedFileName == null
                ? const Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF4267D6),
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload Image or PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4267D6),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'JPG, PNG or PDF (max. 5MB)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFileName!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF243B73),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _removeFile,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        if (selectedFileName != null) ...[
          const SizedBox(height: 8),
          const Text(
            '✔ File uploaded successfully',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        const SizedBox(height: 20),

        _label('Specialty'),
        _input(
          _specialtyController,
          'Enter medical specialty',
          Icons.medical_services_outlined,
        ),

        const SizedBox(height: 20),

        _label('Hospital / Clinic'),
        _input(
          _hospitalController,
          'Enter hospital or clinic',
          Icons.local_hospital_outlined,
        ),

        const SizedBox(height: 30),

        _nextButton(),
      ],
    );
  }

  Widget _buildVolunteerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Organization'),
        _input(
          _organizationController,
          'Enter organization name',
          Icons.groups_outlined,
        ),

        const SizedBox(height: 20),

        _label('Skills'),
        _input(
          _skillsController,
          'Ex. logistics, registration, first aid',
          Icons.volunteer_activism_outlined,
        ),

        const SizedBox(height: 30),

        _nextButton(),
      ],
    );
  }

  Widget _nextButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _goNext,
        icon: const Icon(Icons.navigate_next),
        label: const Text(
          'Next',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF05261),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF243B73),
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
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4267D6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
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