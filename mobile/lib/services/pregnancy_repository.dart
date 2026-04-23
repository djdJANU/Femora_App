import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pregnancy_record.dart';
import '../config/supabase_config.dart';
import 'period_repository.dart';

/// Pregnancy Repository
/// All database operations for the pregnancy module.
class PregnancyRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final PeriodRepository _periodRepo = PeriodRepository();

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User not authenticated');
    return id;
  }

  // ── Create ─────────────────────────────────────────────────────────────

  /// Create a new pregnancy record.
  /// [lmpDate] — Last Menstrual Period.
  /// Due date is calculated as lmpDate + 280 days (Naegele's rule).
  Future<PregnancyRecord> createPregnancy({
    required DateTime lmpDate,
    String? babyName,
    String? babyGender,
  }) async {
    try {
      final dueDate = lmpDate.add(const Duration(days: 280));

      final response = await _supabase
          .from('pregnancy_records')
          .insert({
            'user_id': _userId,
            'lmp_date': lmpDate.toIso8601String().split('T')[0],
            'due_date': dueDate.toIso8601String().split('T')[0],
            'baby_name': babyName,
            'baby_gender': babyGender ?? 'unknown',
            'status': 'active',
          })
          .select()
          .single();

      return PregnancyRecord.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create pregnancy: $e');
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────

  /// Fetch the single active pregnancy for this user.
  /// Returns null if none exists.
  Future<PregnancyRecord?> getActivePregnancy() async {
    try {
      final response = await _supabase
          .from('pregnancy_records')
          .select()
          .eq('user_id', _userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? PregnancyRecord.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch active pregnancy: $e');
    }
  }

  /// Fetch all pregnancies for this user (history).
  Future<List<PregnancyRecord>> getAllPregnancies() async {
    try {
      final response = await _supabase
          .from('pregnancy_records')
          .select()
          .eq('user_id', _userId)
          .order('lmp_date', ascending: false);

      return (response as List)
          .map((j) => PregnancyRecord.fromJson(j))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pregnancy history: $e');
    }
  }

  /// Get a specific pregnancy by ID.
  Future<PregnancyRecord?> getPregnancyById(String id) async {
    try {
      final response = await _supabase
          .from('pregnancy_records')
          .select()
          .eq('id', id)
          .eq('user_id', _userId)
          .maybeSingle();

      return response != null ? PregnancyRecord.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch pregnancy: $e');
    }
  }

  // ── Auto-link from Period Tracker ──────────────────────────────────────

  /// Attempt to pre-fill LMP from the most recent confirmed period start.
  /// Returns null if no period history exists.
  Future<DateTime?> suggestLmpFromPeriodHistory() async {
    try {
      final cycles = await _periodRepo.fetchUserCycles(limit: 1);
      if (cycles.isEmpty) return null;
      // Use the start date of the most recent confirmed cycle
      final lastCycle = cycles.first;
      if (lastCycle.isConfirmed) return lastCycle.startDate;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────

  /// Update baby details (name, gender).
  Future<PregnancyRecord> updateBabyDetails({
    required String pregnancyId,
    String? babyName,
    String? babyGender,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (babyName != null) updates['baby_name'] = babyName;
      if (babyGender != null) updates['baby_gender'] = babyGender;

      final response = await _supabase
          .from('pregnancy_records')
          .update(updates)
          .eq('id', pregnancyId)
          .eq('user_id', _userId)
          .select()
          .single();

      return PregnancyRecord.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update baby details: $e');
    }
  }

  /// Mark pregnancy as completed (baby born).
  Future<PregnancyRecord> completePregnancy({
    required String pregnancyId,
    required DateTime birthDate,
  }) async {
    try {
      final response = await _supabase
          .from('pregnancy_records')
          .update({
            'status': 'completed',
            'actual_birth_date':
                birthDate.toIso8601String().split('T')[0],
          })
          .eq('id', pregnancyId)
          .eq('user_id', _userId)
          .select()
          .single();

      return PregnancyRecord.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete pregnancy: $e');
    }
  }

  // ── Daily Logs ─────────────────────────────────────────────────────────

  Future<PregnancyDailyLog> addDailyLog({
    required String pregnancyId,
    required DateTime logDate,
    required int weekNumber,
    String? mood,
    List<String>? symptoms,
    double? weightKg,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('pregnancy_daily_logs')
          .upsert(
            {
              'user_id': _userId,
              'pregnancy_id': pregnancyId,
              'log_date': logDate.toIso8601String().split('T')[0],
              'week_number': weekNumber,
              'mood': mood,
              'symptoms': symptoms ?? [],
              'weight_kg': weightKg,
              'notes': notes,
            },
            onConflict: 'pregnancy_id,log_date',
          )
          .select()
          .single();

      return PregnancyDailyLog.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add daily log: $e');
    }
  }

  Future<PregnancyDailyLog?> getDailyLog({
    required String pregnancyId,
    required DateTime date,
  }) async {
    try {
      final response = await _supabase
          .from('pregnancy_daily_logs')
          .select()
          .eq('pregnancy_id', pregnancyId)
          .eq('log_date', date.toIso8601String().split('T')[0])
          .maybeSingle();

      return response != null
          ? PregnancyDailyLog.fromJson(response)
          : null;
    } catch (e) {
      throw Exception('Failed to fetch daily log: $e');
    }
  }

  Future<List<PregnancyDailyLog>> getLogsForPregnancy(
      String pregnancyId) async {
    try {
      final response = await _supabase
          .from('pregnancy_daily_logs')
          .select()
          .eq('pregnancy_id', pregnancyId)
          .order('log_date', ascending: false);

      return (response as List)
          .map((j) => PregnancyDailyLog.fromJson(j))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch logs: $e');
    }
  }

  // ── Kick Counter ───────────────────────────────────────────────────────

  Future<KickLog> saveKickSession({
    required String pregnancyId,
    required int kickCount,
    required DateTime startedAt,
    required DateTime completedAt,
  }) async {
    try {
      final duration =
          completedAt.difference(startedAt).inMinutes;

      final response = await _supabase
          .from('pregnancy_kick_logs')
          .insert({
            'user_id': _userId,
            'pregnancy_id': pregnancyId,
            'session_date':
                startedAt.toIso8601String().split('T')[0],
            'kick_count': kickCount,
            'duration_minutes': duration,
            'started_at': startedAt.toIso8601String(),
            'completed_at': completedAt.toIso8601String(),
          })
          .select()
          .single();

      return KickLog.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save kick session: $e');
    }
  }

  Future<KickLog?> getTodaysKickLog(String pregnancyId) async {
    try {
      final today =
          DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from('pregnancy_kick_logs')
          .select()
          .eq('pregnancy_id', pregnancyId)
          .eq('session_date', today)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? KickLog.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  /// Delete a pregnancy and all associated data.
  Future<void> deletePregnancy({required String pregnancyId}) async {
    try {
      await _supabase
          .from('pregnancy_kick_logs')
          .delete()
          .eq('pregnancy_id', pregnancyId);

      await _supabase
          .from('pregnancy_daily_logs')
          .delete()
          .eq('pregnancy_id', pregnancyId);

      await _supabase
          .from('pregnancy_records')
          .delete()
          .eq('id', pregnancyId);
    } catch (e) {
      throw Exception('Failed to delete pregnancy: $e');
    }
  }
}
