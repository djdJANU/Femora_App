import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../auth/email_auth_screen.dart';
import 'widgets/gradient_button.dart';

class OnboardingPregnancyScreen extends StatelessWidget {
  const OnboardingPregnancyScreen({super.key});

  void _goNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
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

              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/onboarding/onboarding3.png',
                    height: 380,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Track your pregnancy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: FemoraColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'oyata puluwm dn lesiyenma oyge mewwa eka track kr gnna apen wage mona hri dnn',
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