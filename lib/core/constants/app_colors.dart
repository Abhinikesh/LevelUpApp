import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color brand = Color(0xFF7B6EF6);       // Brand purple
  static const Color coral = Color(0xFFFF5E7D);       // Brand coral
  static const Color green = Color(0xFF00E5A0);       // Brand green
  static const Color yellow = Color(0xFFFFB300);      // Gold / Yellow
  static const Color gold = Color(0xFFFFB300);        // Gold
  static const Color teal = Color(0xFF00E5A0);        // Map to brand green

  // Background Colors
  static const Color bgDark = Color(0xFF080810);      // Background (darkest)
  static const Color bgCard = Color(0xFF0F0F1A);      // Surface (cards)
  static const Color bgCardLight = Color(0xFF161625); // Surface elevated
  static const Color border = Color(0xFF1C1C2E);       // Border subtle
  static const Color borderLight = Color(0xFF252538);  // Border bright

  // Text Colors
  static const Color textPrimary = Color(0xFFF5F5FF);
  static const Color textSecondary = Color(0xFF9898B8);
  static const Color textMuted = Color(0xFF55557A);

  // Status Colors
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5E7D);
  static const Color info = Color(0xFF7B6EF6);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color glowBrand = Color(0x337B6EF6);
  static const Color glowCoral = Color(0x33FF5E7D);
  static const Color glowGreen = Color(0x3300E5A0);
  static const Color glowGold = Color(0x33FFB300);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF7B6EF6), Color(0xFFFF5E7D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00C788)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF080810)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7B6EF6), Color(0xFF9F93FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFF8C00), Color(0xFFFF5E7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF5E7D), Color(0xFFE53E3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
