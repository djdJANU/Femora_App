import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/period_cycle.dart';
import '../models/period_daily_log.dart';
import '../config/supabase_config.dart';

/// Period Repository
/// Handles all period-related data operations with Supabase
class PeriodRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Create or confirm a new cycle
  Future<PeriodCycle> createOrConfirmCycle({
    required DateTime startDate,
    bool isConfirmed = true,
    bool isPredicted = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('period_cycles')
          .insert({
            'user_id': userId,
            'start_date': startDate.toIso8601String().split('T')[0],
            'is_confirmed': isConfirmed,
            'is_predicted': isPredicted,
          })
          .select()
          .single();

      return PeriodCycle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create cycle: $e');
    }
  }

  /// Add a daily log entry
  Future<PeriodDailyLog> addDailyLog({
    required DateTime logDate,
    String? cycleId,
    String? flowLevel,
    int? painLevel,
    List<String>? symptoms,
    bool hasSpotting = false,
    String? notes,
    String? mood,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint("Checking for active cycle...");

      PeriodCycle? activeCycle = await getCurrentCycle();

      debugPrint("Active cycle found: ${activeCycle?.id}");

      if (activeCycle == null) {
        debugPrint("No active cycle found. Creating new cycle...");
        activeCycle = await createOrConfirmCycle(startDate: logDate);
        debugPrint("New cycle created: ${activeCycle.id}");
      }

      final response = await _supabase
          .from('period_daily_logs')
          .insert({
            'user_id': userId,
            'cycle_id': activeCycle.id,
            'log_date': logDate.toIso8601String().split('T')[0],
            'flow_level': flowLevel,
            'pain_level': painLevel,
            'symptoms': symptoms ?? [],
            'has_spotting': hasSpotting,
            'notes': notes,
            'mood': mood,
          })
          .select()
          .single();

      return PeriodDailyLog.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add daily log: $e');
    }
  }

  /// Update an existing daily log
  Future<PeriodDailyLog> updateDailyLog({
    required String logId,
    String? flowLevel,
    int? painLevel,
    List<String>? symptoms,
    bool? hasSpotting,
    String? notes,
    String? mood,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (flowLevel != null) updates['flow_level'] = flowLevel;
      if (painLevel != null) updates['pain_level'] = painLevel;
      if (symptoms != null) updates['symptoms'] = symptoms;
      if (hasSpotting != null) updates['has_spotting'] = hasSpotting;
      if (notes != null) updates['notes'] = notes;
      if (mood != null) updates['mood'] = mood;

      final response = await _supabase
          .from('period_daily_logs')
          .update(updates)
          .eq('id', logId)
          .select()
          .single();

      return PeriodDailyLog.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update daily log: $e');
    }
  }

  /// Delete a daily log
  Future<void> deleteDailyLog(String logId) async {
    try {
      await _supabase.from('period_daily_logs').delete().eq('id', logId);
    } catch (e) {
      throw Exception('Failed to delete daily log: $e');
    }
  }

  /// Fetch all cycles for the current user
  Future<List<PeriodCycle>> fetchUserCycles({int limit = 12}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('period_cycles')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PeriodCycle.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cycles: $e');
    }
  }

  /// Fetch daily logs for a specific cycle
  Future<List<PeriodDailyLog>> fetchDailyLogsForCycle(String cycleId) async {
    try {
      final response = await _supabase
          .from('period_daily_logs')
          .select()
          .eq('cycle_id', cycleId)
          .order('log_date', ascending: true);

      return (response as List)
          .map((json) => PeriodDailyLog.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch daily logs: $e');
    }
  }

  /// Fetch daily logs for a date range
  Future<List<PeriodDailyLog>> fetchDailyLogsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('period_daily_logs')
          .select()
          .eq('user_id', userId)
          .gte('log_date', startDate.toIso8601String().split('T')[0])
          .lte('log_date', endDate.toIso8601String().split('T')[0])
          .order('log_date', ascending: true);

      return (response as List)
          .map((json) => PeriodDailyLog.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch daily logs for date range: $e');
    }
  }

  /// Get daily log for a specific date
  Future<PeriodDailyLog?> getDailyLogForDate(DateTime date) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('period_daily_logs')
          .select()
          .eq('user_id', userId)
          .eq('log_date', date.toIso8601String().split('T')[0])
          .maybeSingle();

      return response != null ? PeriodDailyLog.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch daily log for date: $e');
    }
  }

  /// Calculate cycle length between two dates
  int calculateCycleLength(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays;
  }

  /// Detect if a new cycle should be started with confirmation
  Future<bool> detectNewCycleWithConfirmation(DateTime newPeriodDate) async {
    try {
      final cycles = await fetchUserCycles(limit: 1);
      if (cycles.isEmpty) return true; // First cycle, no confirmation needed

      final lastCycle = cycles.first;
      final daysSinceLastCycle = newPeriodDate
          .difference(lastCycle.startDate)
          .inDays;

      // If >= 21 days from last cycle, require confirmation
      return daysSinceLastCycle >= 21;
    } catch (e) {
      throw Exception('Failed to detect new cycle: $e');
    }
  }

  /// Update cycle end date and calculate cycle length
  Future<PeriodCycle> updateCycleEnd({
    required String cycleId,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('period_cycles')
          .select()
          .eq('id', cycleId)
          .single();

      final cycle = PeriodCycle.fromJson(response);
      final cycleLength = calculateCycleLength(cycle.startDate, endDate);

      final updated = await _supabase
          .from('period_cycles')
          .update({
            'end_date': endDate.toIso8601String().split('T')[0],
            'cycle_length': cycleLength,
          })
          .eq('id', cycleId)
          .select()
          .single();

      return PeriodCycle.fromJson(updated);
    } catch (e) {
      throw Exception('Failed to update cycle end: $e');
    }
  }

  /// Update bleeding days for a cycle
  Future<PeriodCycle> updateBleedingDays({
    required String cycleId,
    required int bleedingDays,
  }) async {
    try {
      final response = await _supabase
          .from('period_cycles')
          .update({'bleeding_days': bleedingDays})
          .eq('id', cycleId)
          .select()
          .single();

      return PeriodCycle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update bleeding days: $e');
    }
  }

  /// Get the current active cycle (most recent unended cycle)
  Future<PeriodCycle?> getCurrentCycle() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('period_cycles')
          .select()
          .eq('user_id', userId)
          .isFilter('end_date', null)
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? PeriodCycle.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get current cycle: $e');
    }
  }
  // ── METHOD 1 ── Delete cycle + all its daily logs (RLS-safe) ─────────────
  Future<void> deleteCycle(String cycleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
 
      // ── Step 1: delete every daily log for this cycle ──────────────────
      // IMPORTANT: include user_id so Supabase RLS authorises the DELETE.
      // Without user_id, RLS silently prevents deletion (0 rows affected,
      // no error thrown), leaving dots visible on the calendar.
      await _supabase
          .from('period_daily_logs')
          .delete()
          .eq('cycle_id', cycleId)
          .eq('user_id', userId);   // ← RLS fix
 
      // ── Step 2: delete the cycle row itself ────────────────────────────
      await _supabase
          .from('period_cycles')
          .delete()
          .eq('id', cycleId)
          .eq('user_id', userId);   // ← belt-and-braces for RLS
    } catch (e) {
      throw Exception('Failed to delete cycle: $e');
    }
  }
 
  // ── METHOD 2 ── Update the start date of a cycle ──────────────────────────
  Future<PeriodCycle> updateCycleStartDate({
    required String cycleId,
    required DateTime newStartDate,
  }) async {
    try {
      final updated = await _supabase
          .from('period_cycles')
          .update({
            'start_date': newStartDate.toIso8601String().split('T')[0],
            'cycle_length': null,
          })
          .eq('id', cycleId)
          .select()
          .single();
 
      return PeriodCycle.fromJson(updated);
    } catch (e) {
      throw Exception('Failed to update cycle start date: $e');
    }
  }
 
  // ── METHOD 3 ── Re-open a completed cycle ─────────────────────────────────
  Future<PeriodCycle> reopenCycle(String cycleId) async {
    try {
      final updated = await _supabase
          .from('period_cycles')
          .update({
            'end_date': null,
            'cycle_length': null,
            'bleeding_days': null,
          })
          .eq('id', cycleId)
          .select()
          .single();
 
      return PeriodCycle.fromJson(updated);
    } catch (e) {
      throw Exception('Failed to reopen cycle: $e');
    }
  }
 
  // ── METHOD 4 ── Get the most recently COMPLETED cycle ─────────────────────
  Future<PeriodCycle?> getLastCompletedCycle() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
 
      final response = await _supabase
          .from('period_cycles')
          .select()
          .eq('user_id', userId)
          .not('end_date', 'is', null)
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();
 
      return response != null ? PeriodCycle.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }
}
