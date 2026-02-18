// lib/screens/auth/splash_screen.dart
//
// Splash screen matching your Welcome_Screen.png design:
//   • White background (not purple)
//   • Centered Femora logo (woman silhouette in purple)
//   • "Femora" text in elegant script font
//   • "Wellness designed for her" tagline
//   • Purple loading progress bar at bottom

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _logoSlide;
  late Animation<double>   _progress;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2000),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve:  const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve:  const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve:  const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder:        (_, __, ___) => session != null
            ? const HomeScreen()
            : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background matching your design
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(
          children: [
            // Main content - centered
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: Transform.translate(
                  offset: Offset(0, _logoSlide.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo - woman silhouette
                      // Option A: If you have the PNG/SVG asset
                      Image.asset(
                        'assets/images/femora_logo.png',
                        width:  180,
                        height: 180,
                        errorBuilder: (_, __, ___) =>
                            // Fallback if image not found
                            _buildCustomLogo(),
                      ),

                      const SizedBox(height: 24),

                      // "Femora" wordmark - elegant script font
                      // Using a serif font to approximate your script design
                      const Text(
                        'Femora',
                        style: TextStyle(
                          fontFamily:    'Serif', // or 'Satisfy' if you add it
                          fontSize:      48,
                          fontWeight:    FontWeight.w400,
                          color:         Color(0xFF2D2140),
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Wellness designed for her',
                        style: TextStyle(
                          fontFamily:    'Nunito',
                          fontSize:      14,
                          fontWeight:    FontWeight.w300,
                          color:         FemoraColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading bar at bottom - matches your purple progress bar
            Positioned(
              left:   0,
              right:  0,
              bottom: 100,
              child:  Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:           _progress.value,
                        minHeight:       6,
                        backgroundColor: const Color(0xFFE5D9F2), // light purple
                        valueColor:      const AlwaysStoppedAnimation(
                          FemoraColors.primary, // solid purple
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback: Custom painted logo if asset is missing
  // This recreates your woman silhouette logo design
  Widget _buildCustomLogo() {
    return CustomPaint(
      size:    const Size(180, 180),
      painter: _FemoraLogoPainter(),
    );
  }
}

// Custom painter to recreate your Femora logo design
class _FemoraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style       = PaintStyle.stroke
      ..strokeWidth = 3
      ..color       = const Color(0xFF9B7EBD); // Femora purple

    final fillPaint = Paint()
      ..style = PaintStyle.fill
      ..color = const Color(0xFFE5D9F2).withOpacity(0.3); // light purple fill

    final center = Offset(size.width / 2, size.height / 2);
    final scale  = size.width / 180; // normalize to your design size

    // Background fill - pear shape body
    final fillPath = Path();
    fillPath.moveTo(center.dx, center.dy - 40 * scale);
    fillPath.quadraticBezierTo(
      center.dx - 35 * scale, center.dy - 20 * scale,
      center.dx - 40 * scale, center.dy + 10 * scale,
    );
    fillPath.quadraticBezierTo(
      center.dx - 42 * scale, center.dy + 40 * scale,
      center.dx - 25 * scale, center.dy + 55 * scale,
    );
    fillPath.lineTo(center.dx + 25 * scale, center.dy + 55 * scale);
    fillPath.quadraticBezierTo(
      center.dx + 42 * scale, center.dy + 40 * scale,
      center.dx + 40 * scale, center.dy + 10 * scale,
    );
    fillPath.quadraticBezierTo(
      center.dx + 35 * scale, center.dy - 20 * scale,
      center.dx, center.dy - 40 * scale,
    );
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Left curve - woman's left side silhouette
    final leftPath = Path();
    leftPath.moveTo(center.dx - 15 * scale, center.dy - 35 * scale);
    leftPath.quadraticBezierTo(
      center.dx - 28 * scale, center.dy - 15 * scale,
      center.dx - 32 * scale, center.dy + 5 * scale,
    );
    leftPath.quadraticBezierTo(
      center.dx - 34 * scale, center.dy + 30 * scale,
      center.dx - 20 * scale, center.dy + 50 * scale,
    );
    canvas.drawPath(leftPath, paint);

    // Right curve - woman's right side silhouette
    final rightPath = Path();
    rightPath.moveTo(center.dx + 15 * scale, center.dy - 35 * scale);
    rightPath.quadraticBezierTo(
      center.dx + 28 * scale, center.dy - 15 * scale,
      center.dx + 32 * scale, center.dy + 5 * scale,
    );
    rightPath.quadraticBezierTo(
      center.dx + 34 * scale, center.dy + 30 * scale,
      center.dx + 20 * scale, center.dy + 50 * scale,
    );
    canvas.drawPath(rightPath, paint);

    // Arm/scarf element - the flowing ribbon at top right
    final scarfPath = Path();
    scarfPath.moveTo(center.dx + 12 * scale, center.dy - 38 * scale);
    scarfPath.quadraticBezierTo(
      center.dx + 25 * scale, center.dy - 42 * scale,
      center.dx + 35 * scale, center.dy - 35 * scale,
    );
    scarfPath.quadraticBezierTo(
      center.dx + 38 * scale, center.dy - 30 * scale,
      center.dx + 36 * scale, center.dy - 25 * scale,
    );
    canvas.drawPath(scarfPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}