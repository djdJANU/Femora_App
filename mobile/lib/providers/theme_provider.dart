// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

/// ThemeProvider
/// ─────────────
/// Manages light/dark theme preference.
/// Persists to SharedPreferences (instant load).
/// Syncs to Supabase profiles table.
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'femora_theme';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  /// Call during app startup
  Future<void> loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'dark') {
        _themeMode = ThemeMode.dark;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Toggle between light and dark
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    // Persist locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}

    // Sync to Supabase
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        await SupabaseConfig.client.from('profiles').update({
          'theme': _themeMode == ThemeMode.dark ? 'dark' : 'light',
        }).eq('id', userId);
      }
    } catch (_) {}
  }

  /// Set theme directly
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
