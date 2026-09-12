import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccAboutWidget extends StatelessWidget {
  const AccAboutWidget({super.key});

  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _cardBg = Colors.white;
  static const Color _softBlue = Color(0xFFEBF3FA);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _titleBlue = Color(0xFF10539B);
  static const Color _blue = Color(0xFF1863B5);
  static const Color _gradientEnd = Color(0xFF0B4380);
  static const Color _border = Color(0xFFCDE1EC);
  static const Color _textDark = Color(0xFF102A43);
  static const Color _bodyText = Color(0xFF526579);
  static const Color _textSecondary = Color(0xFF8292A6);

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
        elevation: 0,
        centerTitle: true,
        backgroundColor: _titleBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'About',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _pageBg,
              _softBlue,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                const SizedBox(height: 22),
                _buildSectionTitle(
                  icon: Icons.visibility_rounded,
                  title: "RAM's VISION",
                  subtitle: 'Our Vision',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  'Remote Area Medical (RAM) is a non-profit organization dedicated to delivering essential medical aid to the world’s most remote and underserved communities. With a vision to provide high-quality, compassionate healthcare, RAM works to improve the quality of life for impoverished and isolated populations. Dr. Heidi Sampang, the founder and country manager of RAM Philippines, leads the organization’s efforts in the country, aiming to extend this mission to those who need it most.',
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  icon: Icons.menu_book_rounded,
                  title: "RAM's INFO",
                  subtitle: 'RAM Philippines',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  'RAM’s journey in the Philippines began in 2015, when it stepped in to assist in the aftermath of Typhoon Yolanda. Among the volunteers was Dr. Heidi Sampang, a pediatrician trained in New York, whose experience on the ground sparked a deep desire to make a lasting impact. Witnessing the urgent need for better healthcare, Dr. Sampang returned to the Philippines with a mission: to address the disparities in healthcare access across the country. Now named and officially affiliated under RAM, with a Global Health degree from Northwestern University, she founded RAM Philippines. In March 2017, the organization was formally registered with the Securities and Exchange Commission, solidifying its commitment to expanding healthcare services nationwide. Today, Dr. Sampang serves as the country manager of RAM, leading efforts to improve health outcomes for underserved communities across the Philippines.',
                ),
                const SizedBox(height: 20),
                _buildContactSection(),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_titleBlue, _blue, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _titleBlue.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: -28,
            child: Icon(
              Icons.add_rounded,
              size: 90,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: _titleBlue,
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'RAM PHILIPPINES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Remote Area Medical',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _lightBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 13),
              Container(
                height: 1,
                width: 54,
                color: Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bridging healthcare to remote and underserved communities.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _lightBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: _titleBlue,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          color: _bodyText,
          fontSize: 13,
          height: 1.65,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
            child: _buildSectionTitle(
              icon: Icons.phone_rounded,
              title: 'Contact Info',
              subtitle: 'Get in touch with RAM Philippines',
            ),
          ),
          _contactItem(
            icon: Icons.language_rounded,
            title: 'Website',
            value: 'Remote Area Medical Philippines',
            buttonLabel: 'Visit',
            buttonIcon: Icons.open_in_new_rounded,
            onTap: () => _openUrl(
              'https://www.facebook.com/RemoteAreaMedicalPhilippines/',
            ),
          ),
          const SizedBox(height: 8),
          _contactItem(
            icon: Icons.phone_rounded,
            title: 'Phone',
            value: '09999999999',
            buttonLabel: 'Call',
            buttonIcon: Icons.call_rounded,
            onTap: _openPhone,
          ),
          const SizedBox(height: 8),
          _contactItem(
            icon: Icons.location_on_rounded,
            title: 'Address',
            value: '#221B Baker St.',
            buttonLabel: null,
            buttonIcon: null,
            onTap: null,
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: _border,
          ),
          const SizedBox(height: 14),
          _buildFollowUs(),
        ],
      ),
    );
  }

  Widget _contactItem({
    required IconData icon,
    required String title,
    required String value,
    required String? buttonLabel,
    required IconData? buttonIcon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _border.withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: _lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _titleBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (buttonLabel != null && buttonIcon != null) ...[
            const SizedBox(width: 8),
            Material(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        buttonIcon,
                        color: _blue,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowUs() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: _lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: _titleBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follow Us',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Stay updated with our latest news and activities',
                      style: TextStyle(
                        color: _bodyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _socialCard(
                label: 'Facebook',
                icon: Icons.facebook_rounded,
                color: const Color(0xFF1877F2),
                onTap: () => _openUrl(
                  'https://www.facebook.com/RemoteAreaMedicalPhilippines/',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _socialCard(
                label: 'Instagram',
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFFE1306C),
                onTap: () => _openUrl('https://www.instagram.com/'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _socialCard(
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                color: const Color(0xFFEA4335),
                onTap: _openEmail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: _border,
        ),
        const SizedBox(height: 18),
        const Text(
          'RAMHIS',
          style: TextStyle(
            color: _textDark,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Version 1.0.0',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          '© 2025 RAM Philippines',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Healthcare Reaches Further',
          style: TextStyle(
            color: _blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
