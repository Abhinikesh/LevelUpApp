import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color brand = Color(0xFF6C63FF);
  static const Color coral = Color(0xFFFF6584);
  static const Color green = Color(0xFF43E97B);
  static const Color yellow = Color(0xFFFFD93D);
  static const Color gold = Color(0xFFFFB800);
  static const Color teal = Color(0xFF38F9D7);

  // Background Colors
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color bgCard = Color(0xFF12121A);
  static const Color bgCardLight = Color(0xFF1A1A27);
  static const Color border = Color(0xFF1E1E2E);
  static const Color borderLight = Color(0xFF2A2A3E);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8B8BAE);
  static const Color textMuted = Color(0xFF4A4A6A);

  // Status Colors
  static const Color success = Color(0xFF43E97B);
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color glowBrand = Color(0x336C63FF);
  static const Color glowCoral = Color(0x33FF6584);
  static const Color glowGreen = Color(0x3343E97B);
  static const Color glowGold = Color(0x33FFB800);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF12121A), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFF8C00), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
