import 'package:flutter/material.dart';

class LogoLoadingOverlay extends StatelessWidget {
  const LogoLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = 'Loading...',
  });

  final bool isLoading;
  final Widget child;
  final String message;

  static const Color _kPrimary = Color(0xFF10539B);
  static const Color _kPrimaryDark = Color(0xFF0B4380);
  static const Color _kBlue = Color(0xFF1863B5);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kPrimary,
                    _kBlue,
                    _kPrimaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/ramhis_logo.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 26),

                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        decoration: TextDecoration.none,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Please wait...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}