import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccAboutWidget extends StatelessWidget {
  const AccAboutWidget({super.key});

  static const Color _pageBg = Color(0xFFF5F5F7);
  static const Color _cardBg = Colors.white;
  static const Color _softBlue = Color(0xFFD9ECFF);
  static const Color _titleBlue = Color(0xFF3F5FBE);
  static const Color _textDark = Color(0xFF2D2D2D);

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
        backgroundColor: _pageBg,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'About',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopClose(context),
                    const SizedBox(height: 6),
                    _buildHeading('RAM’s VISION'),
                    const SizedBox(height: 8),
                    _buildTextBlock(
                      smallTitle: 'Our Vision',
                      text:
                          'Remote Area Medical (RAM) is a non-profit organization dedicated to delivering essential medical aid to the world’s most remote and underserved communities. With a vision to provide high-quality, compassionate healthcare, RAM works to improve the quality of life for impoverished and isolated populations. Dr. Heidi Sampang, the founder and country manager of RAM Philippines, leads the organization’s efforts in the country, aiming to extend this mission to those who need it most.',
                    ),
                    const SizedBox(height: 12),
                    _buildHeading('RAM’s INFO'),
                    const SizedBox(height: 8),
                    _buildTextBlock(
                      smallTitle: 'RAM Philippines',
                      text:
                          'RAM’s journey in the Philippines began in 2015, when it stepped in to assist in the aftermath of Typhoon Yolanda. Among the volunteers was Dr. Heidi Sampang, a pediatrician trained in New York, whose experience on the ground sparked a deep desire to make a lasting impact. Witnessing the urgent need for better healthcare, Dr. Sampang returned to the Philippines with a mission: to address the disparities in healthcare access across the country. Now named and officially affiliated under RAM, with a Global Health degree from Northwestern University, she founded RAM Philippines. In March 2017, the organization was formally registered with the Securities and Exchange Commission, solidifying its commitment to expanding healthcare services nationwide. Today, Dr. Sampang serves as the country manager of RAM, leading efforts to improve health outcomes for underserved communities across the Philippines.',
                    ),
                    const SizedBox(height: 14),
                    _buildHeading('Contact Info'),
                    const SizedBox(height: 8),
                    _buildContactPanel(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopClose(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFE45C63),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _titleBlue,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextBlock({
    required String smallTitle,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            smallTitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
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
          const SizedBox(height: 12),
          _contactRow(
            leftIcon: Icons.phone,
            leftLabel: '09999999999',
            onLeftTap: _openPhone,
            rightWidget: _socialLink(
              label: 'Instagram',
              bgColor: const Color(0xFFE1306C),
              icon: Icons.camera_alt,
              onTap: () => _openUrl('https://www.instagram.com/'),
            ),
          ),
          const SizedBox(height: 12),
          _contactRow(
            leftIcon: Icons.location_on,
            leftLabel: '#221B Baker St.',
            rightWidget: _socialLink(
              label: 'Email',
              bgColor: const Color(0xFFEA4335),
              icon: Icons.mail,
              onTap: _openEmail,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData leftIcon,
    required String leftLabel,
    VoidCallback? onLeftTap,
    required Widget rightWidget,
  }) {
    final leftSide = Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFF2E95F4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            leftIcon,
            color: Colors.white,
            size: 11,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            leftLabel,
            style: const TextStyle(
              fontSize: 11,
              color: _textDark,
              fontWeight: FontWeight.w500,
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
                  borderRadius: BorderRadius.circular(8),
                  child: leftSide,
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
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: _textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 11,
            ),
          ),
        ],
      ),
    );
  }
}