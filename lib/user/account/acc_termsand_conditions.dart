import 'package:flutter/material.dart';

class AccTermsandConditionsWidget extends StatelessWidget {
  const AccTermsandConditionsWidget({super.key});

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
          'Terms & Conditions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 18),
                    _buildSection(
                      title: '1. Voluntary Participation',
                      body:
                          'All services provided by Remote Area Medical (RAM) Philippines are voluntary and offered free of charge to eligible patients and communities.',
                    ),
                    _buildSection(
                      title: '2. Scope of Services',
                      body:
                          'Services may vary depending on the availability of licensed healthcare professionals, supplies, equipment, venue limitations, and local coordination support.',
                    ),
                    _buildSection(
                      title: '3. No Guarantee of Outcomes',
                      body:
                          'Medical consultation, treatment, or follow-up recommendations are given in good faith, but specific outcomes cannot be guaranteed.',
                    ),
                    _buildSection(
                      title: '4. Accuracy of Information',
                      body:
                          'Patients and participants are responsible for providing complete, truthful, and accurate personal and medical information during registration and consultation.',
                    ),
                    _buildSection(
                      title: '5. Compliance with Rules',
                      body:
                          'All participants are expected to follow the instructions of RAM staff, partner volunteers, healthcare workers, and site coordinators during operations.',
                    ),
                    _buildSection(
                      title: '6. Right to Refuse Services',
                      body:
                          'RAM Philippines reserves the right to deny, suspend, or discontinue services when necessary for safety, policy enforcement, or operational limitations.',
                    ),
                    _buildSection(
                      title: '7. Privacy',
                      body:
                          'Personal information collected during registration and service delivery will be handled responsibly and in accordance with the organization’s privacy practices.',
                    ),
                    _buildSection(
                      title: '8. Liability',
                      body:
                          'RAM Philippines shall not be held liable beyond the limits provided by applicable law for delays, interruptions, or service limitations caused by circumstances beyond reasonable control.',
                    ),
                    _buildSection(
                      title: '9. Acceptance',
                      body:
                          'By continuing to use the app and participating in RAM Philippines services, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.',
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: _primaryBlue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Please read these terms carefully. These guidelines explain the responsibilities, service limitations, and participation rules for Remote Area Medical (RAM) Philippines.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String body,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD9E5FF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: _textDark,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}