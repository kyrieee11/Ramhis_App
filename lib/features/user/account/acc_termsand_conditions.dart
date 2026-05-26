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
                      number: 1,
                      title: 'Voluntary Participation',
                      body:
                          'All medical consultations, treatments, screenings, and related services provided by RAM are voluntary and free of charge. Registration does not guarantee the availability or completion of all requested services. Services are provided based on available medical personnel, resources, operational capacity, and patient prioritization during medical missions.',
                    ),
                    _buildSection(
                      number: 2,
                      title: 'Scope of Medical Services',
                      body:
                          'RAM Philippines provides limited healthcare services including, but not limited to, medical consultations, basic treatment and medication, health assessments and screenings, and referral recommendations when necessary. Services are conducted based on professional clinical judgment, medical necessity, available facilities, and operational limitations. RAM Philippines reserves the right to prioritize emergency and high-risk cases when necessary.',
                    ),
                    _buildSection(
                      number: 3,
                      title: 'No Guarantee of Medical Outcomes',
                      body:
                          'While RAM Philippines strives to provide quality, ethical, and compassionate healthcare services, no guarantees or warranties are made regarding medical outcomes, recovery, diagnosis accuracy, or treatment effectiveness. Patients acknowledge that medical services may have inherent risks and limitations, especially in remote or resource-constrained environments.',
                    ),
                    _buildSection(
                      number: 4,
                      title: 'Accuracy and Truthfulness of Information',
                      body:
                          'Users and patients agree to provide complete, truthful, and accurate personal and medical information during registration and consultation. RAM Philippines shall not be held responsible for medical complications, incorrect assessments, delayed treatment, or other issues arising from false or misleading information, failure to disclose relevant medical history, incomplete patient records, or use of another person\'s identity or information.',
                    ),
                    _buildSection(
                      number: 5,
                      title: 'Compliance with Clinic and Safety Procedures',
                      body:
                          'All users, patients, guardians, and companions are expected to comply with registration procedures, queueing and clinic flow protocols, health and safety measures, and instructions from RAM personnel, volunteers, healthcare workers, and security staff. RAM Philippines reserves the right to deny or discontinue services to individuals whose behavior is disruptive, abusive, threatening, unsafe, or non-compliant with mission rules and regulations.',
                    ),
                    _buildSection(
                      number: 6,
                      title: 'Privacy and Data Protection',
                      body:
                          'RAM Philippines respects and protects the privacy and confidentiality of patient information in accordance with the Data Privacy Act of 2012. Personal and medical information collected through the RAM registration system may be used solely for patient registration and identification, medical consultation and treatment, healthcare documentation, program monitoring and reporting, statistical and operational analysis, and referral coordination and follow-up services. Patient information shall not be sold, shared, or disclosed to unauthorized third parties except when required by law, for legitimate medical and operational purposes, or with the consent of the patient or authorized representative.',
                    ),
                    _buildSection(
                      number: 7,
                      title: 'Patient Confidentiality',
                      body:
                          'All patient records, consultations, diagnoses, and medical information shall be treated with strict confidentiality by RAM staff, healthcare professionals, and volunteers. Only authorized personnel involved in patient care, registration, and operations may access necessary information in accordance with applicable laws, ethical standards, and healthcare confidentiality practices.',
                    ),
                    _buildSection(
                      number: 8,
                      title: 'Consent to Documentation and Media Use',
                      body:
                          'During RAM medical missions, photographs, videos, and activity documentation may be taken for organizational reporting, transparency, educational, fundraising, and public awareness purposes. RAM Philippines will make reasonable efforts to protect patient dignity and privacy. Personally identifiable medical information shall not be publicly disclosed without appropriate consent unless otherwise permitted by law. Users may request exclusion from non-essential photography or media documentation whenever reasonably possible.',
                    ),
                    _buildSection(
                      number: 9,
                      title: 'Limitation of Liability',
                      body:
                          'To the fullest extent permitted by applicable law, RAM Philippines, its officers, healthcare professionals, staff, volunteers, partners, and affiliated organizations shall not be held liable for delays or interruptions in service, unavailability of medicines, equipment, or specialists, adverse medical outcomes beyond reasonable control, loss, damage, or theft of personal belongings during missions, or indirect, incidental, or consequential damages arising from participation in RAM activities. All services are provided in good faith and within the limitations of available resources and field conditions.',
                    ),
                    _buildSection(
                      number: 10,
                      title: 'Right to Refuse or Discontinue Services',
                      body:
                          'RAM Philippines reserves the right to refuse, suspend, limit, or discontinue services when false information is intentionally provided, safety and operational rules are violated, behavior endangers staff, volunteers, or other patients, abuse, harassment, or unlawful conduct occurs, or medical services exceed operational capabilities.',
                    ),
                    _buildSection(
                      number: 11,
                      title: 'Amendments and Updates',
                      body:
                          'RAM Philippines reserves the right to modify, update, or revise these Terms and Conditions at any time without prior notice to ensure compliance with operational requirements, healthcare standards, and applicable laws. Continued use of the RAM registration system constitutes acceptance of any updated Terms and Conditions.',
                    ),
                    _buildSection(
                      number: 12,
                      title: 'Acceptance of Terms',
                      body:
                          'By proceeding with registration and use of the RAM system, you confirm that you have read and understood these Terms and Conditions, you voluntarily consent to the collection and processing of your information, you agree to comply with all applicable policies and procedures of RAM Philippines, and you understand the nature and limitations of the medical services being provided.',
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
    required int number,
    required String title,
    required String body,
    bool isLast = false,
  }) {
    final Color accentColor = number <= 3
        ? _primaryBlue
        : number <= 6
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
                                '$number. $title',
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
