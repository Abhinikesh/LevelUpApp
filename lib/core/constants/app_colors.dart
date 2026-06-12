import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class DynamicColor extends Color {
  final int Function() getter;
  const DynamicColor(this.getter) : super(0);

  @override
  int get value => getter();
}

int _brandVal() => AppColors.currentTheme.primary.value;
int _coralVal() => AppColors.currentTheme.secondary.value;
int _greenVal() => AppColors.currentTheme.accent.value;
int _tealVal() => AppColors.currentTheme.accent.value;
int _infoVal() => AppColors.currentTheme.primary.value;

int _bgDarkVal() => AppColors.isDark ? 0xFF080810 : 0xFFF5F5FA;
int _bgCardVal() => AppColors.isDark ? 0xFF0F0F1A : 0xFFFFFFFF;
int _bgCardLightVal() => AppColors.isDark ? 0xFF161625 : 0xFFF0F0F5;
int _borderVal() => AppColors.isDark ? 0xFF1C1C2E : 0xFFE0E0EB;
int _borderLightVal() => AppColors.isDark ? 0xFF252538 : 0xFFE5E5F0;

int _textPrimaryVal() => AppColors.isDark ? 0xFFF5F5FF : 0xFF1A1A2E;
int _textSecondaryVal() => AppColors.isDark ? 0xFF9898B8 : 0xFF6B6B8A;
int _textMutedVal() => AppColors.isDark ? 0xFF55557A : 0xFFAAAABF;

class AppColors {
  AppColors._();

  // Dynamic state loaded from providers
  static AppTheme currentTheme = appThemes[0];
  static bool isDark = true;

  // Brand Colors
  static const Color brand = DynamicColor(_brandVal);       // Brand purple
  static const Color coral = DynamicColor(_coralVal);       // Brand coral
  static const Color green = DynamicColor(_greenVal);       // Brand green
  static const Color yellow = Color(0xFFFFB300);            // Gold / Yellow
  static const Color gold = Color(0xFFFFB300);              // Gold
  static const Color teal = DynamicColor(_tealVal);         // Map to brand green

  // Background Colors
  static const Color bgDark = DynamicColor(_bgDarkVal);      // Background (darkest)
  static const Color bgCard = DynamicColor(_bgCardVal);      // Surface (cards)
  static const Color bgCardLight = DynamicColor(_bgCardLightVal); // Surface elevated
  static const Color border = DynamicColor(_borderVal);       // Border subtle
  static const Color borderLight = DynamicColor(_borderLightVal);  // Border bright

  // Text Colors
  static const Color textPrimary = DynamicColor(_textPrimaryVal);
  static const Color textSecondary = DynamicColor(_textSecondaryVal);
  static const Color textMuted = DynamicColor(_textMutedVal);

  // Status Colors
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5E7D);
  static const Color info = DynamicColor(_infoVal);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static Color get glowBrand => brand.withValues(alpha: 0.2);
  static Color get glowCoral => coral.withValues(alpha: 0.2);
  static Color get glowGreen => green.withValues(alpha: 0.2);
  static Color get glowGold => gold.withValues(alpha: 0.2);

  // Gradients
  static LinearGradient get brandGradient => LinearGradient(
    colors: [brand, coral],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get greenGradient => LinearGradient(
    colors: [green, green.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get goldGradient => LinearGradient(
    colors: [gold, gold.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get darkGradient => LinearGradient(
    colors: [bgCard, bgDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get purpleGradient => LinearGradient(
    colors: [brand, brand.withValues(alpha: 0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get fireGradient => LinearGradient(
    colors: [const Color(0xFFFF8C00), coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get dangerGradient => LinearGradient(
    colors: [coral, const Color(0xFFFF3E3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
