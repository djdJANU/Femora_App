import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ProfileProvider
/// Manages user profile data from the 'profiles' table.
/// 
/// Confirmed columns (from Supabase dashboard):
///   id, full_name, avatar_url, date_of_birth, created_at,
///   updated_at (added), onboarding_completed (added)
class ProfileProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;

  /// Convenience getters so UI doesn't need to cast everywhere
  String get fullName => _profile?['full_name'] ?? '';
  String? get avatarUrl => _profile?['avatar_url'];
  DateTime? get dateOfBirth {
    final dob = _profile?['date_of_birth'];
    if (dob == null) return null;
    return DateTime.tryParse(dob.toString());
  }
  bool get onboardingCompleted =>
      _profile?['onboarding_completed'] as bool? ?? false;

  /// Fetch profile from Supabase for a given user id
  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('profiles')               // ← confirmed table name
          .select(
            'id, full_name, avatar_url, date_of_birth, '
            'created_at, updated_at, onboarding_completed',
          )
          .eq('id', userId)
          .maybeSingle();                 // maybeSingle — won't throw if missing

      _profile = response;
    } catch (e) {
      debugPrint('❌ fetchProfile error: $e');
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile fields
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    DateTime? dateOfBirth,
    bool? onboardingCompleted,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (dateOfBirth != null) {
        // Store as DATE format: YYYY-MM-DD
        updates['date_of_birth'] =
            dateOfBirth.toIso8601String().split('T')[0];
      }
      if (onboardingCompleted != null) {
        updates['onboarding_completed'] = onboardingCompleted;
      }

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      // Refresh local copy
      await fetchProfile(userId);
    } catch (e) {
      debugPrint('❌ updateProfile error: $e');
      rethrow; // Let the UI handle and show the error
    }
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding(String userId) async {
    await updateProfile(
      userId: userId,
      onboardingCompleted: true,
    );
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}