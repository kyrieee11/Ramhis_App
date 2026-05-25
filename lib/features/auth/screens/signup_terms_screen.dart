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

  Future<void> _showSuccessDialog() async {
    final bool isDoctor = widget.accountType == 'doctor';

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Registration Success',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDoctor
                          ? Icons.local_hospital_rounded
                          : Icons.check_circle_rounded,
                      size: 80,
                      color: isDoctor
                          ? const Color(0xFF3949AB)
                          : const Color(0xFF22C55E),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isDoctor
                          ? 'Doctor Registration Submitted!'
                          : 'Registration Submitted!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1B2559),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isDoctor
                          ? 'Thank you for registering as a Doctor'
                          : 'Thank you for signing up as a Volunteer',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7B8BB2),
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(
                      color: const Color(0xFF7B8BB2).withValues(alpha: 0.20),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isDoctor
                          ? 'Your professional credentials have been submitted for verification.\n\n'
                              'Our admin team will review your:\n'
                              '- PRC License Number\n'
                              '- Specialty Information\n'
                              '- Hospital/Clinic Details\n\n'
                              'This verification may take 2-3 business days.'
                          : 'Your account has been submitted for admin review.\n\n'
                              'You will be able to log in once an administrator approves your account.\n\n'
                              'This usually takes 1-2 business days.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1B2559),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email_rounded,
                            color: Color(0xFF3949AB),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isDoctor
                                  ? 'Updates will be sent to ${widget.email}'
                                  : 'A confirmation will be sent to ${widget.email}',
                              style: const TextStyle(
                                color: Color(0xFF3949AB),
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF05261),
                              Color(0xFFD94350),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Got it!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: curved,
            child: child,
          ),
        );
      },
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

      await _showSuccessDialog();

      if (!mounted) return;

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