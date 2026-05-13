import 'dart:io';

import 'package:flutter/material.dart';

import 'package:ramhis_app/features/auth/screens/signup_verification_screen.dart';
import 'package:ramhis_app/features/auth/screens/landing_page.dart';
import 'package:ramhis_app/services/api/auth_service.dart';

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

    if (widget.password != widget.confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AuthService.signup(
        fullName: widget.fullName,
        email: widget.email,
        password: widget.password,
        accountType: widget.accountType,
        contactNumber: widget.contactNumber,
        birthdate: widget.birthdate,
        acceptedTerms: _acceptedTerms,
        prcLicenseNumber: widget.prcLicenseNumber,
        specialty: widget.specialty,
        hospitalClinic: widget.hospitalClinic,
        organization: widget.organization,
        skills: widget.skills,
        licenseFile: widget.proofFile,
      );

      if (!mounted) return;

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
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsText = widget.accountType == 'doctor'
        ? '''
Doctor Terms and Conditions

By submitting your registration, you confirm that all professional information provided is true and accurate.

Your PRC license number, specialty, hospital or clinic details, and uploaded license proof will be reviewed by the RAMHIS admin team.

Your account may remain pending until approved by an administrator.

False or misleading information may result in rejection or account suspension.
'''
        : '''
Volunteer Terms and Conditions

By submitting your registration, you confirm that your personal and volunteer information is true and accurate.

Your organization and skills may be used by RAMHIS to match you with appropriate medical mission activities.

You agree to follow RAMHIS guidelines, event rules, and volunteer responsibilities.

False or misleading information may result in account suspension.
''';

    return _SignupStepScaffold(
      accountName: _accountName,
      stepLabel: 'Terms and Conditions',
      currentStep: 4,
      totalSteps: 4,
      onBack: _goBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
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
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    accountName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: progress,
                    color: const Color(0xFFF05261),
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
                          Icons.article_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Step $currentStep of $totalSteps\n$stepLabel',
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
        ],
      ),
    );
  }
}