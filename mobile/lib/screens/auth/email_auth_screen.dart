import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_theme.dart';
import 'otp_verification_screen.dart';

/// Email authentication screen — first step of the OTP / magic-link flow.
///
/// Collects a valid email address, shows a loading state while the OTP is
/// (conceptually) being sent, then navigates to [OTPVerificationScreen].
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers & keys ────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isEmailValid = false;

  // ── Fade-in animation ─────────────────────────────────────────────────────
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // ── Email regex (simple RFC 5322 subset) ──────────────────────────────────
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$',
  );

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: FemoraAnimations.easeOut,
    );
    _fadeController.forward();

    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _onEmailChanged() {
    final valid = _emailRegex.hasMatch(_emailController.text.trim());
    if (valid != _isEmailValid) {
      setState(() => _isEmailValid = valid);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Sends OTP via Supabase and navigates to the verification screen.
  Future<void> _onSendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // Send OTP via Supabase Magic Link
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // We'll verify in-app
      );

      if (!mounted) return;

      // Navigate to OTP verification screen
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: FemoraAnimations.normal,
          pageBuilder: (context, animation, child) =>
              OTPVerificationScreen(email: email),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );

      // Show success feedback
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Code sent to $email',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textLight,
            ),
          ),
          backgroundColor: FemoraColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      debugPrint('⚠️ Supabase OTP Error: ${e.message}');

      String message = e.message; // Show actual error by default

      // Map common errors to user-friendly messages
      final errorLower = e.message.toLowerCase();
      if (errorLower.contains('rate')) {
        message = 'Too many attempts. Please try again in a few minutes.';
      } else if (errorLower.contains('invalid email') ||
          errorLower.contains('invalid_identifier')) {
        message = 'Please enter a valid email address.';
      } else if (errorLower.contains('already registered') ||
          errorLower.contains('email already exists')) {
        message = 'This email is already registered.';
      } else if (errorLower.contains('no rows') ||
          errorLower.contains('not found')) {
        message = 'Unable to process request. Try again.';
      } else if (errorLower.contains('mfa') ||
          errorLower.contains('unauthorized')) {
        message = 'Authentication is not available. Contact support.';
      } else if (errorLower.contains('invalid_grant')) {
        message = 'Invalid credentials. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textLight,
            ),
          ),
          backgroundColor: FemoraColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('⚠️ Unexpected Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong. Please check your internet connection and try again.',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textLight,
            ),
          ),
          backgroundColor: FemoraColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Dismiss the keyboard when tapping outside input fields.
  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: FemoraSpacing.lg,
                ),
                child: _buildCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: FemoraSpacing.lg,
        vertical: FemoraSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FemoraBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo ────────────────────────────────────────────────────
            Image.asset(
              'assets/images/femora_logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: FemoraSpacing.lg),

            // ── Title ───────────────────────────────────────────────────
            Text(
              'Welcome back 👋',
              style: FemoraTextStyles.headlineLarge.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FemoraSpacing.sm),

            // ── Subtitle ────────────────────────────────────────────────
            Text(
              'Enter your email to sign in',
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textSecondary,
              ),
            ),
            const SizedBox(height: FemoraSpacing.xl),

            // ── Email field ─────────────────────────────────────────────
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: true,
              inputFormatters: [
                // Prevent whitespace in email input
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              validator: _validateEmail,
              onFieldSubmitted: (_) {
                if (_isEmailValid) _onSendOtp();
              },
              style: FemoraTextStyles.bodyLarge.copyWith(
                color: FemoraColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: FemoraTextStyles.bodyLarge.copyWith(
                  color: FemoraColors.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: FemoraColors.textSecondary,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: FemoraSpacing.md,
                  vertical: FemoraSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: FemoraColors.neutralLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: FemoraColors.neutralLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: FemoraColors.primary,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: FemoraColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: FemoraColors.error,
                    width: 1.5,
                  ),
                ),
                errorStyle: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.error,
                ),
              ),
            ),
            const SizedBox(height: FemoraSpacing.lg),

            // ── Send OTP button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isEmailValid && !_isLoading) ? _onSendOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemoraColors.primary,
                  disabledBackgroundColor: FemoraColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Send OTP',
                        style: FemoraTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: FemoraSpacing.md),

            // ── Footer hint ─────────────────────────────────────────────
            Text(
              "You'll receive a 6-digit code",
              style: FemoraTextStyles.caption.copyWith(
                color: FemoraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
