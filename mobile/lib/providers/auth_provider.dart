import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthProvider
/// Listens to Supabase auth state changes reactively.
/// This is the single source of truth for authentication state in the app.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Step 1: Read existing session immediately on startup
    _user = _supabase.auth.currentUser;

    // Step 2: Listen to ALL future auth state changes reactively
    // This handles: sign in, sign out, token refresh, session expiry
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (AuthState data) {
        final event = data.event;
        final session = data.session;

        debugPrint('🔐 Auth Event: $event | User: ${session?.user.email}');

        _user = session?.user;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Auth Stream Error: $error');
        _user = null;
        notifyListeners();
      },
    );
  }

  /// Send OTP to email. Does NOT log the user in yet.
  Future<void> sendOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: null, // in-app OTP verification
    );
  }

  /// Sign out and clear local state.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // Stream listener above will handle setting _user = null
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}