# Supabase OTP Implementation - Quick Reference

## Key Code Implementations

### 1. Email Auth Screen - Send OTP

```dart
// Location: _onSendOtp() method
Future<void> _onSendOtp() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;
  
  setState(() => _isLoading = true);
  
  try {
    final email = _emailController.text.trim();
    
    // ✅ Send OTP via Supabase Magic Link
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: null, // In-app verification
    );
    
    if (!mounted) return;
    
    // ✅ Navigate to OTP screen with email parameter
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: FemoraAnimations.normal,
        pageBuilder: (_, __, ___) => OTPVerificationScreen(email: email),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    
    // ✅ Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code sent to $email'),
        backgroundColor: FemoraColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on AuthException catch (e) {
    if (!mounted) return;
    
    // ✅ Map errors to user-friendly messages
    String message = 'Authentication failed';
    if (e.message.toLowerCase().contains('rate')) {
      message = 'Too many attempts. Please try again in a few minutes.';
    } else if (e.message.toLowerCase().contains('invalid email')) {
      message = 'Please enter a valid email address.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: FemoraColors.error)
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Something went wrong. Check your connection.'),
        backgroundColor: FemoraColors.error,
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

### 2. OTP Verification Screen - Verify OTP

```dart
// Location: _onVerify() method
Future<void> _onVerify() async {
  if (!_isOtpComplete || _isVerifying) return;
  
  setState(() => _isVerifying = true);
  
  try {
    final otp = _otpCode; // Combined 6-digit code
    
    // ✅ Verify OTP with Supabase
    final response = await Supabase.instance.client.auth.verifyOTP(
      type: OtpType.email,
      token: otp,
      email: widget.email,
    );
    
    if (!mounted) return;
    
    final user = response.user;
    if (user == null) throw Exception('Authentication failed');
    
    // ✅ Check if user profile exists in profiles table
    final existingProfile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    
    // ✅ Create profile if doesn't exist (fallback if trigger fails)
    if (existingProfile == null) {
      await Supabase.instance.client
          .from('profiles')
          .insert({
            'id': user.id,
            'full_name': user.email?.split('@')[0] ?? 'User',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } else {
      // ✅ Update login timestamp
      await Supabase.instance.client
          .from('profiles')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);
    }
    
    if (!mounted) return;
    
    // ✅ Navigate to HomeScreen (clear all routes)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    
    // ✅ Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome to Femora! 🌸'),
        backgroundColor: FemoraColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on AuthException catch (e) {
    if (!mounted) return;
    
    // ✅ Specific error messages
    String message = 'Verification failed';
    if (e.message.toLowerCase().contains('invalid') ||
        e.message.toLowerCase().contains('expired')) {
      message = 'Invalid or expired code. Please try again.';
    } else if (e.message.toLowerCase().contains('rate')) {
      message = 'Too many attempts. Request a new code.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: FemoraColors.error)
    );
    
    // ✅ Clear OTP on error
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    setState(() {});
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Something went wrong. Please try again.'),
        backgroundColor: FemoraColors.error,
      ),
    );
    
    // Clear OTP on error
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    setState(() {});
  } finally {
    if (mounted) setState(() => _isVerifying = false);
  }
}
```

---

### 3. OTP Verification Screen - Resend OTP

```dart
// Location: _onResendOtp() method
Future<void> _onResendOtp() async {
  if (!_canResend) return;
  
  setState(() => _isResending = true);
  
  try {
    // ✅ Resend OTP via Supabase
    await Supabase.instance.client.auth.signInWithOtp(
      email: widget.email,
      emailRedirectTo: null,
    );
    
    if (!mounted) return;
    
    // ✅ Clear input and reset countdown
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    _startResendTimer(); // Resets to 45 seconds
    
    // ✅ Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New code sent to ${widget.email}'),
        backgroundColor: FemoraColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on AuthException catch (e) {
    if (!mounted) return;
    
    String message = 'Could not resend code';
    if (e.message.toLowerCase().contains('rate')) {
      message = 'Too many requests. Please wait a moment.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: FemoraColors.error)
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not resend. Check your connection.'),
        backgroundColor: FemoraColors.error,
      ),
    );
  } finally {
    if (mounted) setState(() => _isResending = false);
  }
}
```

---

## Countdown Timer Implementation

```dart
// In initState()
void _startCountdown() {
  _countdown = 45;
  _timer?.cancel();
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    if (_countdown > 0) {
      setState(() => _countdown--);
    } else {
      timer.cancel();
    }
  });
}

// In dispose()
@override
void dispose() {
  _timer?.cancel();
  _otpControllers.forEach((c) => c.dispose());
  _focusNodes.forEach((f) => f.dispose());
  super.dispose();
}

// Resend button UI
TextButton(
  onPressed: (_isResending || _countdown > 0) ? null : _resendOtp,
  child: Text(_countdown > 0 
    ? 'Resend code in 00:${_countdown.toString().padLeft(2, '0')}'
    : 'Resend code'
  ),
)
```

---

## OTP Input Auto-Focus

```dart
// When user types in OTP box
void _onOtpChanged(int index, String value) {
  if (value.length == 1 && index < 5) {
    // ✅ Move to next box
    _focusNodes[index + 1].requestFocus();
  }
  
  // ✅ Auto-verify when all 6 digits filled
  if (_isOtpComplete) {
    _dismissKeyboard();
    _onVerify();
  }
  
  setState(() {});
}

// When backspace pressed on empty box
void _onOtpKeyEvent(int index, KeyEvent event) {
  if (event is KeyDownEvent &&
      event.logicalKey == LogicalKeyboardKey.backspace &&
      _controllers[index].text.isEmpty &&
      index > 0) {
    // ✅ Move to previous box
    _controllers[index - 1].clear();
    _focusNodes[index - 1].requestFocus();
    setState(() {});
  }
}
```

---

## Important Pattern: Mounted Check

Used EVERYWHERE after async operations to prevent errors:

```dart
// After async call, ALWAYS check mounted
if (!mounted) return;

// Then safe to call setState or show SnackBar
setState(() => _isLoading = false);
ScaffoldMessenger.of(context).showSnackBar(...);
```

---

## Database Query Examples

### Check if profile exists
```dart
final existingProfile = await Supabase.instance.client
    .from('profiles')
    .select()
    .eq('id', user.id)
    .maybeSingle(); // Returns null if not found (doesn't throw)
```

### Create new profile
```dart
await Supabase.instance.client
    .from('profiles')
    .insert({
      'id': user.id,
      'full_name': 'User',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
```

### Update profile
```dart
await Supabase.instance.client
    .from('profiles')
    .update({'updated_at': DateTime.now().toIso8601String()})
    .eq('id', user.id);
```

---

## Files Modified

| File | Changes |
|------|---------|
| `email_auth_screen.dart` | Added Supabase import, implemented full OTP sending with error handling |
| `otp_verification_screen.dart` | Added Supabase & HomeScreen imports, implemented OTP verification, profile handling, resend logic |

✅ **No new files created** - All logic integrated into existing screens
