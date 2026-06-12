import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'app_themes.dart' as themes;
import 'app_color_scheme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData buildThemeData(themes.AppTheme theme, bool isDark) {
    final scheme = getAppColorScheme(theme, isDark);
    
    // Update global state for non-context style/gradient access
    AppColors.currentTheme = theme;
    AppColors.isDark = isDark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.brand,
      colorScheme: scheme,

      // ── Typography ─────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineMedium: AppTextStyles.h4,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h3,
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconLg,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconLg,
        ),
      ),

      // ── Bottom Navigation Bar ───────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle: AppTextStyles.navLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Navigation Bar (Material 3) ─────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        indicatorColor: AppColors.brand.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.brand, size: 22);
          }
          return IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.navLabel.copyWith(color: AppColors.brand);
          }
          return AppTextStyles.navLabel.copyWith(color: AppColors.textMuted);
        }),
        height: AppSpacing.bottomNavHeight,
        elevation: 0,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Card Theme ──────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Decoration ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.inputPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        labelStyle: AppTextStyles.label,
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ── Elevated Button ─────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize:
              const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Text Button ─────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: BorderSide(color: AppColors.brand),
          minimumSize:
              const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgCardLight,
        selectedColor: AppColors.brand.withValues(alpha: 0.2),
        labelStyle: AppTextStyles.bodySmall,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // ── Divider ──────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Snackbar ─────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCardLight,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Icon ─────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: AppSpacing.iconLg,
      ),

      // ── Switch ───────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor:
            WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textMuted;
        }),
        trackColor:
            WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brand;
          }
          return AppColors.border;
        }),
      ),

      // ── Progress Indicator ───────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),

      // ── Tooltip ──────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: AppTextStyles.bodySmall,
      ),
    );
  }
}
