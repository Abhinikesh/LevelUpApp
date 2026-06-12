import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

final appModeProvider = StateNotifierProvider<AppModeNotifier, String>((ref) {
  return AppModeNotifier();
});

class AppModeNotifier extends StateNotifier<String> {
  AppModeNotifier() : super('system') {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('app_mode') ?? 'system';
  }

  Future<void> setMode(String mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', mode);
  }
}

ColorScheme getAppColorScheme(AppTheme theme, bool isDark) {
  if (isDark) {
    return ColorScheme.dark(
      primary: theme.primary,
      secondary: theme.secondary,
      outline: const Color(0xFF1C1C2E), // border
      surface: const Color(0xFF0F0F1A), // bgCard
      error: const Color(0xFFFF5E7D), // error
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFF5F5FF), // textPrimary
      onSurfaceVariant: const Color(0xFF9898B8), // textSecondary
      onError: Colors.white,
    );
  } else {
    return ColorScheme.light(
      primary: theme.primary,
      secondary: theme.secondary,
      outline: const Color(0xFFE0E0EB), // border light
      surface: const Color(0xFFFFFFFF), // bgCard light
      error: const Color(0xFFFF5E7D), // error
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1A1A2E), // textPrimary light
      onSurfaceVariant: const Color(0xFF6B6B8A), // textSecondary light
      onError: Colors.white,
    );
  }
}
