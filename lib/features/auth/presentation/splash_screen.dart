import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/secure_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _startNavTimer();
  }

  Future<void> _startNavTimer() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    await _navigate();
  }

  Future<void> _navigate() async {
    final hasToken = await SecureStorageService.hasToken();
    if (!mounted) return;
    if (hasToken) {
      context.go(AppRoutes.dashboard);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    context.go(seenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [Color(0xFF1A1040), AppColors.bgDark],
          ),
        ),
        child: Stack(
          children: [
            // Background glow orbs
            Positioned(
              top: -100,
              left: -80,
              child: _GlowOrb(color: AppColors.brand, size: 300, opacity: 0.08),
            ),
            Positioned(
              bottom: -80,
              right: -60,
              child: _GlowOrb(color: AppColors.coral, size: 250, opacity: 0.06),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ────────────────────────────────────
                  _GradientText(
                    'STEPUP',
                    gradient: AppColors.brandGradient,
                    style: GoogleFonts.syne(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms),

                  const SizedBox(height: AppSpacing.base),

                  // ── Tagline ──────────────────────────────────
                  Text(
                    'Level up your life',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: AppSpacing.massive + AppSpacing.xxxl),

                  // ── Bouncing dots ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return _BouncingDot(index: i);
                    }),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 400.ms),
                ],
              ),
            ),

            // Bottom version text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ).animate().fadeIn(delay: 900.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient text helper ────────────────────────────────────
class _GradientText extends StatelessWidget {
  final String text;
  final LinearGradient gradient;
  final TextStyle style;
  const _GradientText(this.text,
      {required this.gradient, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

// ─── Glow orb ───────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowOrb(
      {required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Bouncing dot ────────────────────────────────────────────
class _BouncingDot extends StatelessWidget {
  final int index;
  const _BouncingDot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
          delay: Duration(milliseconds: index * 160),
        )
        .moveY(
          begin: 0,
          end: -10,
          duration: 500.ms,
          curve: Curves.easeInOut,
        );
  }
}
