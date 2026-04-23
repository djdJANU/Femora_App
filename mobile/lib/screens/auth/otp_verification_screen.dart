import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_theme.dart';
import '../home/home_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  const OTPVerificationScreen({super.key, required this.email});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with SingleTickerProviderStateMixin {

  // Supabase sends exactly 6 digits — do not change this
  static const int _otpLength = 6;
  static const int _resendCooldown = 45;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isVerifying = false;
  bool _isResending = false;
  int _remainingSeconds = _resendCooldown;
  Timer? _resendTimer;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == _otpLength;
  bool get _canResend => _remainingSeconds == 0 && !_isResending;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _fadeController.dispose();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startResendTimer() {
    _remainingSeconds = _resendCooldown;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _formattedCountdown {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_isOtpComplete) {
      _dismissKeyboard();
      _onVerify();
    }
    setState(() {});
  }

  void _onOtpKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  Future<void> _onVerify() async {
    if (!_isOtpComplete || _isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        token: _otpCode,
        email: widget.email,
      );

      if (!mounted) return;

      final user = response.user;
      if (user == null) throw Exception('No user returned');

      // ── Profile handling ─────────────────────────────────────────────
      // Table: profiles
      // Columns confirmed: id, full_name, avatar_url, date_of_birth,
      //                    created_at, updated_at, onboarding_completed
      String userName = user.email?.split('@')[0] ?? 'User';

      try {
        final existing = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .eq('id', user.id)
            .maybeSingle();

        if (existing == null) {
          // First time user — create profile row
          await Supabase.instance.client.from('profiles').insert({
            'id': user.id,
            'full_name': userName,
            'created_at': DateTime.now().toIso8601String(),
            // updated_at uses DB default trigger
            // onboarding_completed defaults to false
          });
          debugPrint('✅ New profile created for: ${user.email}');
        } else {
          userName = existing['full_name'] ?? userName;
          // Update last seen
          await Supabase.instance.client
              .from('profiles')
              .update({'updated_at': DateTime.now().toIso8601String()})
              .eq('id', user.id);
          debugPrint('✅ Existing profile updated for: ${user.email}');
        }
      } catch (dbError) {
        // Don't block login if profile update fails
        debugPrint('⚠️ Profile update error (non-blocking): $dbError');
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(userName: userName)),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Welcome to Femora! 🌸',
            style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textLight)),
        backgroundColor: FemoraColors.success,
        behavior: SnackBarBehavior.floating,
      ));

    } on AuthException catch (e) {
      if (!mounted) return;
      String message = 'Verification failed';
      final err = e.message.toLowerCase();
      if (err.contains('invalid') || err.contains('expired')) {
        message = 'Invalid or expired code. Please try again.';
      } else if (err.contains('rate')) {
        message = 'Too many attempts. Please request a new code.';
      } else if (err.contains('not found')) {
        message = 'Code not found. Please request a new one.';
      }
      _showError(message);
      _clearOtp();

    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Verify error: $e');
      _showError('Something went wrong. Please try again.');
      _clearOtp();

    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _onResendOtp() async {
    if (!_canResend) return;
    setState(() => _isResending = true);

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: widget.email,
        emailRedirectTo: null,
      );
      if (!mounted) return;
      _clearOtp();
      _startResendTimer();
      _showSuccess('New code sent to ${widget.email}');

    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message.toLowerCase().contains('rate')
          ? 'Too many requests. Please wait.'
          : 'Could not resend code.');

    } catch (_) {
      if (!mounted) return;
      _showError('Could not resend. Check your connection.');

    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _clearOtp() {
    for (final c in _controllers) { c.clear(); }
    if (mounted) _focusNodes[0].requestFocus();
    setState(() {});
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg,
          style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textLight)),
      backgroundColor: FemoraColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg,
          style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textLight)),
      backgroundColor: FemoraColors.success,
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: FemoraColors.textPrimary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: FemoraSpacing.lg),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: FemoraSpacing.lg),
        Text(
          'Enter verification code',
          style: FemoraTextStyles.headlineLarge.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: FemoraSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Code sent to ',
                style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textSecondary)),
            Flexible(
              child: Text(
                widget.email,
                overflow: TextOverflow.ellipsis,
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: FemoraSpacing.xl),

        // ── 6 OTP boxes scaled to screen width ──────────────────────
        LayoutBuilder(builder: (context, constraints) {
          final boxSize = ((constraints.maxWidth - (FemoraSpacing.sm * 5)) / 6)
              .clamp(40.0, 56.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_otpLength, (i) {
              return Padding(
                padding: EdgeInsets.only(
                    right: i < _otpLength - 1 ? FemoraSpacing.sm : 0),
                child: _buildOtpBox(i, boxSize),
              );
            }),
          );
        }),
        const SizedBox(height: FemoraSpacing.xl),

        if (_canResend)
          TextButton(
            onPressed: _isResending ? null : _onResendOtp,
            child: _isResending
                ? SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: FemoraColors.primary))
                : Text('Resend code',
                    style: FemoraTextStyles.bodyMedium.copyWith(
                        color: FemoraColors.primary,
                        fontWeight: FontWeight.w600)),
          )
        else
          Text('Resend code in $_formattedCountdown',
              style: FemoraTextStyles.bodyMedium.copyWith(
                  color: FemoraColors.textSecondary)),
        const SizedBox(height: FemoraSpacing.xl),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_isOtpComplete && !_isVerifying) ? _onVerify : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: FemoraColors.primary,
              disabledBackgroundColor:
                  FemoraColors.primary.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)))
                : Text('Verify',
                    style: FemoraTextStyles.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: FemoraSpacing.lg),
      ],
    );
  }

  Widget _buildOtpBox(int index, double size) {
    final hasValue = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: size,
      height: size,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => _onOtpKeyEvent(index, event),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => _onOtpChanged(index, value),
          style: FemoraTextStyles.headlineLarge.copyWith(
              color: FemoraColors.textPrimary, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: FemoraColors.neutralLight)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: hasValue
                      ? FemoraColors.primary
                      : FemoraColors.neutralLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: FemoraColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}