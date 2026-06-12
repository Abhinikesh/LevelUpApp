import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_themes.dart' hide AppTheme;
import 'core/theme/app_color_scheme.dart';

class StepUpApp extends ConsumerWidget {
  const StepUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeProvider);
    final appMode = ref.watch(appModeProvider);

    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = appMode == 'system'
        ? (systemBrightness == Brightness.dark)
        : (appMode == 'dark');

    final themeData = AppTheme.buildThemeData(theme, isDark);

    return MaterialApp.router(
      title: 'STEPUP',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      routerConfig: router,
    );
  }
}
