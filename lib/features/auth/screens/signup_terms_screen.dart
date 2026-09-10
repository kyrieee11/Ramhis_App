
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
    this.department = '',
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
  final String department;
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
      widget.accountType == 'doctor'
          ? 'Doctor Account'
          : 'Volunteer Account';

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
          department: widget.department,
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
          content: Text(
            'Please agree to the Terms and Conditions first.',
          ),
        ),
      );
      return;
    }

    if (widget.password != widget.confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    if (widget.accountType == 'doctor' &&
        widget.department.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor department is required.'),
        ),
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
        department: widget.department,
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
        MaterialPageRoute(
          builder: (_) => const LandingpageWidget(),
        ),
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

Welcome to the RAM Philippines Registration System. By completing your registration as a licensed healthcare professional, you acknowledge that you have read, understood, and agreed to the following terms.

1. Voluntary Participation
All medical consultations, treatments, screenings, and related services provided through RAM are voluntary. Registration does not guarantee assignment to all requested activities. Participation is subject to available resources, operational capacity, and mission requirements.

2. Scope of Medical Services
RAM Philippines provides limited healthcare services including medical consultations, basic treatment and medication, health assessments and screenings, and referral recommendations. Services are conducted based on professional clinical judgment, medical necessity, and available facilities.

3. No Guarantee of Medical Outcomes
While RAM Philippines strives to provide quality and compassionate healthcare, no guarantees are made regarding medical outcomes, diagnosis accuracy, or treatment effectiveness. Medical services may have inherent risks and limitations, especially in remote or resource-constrained environments.

4. Accuracy and Truthfulness of Information
You confirm that all professional information provided — including your PRC license number, specialty, hospital or clinic details, and uploaded license proof — is true, complete, and accurate. RAM Philippines shall not be held responsible for issues arising from false or misleading information, failure to disclose relevant credentials, or use of another person's identity. False information may result in rejection or permanent account suspension.

5. Compliance with Clinic and Safety Procedures
All healthcare professionals are expected to comply with registration procedures, clinic flow protocols, health and safety measures, and instructions from RAM personnel and site coordinators during medical missions.

6. Privacy and Data Protection
Your personal and professional information is handled in accordance with the Data Privacy Act of 2012. Information collected is used solely for patient registration, medical documentation, program monitoring, and operational reporting. Your data will not be sold or shared with unauthorized third parties.

7. Patient Confidentiality
All patient records, consultations, diagnoses, and medical information must be treated with strict confidentiality in accordance with applicable laws, ethical standards, and professional healthcare practices.

8. Consent to Documentation and Media Use
Photographs and videos may be taken during RAM missions for reporting, educational, and awareness purposes. RAM Philippines will protect patient and participant dignity and privacy. You may request exclusion from non-essential media documentation whenever reasonably possible.

9. Limitation of Liability
RAM Philippines shall not be liable for delays or interruptions in service, unavailability of medicines or equipment, adverse outcomes beyond reasonable control, or loss of personal belongings during missions. All services are provided in good faith within the limitations of available resources.

10. Right to Refuse or Discontinue Services
RAM Philippines reserves the right to refuse, suspend, or discontinue participation when false information is provided, safety rules are violated, or conduct endangers staff, volunteers, or patients.

11. Amendments and Updates
RAM Philippines may update these Terms and Conditions at any time. Continued use of the system constitutes acceptance of any revised terms.

12. Acceptance of Terms
By submitting your registration, you confirm that you have read and understood these Terms and Conditions, you voluntarily consent to the collection and processing of your information, you agree to comply with all applicable RAM Philippines policies and procedures, and you understand the nature and limitations of the medical services being provided.
'''
        : '''
TERMS AND CONDITIONS — Volunteer Account
Remote Area Medical (RAM) Philippines

Welcome to the RAM Philippines Registration System. By completing your registration as a volunteer, you acknowledge that you have read, understood, and agreed to the following terms.

1. Voluntary Participation
All services and activities performed through RAM Philippines are voluntary and free of charge to eligible communities. Registration does not guarantee assignment to all requested activities. Participation is subject to available resources, operational capacity, and mission requirements.

2. Scope of Volunteer Activities
Volunteer roles and assignments may vary depending on the availability of healthcare professionals, supplies, equipment, venue limitations, and local coordination support. RAM Philippines reserves the right to assign or reassign roles based on operational needs.

3. No Guarantee of Outcomes
Volunteer contributions and support activities are provided in good faith. Specific outcomes from medical missions cannot be guaranteed due to the nature of field healthcare operations.

4. Accuracy and Truthfulness of Information
You confirm that all personal and volunteer information provided — including your organization, skills, and identification details — is true, complete, and accurate. RAM Philippines shall not be held responsible for complications arising from false or misleading information, incomplete records, or use of another person's identity. False information may result in account suspension.

5. Compliance with Rules and Procedures
All volunteers are expected to comply with registration procedures, queueing and clinic flow protocols, health and safety measures, and instructions from RAM personnel, healthcare workers, and site coordinators. RAM Philippines reserves the right to deny or discontinue participation for individuals whose behavior is disruptive, abusive, threatening, or non-compliant with mission rules.

6. Privacy and Data Protection
Your personal information is handled in accordance with the Data Privacy Act of 2012. Information collected is used solely for volunteer registration, mission coordination, program monitoring, and operational reporting. Your data will not be sold or shared with unauthorized third parties.

7. Patient Confidentiality
Volunteers who access or encounter patient information during missions must treat all such information with strict confidentiality in accordance with applicable laws and RAM Philippines' privacy policies.

8. Consent to Documentation and Media Use
Photographs and videos may be taken during RAM missions for organizational reporting, educational, fundraising, and awareness purposes. RAM Philippines will protect participant dignity and privacy. You may request exclusion from non-essential media documentation whenever reasonably possible.

9. Limitation of Liability
RAM Philippines shall not be liable for delays or interruptions in activities, adverse outcomes beyond reasonable control, or loss, damage, or theft of personal belongings during missions. All activities are conducted in good faith within the limitations of available resources and field conditions.

10. Right to Refuse or Discontinue Services
RAM Philippines reserves the right to refuse, suspend, or discontinue volunteer participation when false information is provided, safety or operational rules are violated, or conduct endangers staff, healthcare workers, or patients.

11. Amendments and Updates
RAM Philippines may update these Terms and Conditions at any time. Continued use of the system constitutes acceptance of any revised terms.

12. Acceptance of Terms
By submitting your registration, you confirm that you have read and understood these Terms and Conditions, you voluntarily consent to the collection and processing of your information, you agree to comply with all applicable RAM Philippines policies, guidelines, and volunteer responsibilities, and you understand the nature and limitations of the services and activities provided.
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
            constraints: const BoxConstraints(minHeight: 325),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E2).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: const Color(0xFFA88B4E),
                width: 1.7,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'TERMS AND CONDITIONS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF725A2A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _accountName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF735B2C),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Remote Area Medical (RAM) Philippines',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9B8D72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.accountType == 'doctor'
                          ? 'Welcome to the RAM Philippines Registration System. By completing your registration as a licensed healthcare professional, you acknowledge that you have read, understood, and agreed to the following terms.'
                          : 'Welcome to the RAM Philippines Registration System. By completing your registration as a volunteer, you acknowledge that you have read, understood, and agreed to the following terms.',
                      style: const TextStyle(
                        color: Color(0xFF5C5140),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: const Color(0xFFD0B66F),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    termsText,
                    style: const TextStyle(
                      color: Color(0xFF5C5140),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E2).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFA88B4E),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        },
                  activeColor: const Color(0xFF17479C),
                  checkColor: const Color(0xFFF7F1E2),
                  side: const BorderSide(
                    color: Color(0xFF8E7137),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 3),
                const Expanded(
                  child: Text(
                    'I have read and agree to the Terms and Conditions.',
                    style: TextStyle(
                      color: Color(0xFF665638),
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _isSubmitting ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 51,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: _isSubmitting
                      ? [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ]
                      : const [
                          Color(0xFFB9232B),
                          Color(0xFFD94350),
                        ],
                ),
                border: Border.all(
                  color: const Color(0xFFD9C27A),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
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
                              color: Color(0xFFF8F1DB),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 13),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFF8F1DB),
                            size: 27,
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: _MarbleBackground(),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFFF7F1E2).withValues(alpha: 0.86),
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
            textAlign: TextAlign.center,
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
