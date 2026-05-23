import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccAboutWidget extends StatelessWidget {
  const AccAboutWidget({super.key});

  static const Color _pageBg = Color(0xFFF0F2FF);
  static const Color _cardBg = Colors.white;
  static const Color _softBlue = Color(0xFFEAF1FF);
  static const Color _titleBlue = Color(0xFF5B76F7);
  static const Color _gradientEnd = Color(0xFF4564E8);
  static const Color _textDark = Color(0xFF1B2559);
  static const Color _bodyText = Color(0xFF4A5568);
  static const Color _textSecondary = Color(0xFF7B8BB2);

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _openPhone() async {
    final uri = Uri.parse('tel:+639175823301');
    final launched = await launchUrl(uri);
    if (!launched) {
      throw Exception('Could not launch phone');
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse('mailto:ramphilippines@gmail.com');
    final launched = await launchUrl(uri);
    if (!launched) {
      throw Exception('Could not launch email');
    }
  }

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
                _titleBlue,
                _gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(),
                    const SizedBox(height: 20),
                    _buildHeading(
                      'RAM’s VISION',
                      Icons.visibility_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildTextBlock(
                      smallTitle: 'Our Vision',
                      text:
                          'Remote Area Medical (RAM) is a non-profit organization dedicated to delivering essential medical aid to the world’s most remote and underserved communities. With a vision to provide high-quality, compassionate healthcare, RAM works to improve the quality of life for impoverished and isolated populations. Dr. Heidi Sampang, the founder and country manager of RAM Philippines, leads the organization’s efforts in the country, aiming to extend this mission to those who need it most.',
                    ),
                    const SizedBox(height: 18),
                    _buildHeading(
                      'RAM’s INFO',
                      Icons.bookmark_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildTextBlock(
                      smallTitle: 'RAM Philippines',
                      text:
                          'RAM’s journey in the Philippines began in 2015, when it stepped in to assist in the aftermath of Typhoon Yolanda. Among the volunteers was Dr. Heidi Sampang, a pediatrician trained in New York, whose experience on the ground sparked a deep desire to make a lasting impact. Witnessing the urgent need for better healthcare, Dr. Sampang returned to the Philippines with a mission: to address the disparities in healthcare access across the country. Now named and officially affiliated under RAM, with a Global Health degree from Northwestern University, she founded RAM Philippines. In March 2017, the organization was formally registered with the Securities and Exchange Commission, solidifying its commitment to expanding healthcare services nationwide. Today, Dr. Sampang serves as the country manager of RAM, leading efforts to improve health outcomes for underserved communities across the Philippines.',
                    ),
                    const SizedBox(height: 18),
                    _buildHeading(
                      'Contact Info',
                      Icons.phone_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildContactPanel(),
                    const SizedBox(height: 24),
                    _buildVersionFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _titleBlue,
            _gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _titleBlue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -42,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -38,
            bottom: -48,
            child: Container(
              width: 130,
              height: 130,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 4),
              Center(
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: _titleBlue,
                      size: 60,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'RAM Philippines',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Remote Area Medical',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFEAF0FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Serving communities since 2015',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFEAF0FF),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: _titleBlue,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _titleBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _textDark,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextBlock({
    required String smallTitle,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
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
          Text(
            smallTitle,
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 13,
              height: 1.7,
              color: _bodyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPanel() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _contactCardDecoration(),
          child: Column(
            children: [
              _contactRow(
                leftIcon: Icons.language,
                leftLabel: 'Website',
                onLeftTap: () => _openUrl(
                  'https://www.facebook.com/RemoteAreaMedicalPhilippines/',
                ),
                rightWidget: _socialLink(
                  label: 'Facebook',
                  bgColor: const Color(0xFF1877F2),
                  icon: Icons.facebook,
                  onTap: () => _openUrl(
                    'https://www.facebook.com/RemoteAreaMedicalPhilippines/',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _contactCardDecoration(),
          child: _contactRow(
            leftIcon: Icons.phone,
            leftLabel: '09999999999',
            onLeftTap: _openPhone,
            rightWidget: const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _contactCardDecoration(),
          child: _contactRow(
            leftIcon: Icons.location_on,
            leftLabel: '#221B Baker St.',
            rightWidget: const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: _contactCardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _socialLink(
                label: 'Facebook',
                bgColor: const Color(0xFF1877F2),
                icon: Icons.facebook,
                onTap: () => _openUrl(
                  'https://www.facebook.com/RemoteAreaMedicalPhilippines/',
                ),
              ),
              _socialLink(
                label: 'Instagram',
                bgColor: const Color(0xFFE1306C),
                icon: Icons.camera_alt,
                onTap: () => _openUrl('https://www.instagram.com/'),
              ),
              _socialLink(
                label: 'Email',
                bgColor: const Color(0xFFEA4335),
                icon: Icons.mail,
                onTap: _openEmail,
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _contactCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.055),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _contactRow({
    required IconData leftIcon,
    required String leftLabel,
    VoidCallback? onLeftTap,
    required Widget rightWidget,
  }) {
    final Color iconColor = leftIcon == Icons.phone
        ? const Color(0xFF2BBE9B)
        : leftIcon == Icons.location_on
            ? const Color(0xFFE84D63)
            : _titleBlue;

    final leftSide = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            leftIcon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            leftLabel,
            style: const TextStyle(
              fontSize: 14,
              color: _textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: onLeftTap == null
              ? leftSide
              : InkWell(
                  onTap: onLeftTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: leftSide,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        rightWidget,
      ],
    );
  }

  Widget _socialLink({
    required String label,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFE1E6F3),
        ),
        const SizedBox(height: 18),
        const Text(
          'RAMHIS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Version 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '© 2025 RAM Philippines',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}