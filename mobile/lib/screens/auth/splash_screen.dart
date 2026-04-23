import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_theme.dart';
import '../../providers/locale_provider.dart';
import '../onboarding/language_selection_screen.dart';
import '../onboarding/onboarding_welcome_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    // ── First launch → language not yet chosen ──────────────────────────────
    final localeProvider = context.read<LocaleProvider>();
    final hasLanguage = await localeProvider.hasChosenLanguage();
    if (!mounted) return;
    if (!hasLanguage) {
      _goTo(LanguageSelectionScreen(
        onLanguageSelected: () => _goTo(const OnboardingWelcomeScreen()),
      ));
      return;
    }

    final supabase = Supabase.instance.client;
    final localSession = supabase.auth.currentSession;

    // ── No session → new or logged out user ─────────────────────────────
    if (localSession == null) {
      debugPrint('🚀 No session → Onboarding');
      _goTo(const OnboardingWelcomeScreen());
      return;
    }

    // ── Session exists → validate it with Supabase ───────────────────────
    // A locally cached token can be expired. We must verify it.
    try {
      final refreshed = await supabase.auth.refreshSession();

      if (refreshed.session == null || refreshed.user == null) {
        debugPrint('⚠️ Session refresh returned null → clearing and going to Onboarding');
        await supabase.auth.signOut();
        if (!mounted) return;
        _goTo(const OnboardingWelcomeScreen());
        return;
      }

      final user = refreshed.user!;
      debugPrint('✅ Valid session: ${user.email}');

      // ── Verify profile exists in DB ─────────────────────────────────────
      // Table name: profiles (confirmed from Supabase dashboard)
      // Columns: id, full_name, avatar_url, date_of_birth, created_at,
      //          updated_at, onboarding_completed (added via SQL above)
      String userName = user.email?.split('@')[0] ?? 'User';

      try {
        final existing = await supabase
            .from('profiles')            // ← CORRECT table name
            .select('id, full_name')     // ← only columns that exist
            .eq('id', user.id)
            .maybeSingle();

        if (existing == null) {
          // Profile row missing — create it
          debugPrint('⚠️ No profile row found. Creating...');
          await supabase.from('profiles').insert({
            'id': user.id,
            'full_name': userName,
            'created_at': DateTime.now().toIso8601String(),
            // updated_at and onboarding_completed will use DB defaults
          });
        } else {
          userName = existing['full_name'] ?? userName;
          // Update last seen timestamp
          await supabase
              .from('profiles')
              .update({'updated_at': DateTime.now().toIso8601String()})
              .eq('id', user.id);
          debugPrint('✅ Profile found: $userName');
        }
      } catch (dbError) {
        // DB error must not block navigation
        debugPrint('⚠️ Profile DB error (non-blocking): $dbError');
      }

      if (!mounted) return;
      _goTo(HomeScreen(userName: userName));

    } on AuthException catch (e) {
      // Expired or invalid token
      debugPrint('❌ Auth exception: ${e.message}');
      await supabase.auth.signOut();
      if (!mounted) return;
      _goTo(const OnboardingWelcomeScreen());

    } catch (e) {
      // Network or unexpected error
      debugPrint('❌ Unexpected error during session check: $e');
      await supabase.auth.signOut();
      if (!mounted) return;
      _goTo(const OnboardingWelcomeScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/femora_logo.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Text(
                'Wellness designed for her',
                style: TextStyle(
                  fontSize: 14,
                  color: FemoraColors.textSecondary,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: FemoraColors.lavenderWhisper,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      FemoraColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}