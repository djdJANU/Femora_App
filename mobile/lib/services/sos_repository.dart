import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// SosRepository
/// ─────────────
/// Handles all Supabase reads and writes for the SOS Safety module.
/// No screen talks to Supabase directly — everything goes through here.
class SosRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ── Emergency Contacts ────────────────────────────────────────────────────

  /// Get all emergency contacts for the current user, oldest first
  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('sos_emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SosRepository.getEmergencyContacts error: $e');
      return [];
    }
  }

  /// Add a new emergency contact.
  /// Throws if the user already has 3 contacts.
  Future<Map<String, dynamic>> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Enforce max 3 contacts at the repository level
    final existing = await _supabase
        .from('sos_emergency_contacts')
        .select('id')
        .eq('user_id', userId);

    if (existing.length >= 3) {
      throw Exception('Maximum 3 emergency contacts allowed');
    }

    try {
      final response = await _supabase
          .from('sos_emergency_contacts')
          .insert({
            'user_id': userId,
            'name': name,
            'phone_number': phoneNumber,
            'relationship': relationship,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

  /// Update an existing emergency contact by id
  Future<Map<String, dynamic>> updateContact({
    required String id,
    required String name,
    required String phoneNumber,
    required String relationship,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('sos_emergency_contacts')
          .update({
            'name': name,
            'phone_number': phoneNumber,
            'relationship': relationship,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  /// Delete an emergency contact by id
  Future<void> deleteContact(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('sos_emergency_contacts')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('SosRepository.deleteContact error: $e');
    }
  }

  // ── Trigger Logging ───────────────────────────────────────────────────────

  /// Log an SOS trigger attempt. Never throws — SOS send must not be blocked.
  Future<void> logTrigger({
    required String triggerMethod,
    double? latitude,
    double? longitude,
    required List<String> contactsAlerted,
    required bool wasCancelled,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('sos_trigger_logs').insert({
        'user_id': userId,
        'triggered_at': DateTime.now().toUtc().toIso8601String(),
        'trigger_method': triggerMethod,
        'latitude': latitude,
        'longitude': longitude,
        'contacts_alerted': contactsAlerted,
        'was_cancelled': wasCancelled,
      });
    } catch (e) {
      // Non-critical — log and continue
      debugPrint('SosRepository.logTrigger error (non-blocking): $e');
    }
  }
}
