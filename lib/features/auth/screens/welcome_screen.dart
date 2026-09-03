import 'package:flutter/material.dart';
import 'package:ramhis_app/features/auth/screens/signup_personal_info_screen.dart';

class WelcomeScreenWidget extends StatelessWidget {
  const WelcomeScreenWidget({super.key});

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

    final bool isSmallHeight = height < 760;
    final bool isVerySmallHeight = height < 680;

    final double horizontalPadding = isSmallHeight ? 24 : 32;
    final double verticalPadding = isVerySmallHeight
        ? 16
        : isSmallHeight
            ? 20
            : 28;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4169D8),
              Color(0xFF234AB3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      flex: 2,
                      child: _buildLogo(
                        isSmallHeight: isSmallHeight,
                        isVerySmallHeight: isVerySmallHeight,
                      ),
                    ),

                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Color(0xFFEAF0FF),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Text(
                      'RAMHIS!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isVerySmallHeight ? 34 : 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),

                    _buildDividerDot(),

                    const Text(
                      'How would you like to continue?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFEAF0FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    _buildRoleButton(
                      title: 'Doctor',
                      subtitle:
                          'Access medical tools\nand patient records',
                      icon: Icons.medical_services_rounded,
                      color: const Color(0xFFF05261),
                      onTap: () => _navigate(context, 'doctor'),
                      compact: isSmallHeight,
                    ),

                    _buildRoleButton(
                      title: 'Volunteer',
                      subtitle:
                          'Help and support\nyour community',
                      icon: Icons.volunteer_activism_rounded,
                      color: const Color(0xFF4E75E8),
                      onTap: () =>
                          _navigate(context, 'volunteer'),
                      compact: isSmallHeight,
                    ),

                    _buildOrDivider(),

                    SizedBox(
                      width: 230,
                      height: isSmallHeight ? 46 : 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                        ),
                        label: const Text('Back to Login'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                          textStyle: TextStyle(
                            fontSize:
                                isSmallHeight ? 14 : 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
          ? 130
          : isSmallHeight
              ? 150
              : 180,
      height: isVerySmallHeight
          ? 80
          : isSmallHeight
              ? 90
              : 110,
      child: Image.asset(
        'assets/images/ramhis_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.health_and_safety_rounded,
            size: 80,
            color: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildDividerDot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 70, height: 2, color: Colors.white38),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFF05261),
            shape: BoxShape.circle,
          ),
        ),
        Container(width: 70, height: 2, color: Colors.white38),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool compact,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 12 : 18,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 48 : 58,
                height: compact ? 48 : 58,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: compact ? 25 : 30,
                ),
              ),
              SizedBox(width: compact ? 14 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 19 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 14,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}