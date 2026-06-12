import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  
  const AppTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

const List<AppTheme> appThemes = [
  AppTheme(id: 'default', name: 'Cosmic Purple',
    primary: Color(0xFF7B6EF6), secondary: Color(0xFFFF5E7D), accent: Color(0xFF00E5A0)),
  AppTheme(id: 'forest', name: 'Forest Green',
    primary: Color(0xFF2ECC71), secondary: Color(0xFF27AE60), accent: Color(0xFFA8E063)),
  AppTheme(id: 'ocean', name: 'Ocean Blue',
    primary: Color(0xFF2E86FF), secondary: Color(0xFF00C6FF), accent: Color(0xFF72EDF2)),
  AppTheme(id: 'sunset', name: 'Sunset Orange',
    primary: Color(0xFFFF7E29), secondary: Color(0xFFFFB300), accent: Color(0xFFFF5E62)),
  AppTheme(id: 'rose', name: 'Rose Pink',
    primary: Color(0xFFFF5C8A), secondary: Color(0xFFFF8FAB), accent: Color(0xFFFFC2D1)),
  AppTheme(id: 'sky', name: 'Sky Blue',
    primary: Color(0xFF4FACFE), secondary: Color(0xFF00F2FE), accent: Color(0xFFA1C4FD)),
  AppTheme(id: 'royal', name: 'Royal Gold',
    primary: Color(0xFFFFD700), secondary: Color(0xFFFFA500), accent: Color(0xFFFFE066)),
  AppTheme(id: 'mono', name: 'Slate Gray',
    primary: Color(0xFF8E9AAF), secondary: Color(0xFFCBC0D3), accent: Color(0xFFEFD3D7)),
];

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(appThemes[0]) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString('app_theme') ?? 'default';
    final theme = appThemes.firstWhere((t) => t.id == themeId, orElse: () => appThemes[0]);
    state = theme;
  }

  Future<void> setTheme(String themeId) async {
    final theme = appThemes.firstWhere((t) => t.id == themeId, orElse: () => appThemes[0]);
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', themeId);
  }
}
