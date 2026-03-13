import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class SplashOverlay extends StatelessWidget {
  final bool isDarkMode;
  final Animation<double> fadeAnimation;

  const SplashOverlay({
    super.key,
    required this.isDarkMode,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: ReverseAnimation(fadeAnimation),
      child: Container(
        color: isDarkMode ? AppConstants.darkBackground : Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // DAMO wordmark with purple dot accent on O
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'DAMO',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : const Color(0xFF2D2D2D),
                      letterSpacing: 5,
                    ),
                  ),
                  // Purple dot above O
                  Positioned(
                    right: 7,
                    top: -10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppConstants.accentPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Divider line
              Container(
                width: 80,
                height: 1,
                color: isDarkMode ? AppConstants.darkBorder : AppConstants.lightBorder,
              ),
              const SizedBox(height: 16),
              const Text(
                'SEARCH EVERYTHING',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppConstants.accentLightPurple,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppConstants.accentPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
