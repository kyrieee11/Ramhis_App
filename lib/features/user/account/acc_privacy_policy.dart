import 'package:flutter/material.dart';

class AccPrivacyPolicyWidget extends StatelessWidget {
  const AccPrivacyPolicyWidget({super.key});

  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _primaryBlue = Color(0xFF10539B);
  static const Color _gradientEnd = Color(0xFF0B4380);
  static const Color _blue = Color(0xFF1863B5);
  static const Color _softBlue = Color(0xFFEBF3FA);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _border = Color(0xFFCDE1EC);
  static const Color _textDark = Color(0xFF102A43);
  static const Color _bodyText = Color(0xFF526579);
  static const Color _textSecondary = Color(0xFF8292A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryBlue,
                _gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _pageBg,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(),
                    SizedBox(height: 18),
                    _Section(
                      number: 1,
                      title: 'Information We Collect',
                      body:
                          'During registration, consultation, and medical service delivery, RAM Philippines may collect personal details such as full name, age, sex, birthdate, address, and contact information, as well as medical and health-related information necessary for consultation, diagnosis, treatment, referral services, and medical documentation. Only information necessary for legitimate medical, operational, and healthcare-related purposes is collected.',
                    ),
                    _Section(
                      number: 2,
                      title: 'How We Use Your Information',
                      body:
                          'Your personal and medical information may be used to register patients for RAM medical services, provide medical consultation, treatment, and healthcare support, maintain patient records for continuity of care, coordinate referrals and follow-up services, improve RAM healthcare programs and medical outreach services, conduct operational reporting and statistical analysis, and comply with applicable legal, regulatory, and reporting requirements. Your information shall not be used for unauthorized commercial, advertising, or marketing purposes.',
                    ),
                    _Section(
                      number: 3,
                      title: 'Confidentiality and Data Protection',
                      body:
                          'RAM Philippines treats all personal and medical information with strict confidentiality. Reasonable organizational, physical, and technical security measures are implemented against unauthorized access, accidental disclosure, misuse or unlawful processing, and data loss, alteration, or destruction. Access to records is limited only to authorized RAM staff, healthcare professionals, volunteers, and personnel with legitimate operational or medical responsibilities.',
                    ),
                    _Section(
                      number: 4,
                      title: 'Sharing of Information',
                      body:
                          'RAM Philippines does not sell, rent, or trade personal information to third parties. Information may only be shared when required by law or government authorities, when necessary to protect patient health, safety, or public welfare, for referrals or coordination with healthcare providers with patient consent when applicable, or for legitimate medical and operational purposes directly related to RAM services. Any authorized sharing shall comply with applicable privacy and confidentiality laws.',
                    ),
                    _Section(
                      number: 5,
                      title: 'Data Retention',
                      body:
                          'Personal and medical information shall be retained only for as long as necessary to fulfill medical, operational, legal, and regulatory purposes. RAM Philippines reserves the right to securely archive or dispose of records in accordance with applicable laws, healthcare standards, and organizational policies.',
                    ),
                    _Section(
                      number: 6,
                      title: 'Your Rights',
                      body:
                          'Under the Data Privacy Act of 2012, you have the right to know how your personal information is collected and used, request access to your personal information, request correction of inaccurate or incomplete information, ask questions regarding the handling of your data, withdraw consent where applicable, and refuse to provide certain information, understanding that this may limit the services RAM Philippines can provide. Requests may be subject to verification and applicable legal or medical record retention requirements.',
                    ),
                    _Section(
                      number: 7,
                      title: 'Consent',
                      body:
                          'By registering with Remote Area Medical (RAM) Philippines and using the RAM Mobile Application, you acknowledge that you have read and understood this Privacy Policy, you voluntarily provide your personal and medical information, and you consent to the collection, processing, storage, and use of your information for legitimate medical, operational, and program-related purposes.',
                    ),
                    _Section(
                      number: 8,
                      title: 'Updates to this Privacy Policy',
                      body:
                          'RAM Philippines reserves the right to update or modify this Privacy Policy at any time to ensure compliance with applicable laws, healthcare standards, operational requirements, and organizational policies. Continued use of the RAM system after updates constitutes acceptance of the revised Privacy Policy.',
                    ),
                    _Section(
                      number: 9,
                      title: 'Contact and Privacy Concerns',
                      body:
                          'For questions, concerns, corrections, or requests regarding your personal information and privacy rights, users may contact RAM Philippines through its official communication channels or designated system administrators.',
                      isLast: true,
                    ),
                    SizedBox(height: 28),
                    _Footer(),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AccPrivacyPolicyWidget._primaryBlue,
            AccPrivacyPolicyWidget._gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AccPrivacyPolicyWidget._primaryBlue.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -38,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -42,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 18,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.privacy_tip,
                        color: AccPrivacyPolicyWidget._primaryBlue,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'This policy explains how RAM Philippines handles your data in compliance with the Data Privacy Act of 2012.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFFE3F2FD),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Last updated: 2025',
                  style: TextStyle(
                    color: Color(0xFFE3F2FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final bool isLast;

  const _Section({
    required this.number,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AccPrivacyPolicyWidget._border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: AccPrivacyPolicyWidget._primaryBlue,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AccPrivacyPolicyWidget._primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                number.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AccPrivacyPolicyWidget._textDark,
                                  fontSize: 16,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            color: AccPrivacyPolicyWidget._bodyText,
                            fontSize: 14,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AccPrivacyPolicyWidget._softBlue,
              shape: BoxShape.circle,
              border: Border.all(
                color: AccPrivacyPolicyWidget._border,
              ),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: AccPrivacyPolicyWidget._primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'RAM Philippines',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AccPrivacyPolicyWidget._textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '© 2025 RAM Philippines',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AccPrivacyPolicyWidget._textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'All rights reserved',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AccPrivacyPolicyWidget._textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
