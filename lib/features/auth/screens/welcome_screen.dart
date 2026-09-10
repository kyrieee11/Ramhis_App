import 'package:flutter/material.dart';
import 'package:ramhis_app/features/auth/screens/signup_personal_info_screen.dart';

class WelcomeScreenWidget extends StatelessWidget {
  const WelcomeScreenWidget({super.key});

  static const _navy = Color(0xFF123F91);
  static const _navyDark = Color(0xFF082B6B);
  static const _gold = Color(0xFFD9C27A);
  static const _goldLight = Color(0xFFF1E2AE);
  static const _cream = Color(0xFFF7F1E2);
  static const _red = Color(0xFFB9232B);

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
            colors: [_navy, _navyDark],
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
                            color: _goldLight,
                            fontSize: isVerySmallHeight ? 16 : 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RAMHIS!',
                          style: TextStyle(
                            color: _goldLight,
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
                            color: _cream,
                            fontSize: isVerySmallHeight ? 15 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isVerySmallHeight ? 12 : 17),
                        _buildRoleButton(
                          title: 'Doctor',
                          subtitle: 'Access medical tools\nand patient records',
                          icon: Icons.medical_services_rounded,
                          accent: _red,
                          onTap: () => _navigate(context, 'doctor'),
                          compact: isSmallHeight,
                        ),
                        SizedBox(height: isVerySmallHeight ? 10 : 14),
                        _buildRoleButton(
                          title: 'Volunteer',
                          subtitle: 'Help and support\nyour community',
                          icon: Icons.volunteer_activism_rounded,
                          accent: _red,
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
                              foregroundColor: _goldLight,
                              side: const BorderSide(
                                color: _gold,
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
            color: _gold.withValues(alpha: opacity),
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
            color: _goldLight,
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
          color: _gold.withValues(alpha: 0.75),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _red,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 70,
          height: 1.5,
          color: _gold.withValues(alpha: 0.75),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: _gold.withValues(alpha: 0.48),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: _goldLight.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: _gold.withValues(alpha: 0.48),
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
        splashColor: _gold.withValues(alpha: 0.12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 15 : 18,
            vertical: compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE6D09A),
                Color(0xFFC5A967),
                Color(0xFFE2CD96),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _goldLight,
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 54 : 60,
                height: compact ? 54 : 60,
                decoration: BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF9D7D2F),
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
                        color: const Color(0xFF5B4620),
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF392F25),
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
                color: Color(0xFF6E592E),
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
