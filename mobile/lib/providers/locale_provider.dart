import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

/// LocaleProvider
/// ──────────────
/// Manages the user's chosen locale across the app.
/// Persists to SharedPreferences (instant load on next launch)
/// and syncs to Supabase profiles table (available on any device).
///
/// Usage in main.dart:
///   ChangeNotifierProvider(create: (_) => LocaleProvider()..loadSavedLocale())
///
/// Usage in any widget:
//   final locale = context.watch<LocaleProvider>().locale;
//   context.read<LocaleProvider>().setLocale(const Locale('si'));
class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'femora_locale';

  // Default to English
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Supported locales — must match ARB file names
  static const supportedLocales = [
    Locale('en'),  // English
    Locale('si'),  // Sinhala
    Locale('ta'),  // Tamil
  ];

  /// Call this during app startup before showing any UI
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        _locale = Locale(saved);
        notifyListeners();
      }
    } catch (_) {
      // Keep default English if prefs unavailable
    }
  }

  /// Returns true if the user has ever chosen a language
  /// Used to decide whether to show the language selection screen
  Future<bool> hasChosenLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKey) != null;
    } catch (_) {
      return false;
    }
  }

  /// Set locale locally + sync to Supabase
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;

    _locale = locale;
    notifyListeners();

    // Persist locally for instant load on next launch
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, locale.languageCode);
    } catch (_) {}

    // Sync to Supabase so user's language follows them on any device
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        await SupabaseConfig.client
            .from('profiles')
            .update({'language': locale.languageCode})
            .eq('id', userId);
      }
    } catch (_) {
      // Non-critical — local pref already saved, Supabase sync can retry
    }
  }

  /// Returns a display name for the current locale
  String get currentLanguageLabel {
    switch (_locale.languageCode) {
      case 'si': return 'සිංහල';
      case 'ta': return 'தமிழ்';
      default:   return 'English';
    }
  }
}
