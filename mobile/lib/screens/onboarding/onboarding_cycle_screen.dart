import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../onboarding/onboarding_pregnancy_screen.dart';
import 'widgets/gradient_button.dart';

class OnboardingCycleScreen extends StatelessWidget {
  const OnboardingCycleScreen({super.key});

  void _goNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingPregnancyScreen()),
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
                    'assets/images/onboarding/onboarding2.png',
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
                      'Track your cycle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: FemoraColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'oyata puluwm dn lesiyenma oyge cycle eka track kr gnna apen wage mona hri dnn',
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
                  label: 'Next →',
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