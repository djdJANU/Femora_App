import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Tracker screen placeholder
/// This will be implemented with full period tracking functionality later
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: FemoraColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month,
                  size: 50,
                  color: FemoraColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Period Tracker',
                style: FemoraTextStyles.headlineLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Track your cycle, symptoms, and get personalized insights',
                  textAlign: TextAlign.center,
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Coming soon...',
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
