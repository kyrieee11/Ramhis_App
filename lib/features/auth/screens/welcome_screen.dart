import 'package:flutter/material.dart';
import 'package:ramhis_app/features/auth/screens/signup_personal_info_screen.dart';

class WelcomeScreenWidget extends StatelessWidget {
  const WelcomeScreenWidget({super.key});

  static const _primary = Color(0xFF10539B);
  static const _primaryDark = Color(0xFF0B4380);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _primarySoft = Color(0xFFEBF3FA);
  static const _background = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF102A43);
  static const _textSecondary = Color(0xFF526579);
  static const _textMuted = Color(0xFF8292A6);
  static const _border = Color(0xFFCDE1EC);
  static const _success = Color(0xFF22A06B);

  void _navigate(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupPersonalInformationWidget(accountType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height;
    final isSmallHeight = height < 760;
    final isVerySmallHeight = height < 680;

    final horizontalPadding = isSmallHeight ? 24.0 : 32.0;
    final verticalPadding = isVerySmallHeight
        ? 14.0
        : isSmallHeight
            ? 18.0
            : 26.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -95,
              right: -90,
              child: _backgroundRing(250, 0.07),
            ),
            Positioned(
              bottom: -125,
              left: -120,
              child: _backgroundRing(300, 0.045),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        Flexible(
                          flex: 2,
                          child: Center(
                            child: _buildLogo(
                              isSmallHeight: isSmallHeight,
                              isVerySmallHeight: isVerySmallHeight,
                            ),
                          ),
                        ),
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            color: _primaryLight,
                            fontSize: isVerySmallHeight ? 16 : 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RAMHIS!',
                          style: TextStyle(
                            color: _primaryLight,
                            fontSize: isVerySmallHeight ? 37 : 43,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isVerySmallHeight ? 10 : 15),
                        _buildDividerDot(),
                        SizedBox(height: isVerySmallHeight ? 11 : 16),
                        Text(
                          'How would you like to continue?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _background,
                            fontSize: isVerySmallHeight ? 15 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isVerySmallHeight ? 12 : 17),
                        _buildRoleButton(
                          title: 'Doctor',
                          subtitle: 'Access medical tools\nand patient records',
                          icon: Icons.medical_services_rounded,
                          accent: _primary,
                          onTap: () => _navigate(context, 'doctor'),
                          compact: isSmallHeight,
                        ),
                        SizedBox(height: isVerySmallHeight ? 10 : 14),
                        _buildRoleButton(
                          title: 'Volunteer',
                          subtitle: 'Help and support\nyour community',
                          icon: Icons.volunteer_activism_rounded,
                          accent: _primary,
                          onTap: () => _navigate(context, 'volunteer'),
                          compact: isSmallHeight,
                        ),
                        SizedBox(height: isVerySmallHeight ? 10 : 15),
                        _buildOrDivider(),
                        SizedBox(height: isVerySmallHeight ? 9 : 14),
                        SizedBox(
                          width: 230,
                          height: isSmallHeight ? 47 : 52,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                            ),
                            label: const Text('Back to Login'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryLight,
                              side: const BorderSide(
                                color: _border,
                                width: 1.5,
                              ),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: TextStyle(
                                fontSize: isSmallHeight ? 14 : 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundRing(double size, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _primaryLight.withValues(alpha: opacity),
            width: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({
    required bool isSmallHeight,
    required bool isVerySmallHeight,
  }) {
    return SizedBox(
      width: isVerySmallHeight
          ? 120
          : isSmallHeight
              ? 140
              : 165,
      height: isVerySmallHeight
          ? 75
          : isSmallHeight
              ? 88
              : 105,
      child: Image.asset(
        'assets/images/ramhis_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.health_and_safety_rounded,
            size: 70,
            color: _primaryLight,
          );
        },
      ),
    );
  }

  Widget _buildDividerDot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 1.5,
          color: _border.withValues(alpha: 0.75),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 70,
          height: 1.5,
          color: _border.withValues(alpha: 0.75),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: _border.withValues(alpha: 0.48),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: _primaryLight.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: _border.withValues(alpha: 0.48),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    required bool compact,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: _border.withValues(alpha: 0.12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 15 : 18,
            vertical: compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _primaryDark,
                _primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _primaryLight,
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 54 : 60,
                height: compact ? 54 : 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _border,
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: compact ? 30 : 34,
                ),
              ),
              SizedBox(width: compact ? 15 : 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 14,
                        height: 1.28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
