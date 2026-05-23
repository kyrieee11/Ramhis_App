import 'package:flutter/material.dart';

class AccTermsandConditionsWidget extends StatelessWidget {
  const AccTermsandConditionsWidget({super.key});

  static const Color _pageBg = Color(0xFFF0F2FF);
  static const Color _primaryBlue = Color(0xFF5B76F7);
  static const Color _gradientEnd = Color(0xFF4564E8);
  static const Color _greenAccent = Color(0xFF2BBE9B);
  static const Color _purpleAccent = Color(0xFF7A5AF8);
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
          'Terms & Conditions',
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
                    const SizedBox(height: 28),
                    _buildFooter(),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _primaryBlue,
            _gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.25),
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
                        Icons.description_rounded,
                        color: _primaryBlue,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Terms and Conditions',
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
                'Please read these terms carefully. These guidelines explain the responsibilities, service limitations, and participation rules for Remote Area Medical (RAM) Philippines.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Color(0xFFEAF0FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Effective Date: 2025',
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

  Widget _buildSection({
    required String title,
    required String body,
    bool isLast = false,
  }) {
    final int sectionNumber = int.tryParse(title.split('.').first) ?? 1;

    final Color accentColor = sectionNumber <= 3
        ? _primaryBlue
        : sectionNumber <= 6
            ? _greenAccent
            : _purpleAccent;

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
                  color: accentColor,
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
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: accentColor,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.7,
                            color: _bodyText,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.justify,
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

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _softBlue,
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryBlue.withValues(alpha: 0.16),
              ),
            ),
            child: const Icon(
              Icons.article_rounded,
              color: _primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'RAM Philippines',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '© 2025 All rights reserved',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'By using this app you agree to these terms',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}