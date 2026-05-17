import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'onboarding_cycle_screen.dart';
import 'widgets/gradient_button.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  void _goNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingCycleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // IMAGE SECTION
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/onboarding/onboarding1.png',
                    height: 380,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // TEXT SECTION
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Welcome to Femora',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: FemoraColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Welcome to Femora 💜 Track your wellness, care for your mental wellbeing, stay safe with SOS support, and chat with Femi, your personal AI companion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: FemoraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // BUTTON SECTION
              Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: GradientButton(
                  label: 'Get started →',
                  onTap: () => _goNext(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
