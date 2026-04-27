import 'package:flutter/material.dart';

class AccPrivacyPolicyWidget extends StatelessWidget {
  const AccPrivacyPolicyWidget({super.key});

  static const Color _pageBg = Color(0xFFF6F8FC);
  static const Color _primaryBlue = Color(0xFF3F5FBE);
  static const Color _softBlue = Color(0xFFEAF1FF);
  static const Color _textDark = Color(0xFF1B2559);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _pageBg,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AccPrivacyPolicyWidget._softBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip, color: AccPrivacyPolicyWidget._primaryBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AccPrivacyPolicyWidget._primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'This policy explains how RAM Philippines handles your data.',
            style: TextStyle(fontSize: 13.5, height: 1.5),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9E5FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AccPrivacyPolicyWidget._primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.justify),
          ],
        ),
      ),
    );
  }
}