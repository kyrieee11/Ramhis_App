import 'package:flutter/material.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';

class AccTermsandConditionsWidget extends StatelessWidget {
  const AccTermsandConditionsWidget({super.key});

  static const Color _cream = Color(0xFFF8FAFC);
  static const Color _creamLight = Color(0xFFFFFFFF);
  static const Color _navy = Color(0xFF10539B);
  static const Color _navyDark = Color(0xFF0B4380);
  static const Color _blue = Color(0xFF1863B5);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _softBlue = Color(0xFFEBF3FA);
  static const Color _border = Color(0xFFCDE1EC);
  static const Color _text = Color(0xFF102A43);
  static const Color _body = Color(0xFF526579);
  static const Color _muted = Color(0xFF8292A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _lightBlue,
            size: 21,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: _cream,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_navy, _navyDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: _lightBlue,
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_cream, _softBlue, _creamLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 24),
            child: Column(
              children: const [
                _TermsHero(),
                SizedBox(height: 13),
                _TermsSection(
                  number: 1,
                  title: 'Voluntary Participation',
                  body:
                      'All medical consultations, treatments, screenings, and related services provided by RAM are voluntary and free of charge. Registration does not guarantee the availability or completion of all requested services. Services are provided based on available medical personnel, resources, operational capacity, and patient prioritization during medical missions.',
                ),
                _TermsSection(
                  number: 2,
                  title: 'Scope of Medical Services',
                  body:
                      'RAM Philippines provides limited healthcare services including, but not limited to, medical consultations, basic treatment and medication, health assessments and screenings, and referral recommendations when necessary. Services are conducted based on professional clinical judgment, medical necessity, available facilities, and operational limitations. RAM Philippines reserves the right to prioritize emergency and high-risk cases when necessary.',
                ),
                _TermsSection(
                  number: 3,
                  title: 'No Guarantee of Medical Outcomes',
                  body:
                      'While RAM Philippines strives to provide quality, ethical, and compassionate healthcare services, no guarantees or warranties are made regarding medical outcomes, recovery, diagnosis accuracy, or treatment effectiveness. Patients acknowledge that medical services may have inherent risks and limitations, especially in remote or resource-constrained environments.',
                ),
                _TermsSection(
                  number: 4,
                  title: 'Accuracy and Truthfulness of Information',
                  body:
                      'Users and patients agree to provide complete, truthful, and accurate personal and medical information during registration and consultation. RAM Philippines shall not be held responsible for medical complications, incorrect assessments, delayed treatment, or other issues arising from false or misleading information, failure to disclose relevant medical history, incomplete patient records, or use of another person\'s identity or information.',
                ),
                _TermsSection(
                  number: 5,
                  title: 'Compliance with Clinic and Safety Procedures',
                  body:
                      'All users, patients, guardians, and companions are expected to comply with registration procedures, queueing and clinic flow protocols, health and safety measures, and instructions from RAM personnel, volunteers, healthcare workers, and security staff. RAM Philippines reserves the right to deny or discontinue services to individuals whose behavior is disruptive, abusive, threatening, unsafe, or non-compliant with mission rules and regulations.',
                ),
                _TermsSection(
                  number: 6,
                  title: 'Privacy and Data Protection',
                  body:
                      'RAM Philippines respects and protects the privacy and confidentiality of patient information in accordance with the Data Privacy Act of 2012. Personal and medical information collected through the RAM registration system may be used solely for patient registration and identification, medical consultation and treatment, healthcare documentation, program monitoring and reporting, statistical and operational analysis, and referral coordination and follow-up services. Patient information shall not be sold, shared, or disclosed to unauthorized third parties except when required by law, for legitimate medical and operational purposes, or with the consent of the patient or authorized representative.',
                ),
                _TermsSection(
                  number: 7,
                  title: 'Patient Confidentiality',
                  body:
                      'All patient records, consultations, diagnoses, and medical information shall be treated with strict confidentiality by RAM staff, healthcare professionals, and volunteers. Only authorized personnel involved in patient care, registration, and operations may access necessary information in accordance with applicable laws, ethical standards, and healthcare confidentiality practices.',
                ),
                _TermsSection(
                  number: 8,
                  title: 'Consent to Documentation and Media Use',
                  body:
                      'During RAM medical missions, photographs, videos, and activity documentation may be taken for organizational reporting, transparency, educational, fundraising, and public awareness purposes. RAM Philippines will make reasonable efforts to protect patient dignity and privacy. Personally identifiable medical information shall not be publicly disclosed without appropriate consent unless otherwise permitted by law. Users may request exclusion from non-essential photography or media documentation whenever reasonably possible.',
                ),
                _TermsSection(
                  number: 9,
                  title: 'Limitation of Liability',
                  body:
                      'To the fullest extent permitted by applicable law, RAM Philippines, its officers, healthcare professionals, staff, volunteers, partners, and affiliated organizations shall not be held liable for delays or interruptions in service, unavailability of medicines, equipment, or specialists, adverse medical outcomes beyond reasonable control, loss, damage, or theft of personal belongings during missions, or indirect, incidental, or consequential damages arising from participation in RAM activities. All services are provided in good faith and within the limitations of available resources and field conditions.',
                ),
                _TermsSection(
                  number: 10,
                  title: 'Right to Refuse or Discontinue Services',
                  body:
                      'RAM Philippines reserves the right to refuse, suspend, limit, or discontinue services when false information is intentionally provided, safety and operational rules are violated, behavior endangers staff, volunteers, or other patients, abuse, harassment, or unlawful conduct occurs, or medical services exceed operational capabilities.',
                ),
                _TermsSection(
                  number: 11,
                  title: 'Amendments and Updates',
                  body:
                      'RAM Philippines reserves the right to modify, update, or revise these Terms and Conditions at any time without prior notice to ensure compliance with operational requirements, healthcare standards, and applicable laws. Continued use of the RAM registration system constitutes acceptance of any updated Terms and Conditions.',
                ),
                _TermsSection(
                  number: 12,
                  title: 'Acceptance of Terms',
                  body:
                      'By proceeding with registration and use of the RAM system, you confirm that you have read and understood these Terms and Conditions, you voluntarily consent to the collection and processing of your information, you agree to comply with all applicable policies and procedures of RAM Philippines, and you understand the nature and limitations of the medical services being provided.',
                ),
                SizedBox(height: 10),
                _TermsFooter(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 3),
    );
  }
}

class _TermsHero extends StatelessWidget {
  const _TermsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AccTermsandConditionsWidget._navy,
            AccTermsandConditionsWidget._navyDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AccTermsandConditionsWidget._lightBlue,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AccTermsandConditionsWidget._lightBlue.withValues(
                    alpha: 0.10,
                  ),
                  width: 16,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: -48,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.035),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 63,
                    height: 63,
                    decoration: BoxDecoration(
                      color: AccTermsandConditionsWidget._softBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AccTermsandConditionsWidget._lightBlue,
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AccTermsandConditionsWidget._navy,
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Please read these terms carefully. These guidelines explain the responsibilities, service limitations, and participation rules for Remote Area Medical (RAM) Philippines.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.48,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Effective Date: 2025',
                  style: TextStyle(
                    color: AccTermsandConditionsWidget._lightBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _TermsSection extends StatelessWidget {
  final int number;
  final String title;
  final String body;

  const _TermsSection({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      decoration: BoxDecoration(
        color: AccTermsandConditionsWidget._creamLight.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AccTermsandConditionsWidget._border,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.075),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 39,
                height: 39,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AccTermsandConditionsWidget._navy,
                      AccTermsandConditionsWidget._navyDark,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AccTermsandConditionsWidget._lightBlue,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: const TextStyle(
                    color: AccTermsandConditionsWidget._text,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            body,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: AccTermsandConditionsWidget._body,
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AccTermsandConditionsWidget._lightBlue,
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: AccTermsandConditionsWidget._navy,
            size: 27,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'RAM Philippines',
          style: TextStyle(
            color: AccTermsandConditionsWidget._text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          '© 2025 All rights reserved',
          style: TextStyle(
            color: AccTermsandConditionsWidget._muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
