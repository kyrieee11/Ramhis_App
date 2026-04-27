import 'package:flutter/material.dart';
import 'signup_personal_information.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 800;

    return Scaffold(
      body: Container(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 34 : 28,
                    vertical: isWide ? 42 : 36,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4167D4).withValues(alpha:0.88),
                    borderRadius: BorderRadius.circular(42),
                    border: Border.all(
                      color: Colors.white.withValues(alpha:0.22),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.25),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 22),
                      const Text(
                        'Welcome to',
                        style: TextStyle(
                          color: Color(0xFFEAF0FF),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'RAMHIS!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDividerDot(),
                      const SizedBox(height: 22),
                      const Text(
                        'How would you like to continue?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFEAF0FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),

                      _buildRoleButton(
                        title: 'Doctor',
                        subtitle: 'Access medical tools\nand patient records',
                        icon: Icons.medical_services_rounded,
                        color: const Color(0xFFF05261),
                        onTap: () => _navigate(context, 'doctor'),
                      ),

                      const SizedBox(height: 18),

                      _buildRoleButton(
                        title: 'Volunteer',
                        subtitle: 'Help and support\nyour community',
                        icon: Icons.volunteer_activism_rounded,
                        color: const Color(0xFF4E75E8),
                        onTap: () => _navigate(context, 'volunteer'),
                      ),

                      const SizedBox(height: 28),
                      _buildOrDivider(),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: 230,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to Login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 210,
      height: 130,
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
        Expanded(child: Divider(color: Colors.white.withValues(alpha:0.35))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.65),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha:0.35))),
      ],
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha:0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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