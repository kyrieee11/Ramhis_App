import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:ramhis_app/features/auth/screens/signup_verification_screen.dart';
import 'package:ramhis_app/features/auth/screens/landing_page.dart';

class SignupTermsConditionsWidget extends StatefulWidget {
  const SignupTermsConditionsWidget({
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
    this.acceptedTerms = false,
    this.proofFile,
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
  final bool acceptedTerms;
  final File? proofFile;

  @override
  State<SignupTermsConditionsWidget> createState() =>
      _SignupTermsConditionsWidgetState();
}

class _SignupTermsConditionsWidgetState
    extends State<SignupTermsConditionsWidget> {
  late bool _acceptedTerms;
  bool _isSubmitting = false;

  static const String baseUrl = 'http://10.0.2.2:5000';

  String get _accountName =>
      widget.accountType == 'doctor' ? 'Doctor Account' : 'Volunteer Account';

  @override
  void initState() {
    super.initState();
    _acceptedTerms = widget.acceptedTerms;
  }

  void _goBack() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignupProfessionalVerificationWidget(
          accountType: widget.accountType,
          fullName: widget.fullName,
          email: widget.email,
          contactNumber: widget.contactNumber,
          birthdate: widget.birthdate,
          password: widget.password,
          confirmPassword: widget.confirmPassword,
          prcLicenseNumber: widget.prcLicenseNumber,
          specialty: widget.specialty,
          hospitalClinic: widget.hospitalClinic,
          organization: widget.organization,
          skills: widget.skills,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions first.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/signup'),
      );

      request.fields.addAll({
        'full_name': widget.fullName,
        'email': widget.email,
        'password': widget.password,
        'account_type': widget.accountType,
        'contact_number': widget.contactNumber,
        'birthdate': widget.birthdate,
        'accepted_terms': 'true',
        'prc_license_number': widget.prcLicenseNumber,
        'specialty': widget.specialty,
        'hospital_clinic': widget.hospitalClinic,
        'organization': widget.organization,
        'skills': widget.skills,
      });

      if (widget.proofFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_file',
            widget.proofFile!.path,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      Map<String, dynamic> data = {};
      if (responseData.isNotEmpty) {
        data = jsonDecode(responseData);
      }

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.accountType == 'doctor'
                  ? 'Doctor registration submitted. Await admin approval.'
                  : 'Volunteer registration submitted successfully.',
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingpageWidget()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((data['message'] ?? 'Signup failed.').toString()),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please try again.')),
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsText = widget.accountType == 'doctor'
        ? 'By submitting this Doctor registration, you confirm that all professional credentials provided are accurate and may be reviewed by the admin team before activation.\n\nYou also agree to comply with all platform policies and guidelines. Any false information may result in rejection or permanent suspension of your account.\n\nYour privacy and data will be handled in accordance with our Privacy Policy.'
        : 'By submitting this Volunteer registration, you confirm that all personal and organization details provided are accurate and may be reviewed by the admin team before activation.\n\nYou also agree to comply with all platform policies and guidelines. Any false information may result in rejection or permanent suspension of your account.\n\nYour privacy and data will be handled in accordance with our Privacy Policy.';

    return _SignupStepScaffold(
      accountName: _accountName,
      stepLabel: 'Review & Submit',
      currentStep: 4,
      totalSteps: 4,
      onBack: _goBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF172B5F),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            constraints: const BoxConstraints(minHeight: 260, maxHeight: 340),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Text(
                termsText,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.15,
                child: Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF4267D6),
                  checkColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFF172B5F),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'I have read and agree to the Terms and Conditions.',
                  style: TextStyle(
                    color: Color(0xFF172B5F),
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isSubmitting ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: _isSubmitting
                      ? [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ]
                      : const [
                          Color(0xFFF05261),
                          Color(0xFFD94350),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit Registration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 14),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
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
                    const SizedBox(height: 36),
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
                        fontSize: 40,
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
                    const SizedBox(height: 26),
                    Text(
                      'Step $currentStep of $totalSteps  •  $stepLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFEAF0FF),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
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