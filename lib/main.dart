import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved connection configurations (defaults to Demo Mode)
  await ApiConstants.init();

  // Load saved theme and mode for AppColors initialization
  try {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString('app_theme') ?? 'default';
    AppColors.currentTheme = appThemes.firstWhere((t) => t.id == themeId, orElse: () => appThemes[0]);
    
    final appMode = prefs.getString('app_mode') ?? 'system';
    if (appMode == 'system') {
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
      AppColors.isDark = platformDispatcher.platformBrightness == Brightness.dark;
    } else {
      AppColors.isDark = appMode == 'dark';
    }
  } catch (_) {}

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style — light text on dark background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: StepUpApp(),
    ),
  );
}
