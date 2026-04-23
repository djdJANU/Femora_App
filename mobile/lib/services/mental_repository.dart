// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// MentalRepository
/// ─────────────────
/// Handles all Supabase reads and writes for the Mental Wellbeing module.
/// No screen talks to Supabase directly — everything goes through here.
class MentalRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ── PHQ-2 ─────────────────────────────────────────────────────────────────

  /// Save a new PHQ-2 result
  Future<Map<String, dynamic>> savePHQ2Result({
    required int q1Score,
    required int q2Score,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('mental_phq2_results')
          .insert({
            'user_id': userId,
            'q1_score': q1Score,
            'q2_score': q2Score,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to save PHQ-2 result: $e');
    }
  }

  /// Get the most recent PHQ-2 result for the current user
  Future<Map<String, dynamic>?> getLatestPHQ2Result() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('mental_phq2_results')
          .select()
          .eq('user_id', userId)
          .order('taken_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Failed to get latest PHQ-2 result: $e');
      return null;
    }
  }

  /// Returns true if user needs to retake PHQ-2
  /// (never taken, or last taken more than 14 days ago)
  Future<bool> shouldShowPHQ2() async {
    try {
      final latest = await getLatestPHQ2Result();
      if (latest == null) return true;

      final takenAt = DateTime.parse(latest['taken_at']);
      final daysSince = DateTime.now().difference(takenAt).inDays;
      return daysSince >= 14;
    } catch (e) {
      return true;
    }
  }

  // ── Mood Logs ─────────────────────────────────────────────────────────────

  /// Save a mood log entry
  Future<Map<String, dynamic>> saveMoodLog({
    required String mood,
    String? note,
    int? cycleDay,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('mental_mood_logs')
          .insert({
            'user_id': userId,
            'mood': mood,
            'note': note,
            'cycle_day': cycleDay,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to save mood log: $e');
    }
  }

  /// Get mood logs for the last 7 days
  Future<List<Map<String, dynamic>>> getMoodLogsLast7Days() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final since = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('mental_mood_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', since.toIso8601String())
          .order('logged_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Failed to get mood logs: $e');
      return [];
    }
  }

  /// Get today's mood log if it exists
  Future<Map<String, dynamic>?> getTodayMoodLog() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      final response = await _supabase
          .from('mental_mood_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', todayStart.toIso8601String())
          .order('logged_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Failed to get today mood log: $e');
      return null;
    }
  }

  /// Returns the most frequent mood in the last 7 days
  /// Returns null if fewer than 7 logs exist
  Future<String?> getMoodInsight() async {
    try {
      final logs = await getMoodLogsLast7Days();
      if (logs.length < 7) return null;

      final counts = <String, int>{};
      for (final log in logs) {
        final mood = log['mood'] as String;
        counts[mood] = (counts[mood] ?? 0) + 1;
      }

      return counts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    } catch (e) {
      return null;
    }
  }

  // ── Sleep Logs ────────────────────────────────────────────────────────────

  /// Save or update a sleep log for a given date
  Future<Map<String, dynamic>> saveSleepLog({
    required DateTime sleepDate,
    required int sleepQuality,
    double? hoursSlept,
    String? note,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final dateStr = sleepDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('mental_sleep_logs')
          .upsert({
            'user_id': userId,
            'sleep_date': dateStr,
            'sleep_quality': sleepQuality,
            'hours_slept': hoursSlept,
            'note': note,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to save sleep log: $e');
    }
  }

  /// Get sleep logs for the last 7 days
  Future<List<Map<String, dynamic>>> getSleepLogsLast7Days() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final since = DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String()
          .split('T')[0];

      final response = await _supabase
          .from('mental_sleep_logs')
          .select()
          .eq('user_id', userId)
          .gte('sleep_date', since)
          .order('sleep_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Failed to get sleep logs: $e');
      return [];
    }
  }

  // ── Saved Articles ────────────────────────────────────────────────────────

  /// Save an article
  Future<void> saveArticle(String articleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('mental_saved_articles').upsert({
        'user_id': userId,
        'article_id': articleId,
      });
    } catch (e) {
      debugPrint('Failed to save article: $e');
    }
  }

  /// Unsave an article
  Future<void> unsaveArticle(String articleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('mental_saved_articles')
          .delete()
          .eq('user_id', userId)
          .eq('article_id', articleId);
    } catch (e) {
      debugPrint('Failed to unsave article: $e');
    }
  }

  /// Get all saved article IDs for the current user
  Future<List<String>> getSavedArticleIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('mental_saved_articles')
          .select('article_id')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response)
          .map((row) => row['article_id'] as String)
          .toList();
    } catch (e) {
      debugPrint('Failed to get saved articles: $e');
      return [];
    }
  }
}
