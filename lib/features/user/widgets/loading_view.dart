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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        if (isLoading)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/ramhis_logo.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),

                  const SizedBox(height: 18),

                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}