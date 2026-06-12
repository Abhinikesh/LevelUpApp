import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Headings — Syne ──────────────────────────────────────────
  static TextStyle h1 = GoogleFonts.syne(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle h2 = GoogleFonts.syne(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle h3 = GoogleFonts.syne(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle h4 = GoogleFonts.syne(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ── Body — Inter ─────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ── Special ──────────────────────────────────────────────────
  static TextStyle xpNumber = GoogleFonts.syne(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.gold,
    height: 1.0,
  );

  static TextStyle levelNumber = GoogleFonts.syne(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.brand,
    height: 1.0,
  );

  static TextStyle streakNumber = GoogleFonts.syne(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static TextStyle scoreNumber = GoogleFonts.syne(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static TextStyle tag = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.brand,
  );

  static TextStyle navLabel = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // ── Plan-specified aliases ────────────────────────────────────
  /// App logo wordmark — SpaceMono 20 700 brand purple
  static TextStyle appLogo = GoogleFonts.spaceMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF7B6EF6),
  );

  /// Page-level hero title — SpaceMono 22 700 near-white
  static TextStyle pageTitle = GoogleFonts.spaceMono(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFF5F5FF),
  );

  /// Section heading — SpaceMono 16 700 near-white
  static TextStyle sectionTitle = GoogleFonts.spaceMono(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFF5F5FF),
  );

  /// Large stat number — SpaceGrotesk 24 700 near-white
  static TextStyle statNumber = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFF5F5FF),
  );

  /// CTA button label — SpaceMono 14 700 white
  static TextStyle buttonText = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}

