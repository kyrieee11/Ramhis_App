import 'package:flutter/material.dart';

class AccPrivacyPolicyWidget extends StatelessWidget {
  const AccPrivacyPolicyWidget({super.key});

  static const Color _pageBg = Color(0xFFF0F2FF);
  static const Color _primaryBlue = Color(0xFF5B76F7);
  static const Color _gradientEnd = Color(0xFF4564E8);
  static const Color _softBlue = Color(0xFFEAF1FF);
  static const Color _textDark = Color(0xFF1B2559);
  static const Color _bodyText = Color(0xFF4A5568);
  static const Color _textSecondary = Color(0xFF7B8BB2);

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
                      title: 'Information We Collect',
                      body:
                          'RAM Philippines may collect personal details such as name, age, sex, address, and contact information, as well as medical data necessary to provide proper care.',
                    ),
                    _Section(
                      title: 'How We Use Your Information',
                      body:
                          'Your information is used to register you for services, provide consultation and treatment, maintain medical records, and improve services.',
                    ),
                    _Section(
                      title: 'Confidentiality and Protection',
                      body:
                          'All personal and medical information is treated as confidential and protected against unauthorized access.',
                    ),
                    _Section(
                      title: 'Sharing of Information',
                      body:
                          'RAM does not sell or share personal data with third parties except when required by law or necessary for safety.',
                    ),
                    _Section(
                      title: 'Your Rights',
                      body:
                          'You may request corrections, ask questions, or refuse to provide data (with service limitations).',
                    ),
                    _Section(
                      title: 'Consent',
                      body:
                          'By registering, you agree to the collection and use of your data for medical purposes.',
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
            color: AccPrivacyPolicyWidget._primaryBlue.withValues(alpha: 0.25),
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
                'This policy explains how RAM Philippines handles your data.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFFEAF0FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Last updated: 2025',
                  style: TextStyle(
                    color: Color(0xFFEAF0FF),
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
  final String title;
  final String body;
  final bool isLast;

  const _Section({
    required this.title,
    required this.body,
    this.isLast = false,
  });

  int get _sectionNumber {
    switch (title) {
      case 'Information We Collect':
        return 1;
      case 'How We Use Your Information':
        return 2;
      case 'Confidentiality and Protection':
        return 3;
      case 'Sharing of Information':
        return 4;
      case 'Your Rights':
        return 5;
      case 'Consent':
        return 6;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                                _sectionNumber.toString(),
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
                color: AccPrivacyPolicyWidget._primaryBlue.withValues(
                  alpha: 0.16,
                ),
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