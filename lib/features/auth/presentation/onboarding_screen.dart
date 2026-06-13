import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/stepup_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final _pages = const [_Page1(), _Page2(), _Page3()];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.brand.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          Column(
            children: [
              // Skip button
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: AppSpacing.pagePadding, top: AppSpacing.sm),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: _pages,
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.xl,
                  AppSpacing.pagePadding,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: active ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            gradient:
                                active ? AppColors.brandGradient : null,
                            color: active ? null : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // CTA button
                    StepUpButton(
                      label: isLast ? 'Get Started 🚀' : 'Continue',
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
              SafeArea(top: false, child: const SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared page wrapper ──────────────────────────────────────
class _PageWrapper extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;
  const _PageWrapper({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        children: [
          // Illustration area
          Expanded(
            flex: 3,
            child: Center(child: illustration),
          ),
          const SizedBox(height: 16),
          // Text area
          Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── PAGE 1: Game map illustration ───────────────────────────
class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'Your Goals, Gamified',
      subtitle:
          'Turn any task into a Candy Crush-style level map. Complete one, unlock the next.',
      illustration: _MapIllustration(),
    );
  }
}

class _MapIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Curved path behind nodes (custom paint)
          CustomPaint(
            size: const Size(260, 240),
            painter: _PathPainter(),
          ),
          // Level nodes
          Positioned(
            top: 20,
            left: 80,
            child: _LevelNode(
              label: '1',
              color: AppColors.green,
              isCompleted: true,
              delay: 0,
            ),
          ),
          Positioned(
            top: 100,
            left: 140,
            child: _LevelNode(
              label: '2',
              color: AppColors.brand,
              isActive: true,
              delay: 200,
            ),
          ),
          Positioned(
            top: 170,
            left: 60,
            child: _LevelNode(
              label: '3',
              color: AppColors.borderLight,
              isLocked: true,
              delay: 400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.42, 44);
    path.cubicTo(
      size.width * 0.65, 80,
      size.width * 0.75, 110,
      size.width * 0.66, 124,
    );
    path.cubicTo(
      size.width * 0.58, 140,
      size.width * 0.35, 155,
      size.width * 0.35, 194,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LevelNode extends StatelessWidget {
  final String label;
  final Color color;
  final bool isCompleted;
  final bool isActive;
  final bool isLocked;
  final int delay;

  const _LevelNode({
    required this.label,
    required this.color,
    this.isCompleted = false,
    this.isActive = false,
    this.isLocked = false,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    Widget node = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLocked ? AppColors.bgCardLight : null,
        gradient: isCompleted
            ? AppColors.greenGradient
            : isActive
                ? AppColors.brandGradient
                : null,
        border: Border.all(color: color, width: isActive ? 2.5 : 1.5),
        boxShadow: isActive || isCompleted
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
            : isLocked
                ? const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20)
                : Text(
                    label,
                    style: GoogleFonts.syne(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
      ),
    );

    if (isActive) {
      node = node
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 1200.ms, curve: Curves.easeInOut);
    }

    return node
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          delay: Duration(milliseconds: delay),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms);
  }
}

// ─── PAGE 2: AI verification ──────────────────────────────────
class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'AI Verifies Your Progress',
      subtitle:
          'No more fake done. Quiz, photo proof, code submission. Real progress only.',
      illustration: _VerificationIllustration(),
    );
  }
}

class _VerificationIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone frame
          Center(
            child: Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgCardLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'What is O(n log n)?',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _QuizOption('Merge Sort', correct: true),
                  const SizedBox(height: 6),
                  _QuizOption('Bubble Sort'),
                ],
              ),
            ).animate().scale(
              begin: const Offset(0.8, 0.8),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ).fadeIn(duration: 400.ms),
          ),

          // Checkmark badge
          Positioned(
            top: 10,
            right: 20,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.greenGradient,
                boxShadow: [BoxShadow(color: AppColors.glowGreen, blurRadius: 12)],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  duration: 600.ms,
                  delay: 400.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(delay: 400.ms),
          ),

          // Stars flying out
          ...List.generate(4, (i) {


            return Positioned(
              top: 20 + 70 * (0.3 + 0.4 * (i % 2)),
              right: 10 + 40.0 * i,
              child: Text('⭐', style: const TextStyle(fontSize: 14))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -8, duration: 900.ms + Duration(milliseconds: i * 200))
                  .fadeIn(delay: Duration(milliseconds: 500 + i * 150)),
            );
          }),
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  final String text;
  final bool correct;
  const _QuizOption(this.text, {this.correct = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: correct
            ? AppColors.green.withValues(alpha: 0.15)
            : AppColors.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: correct ? AppColors.green : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: correct ? AppColors.green : AppColors.textMuted,
          fontWeight: correct ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── PAGE 3: Social / leaderboard ────────────────────────────
class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'Beat Your Friends',
      subtitle:
          'Race friends on the same roadmap. Leaderboards, streaks, and bragging rights.',
      illustration: _SocialIllustration(),
    );
  }
}

class _SocialIllustration extends StatelessWidget {
  final _friends = const [
    ('A', AppColors.coral, '🥇', 2400),
    ('B', AppColors.brand, '🥈', 1850),
    ('C', AppColors.green, '🥉', 1200),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        children: [
          // Trophy center
          Center(
            child: Text('🏆', style: const TextStyle(fontSize: 60))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -8, duration: 1500.ms, curve: Curves.easeInOut)
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
          ),

          // Friend avatars with progress
          ..._friends.asMap().entries.map((e) {
            final i = e.key;
            final (initial, color, medal, xp) = e.value;
            final tops = [30.0, 80.0, 140.0];
            final lefts = [160.0, 30.0, 170.0];

            return Positioned(
              top: tops[i],
              left: lefts[i],
              child: _FriendBadge(
                initial: initial,
                color: color,
                medal: medal,
                xp: xp,
                delay: i * 150,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FriendBadge extends StatelessWidget {
  final String initial;
  final Color color;
  final String medal;
  final int xp;
  final int delay;

  const _FriendBadge({
    required this.initial,
    required this.color,
    required this.medal,
    required this.xp,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                initial,
                style: GoogleFonts.syne(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: Text(medal, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$xp XP',
          style: GoogleFonts.inter(
              fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          delay: Duration(milliseconds: delay + 200),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(delay: Duration(milliseconds: delay + 200));
  }
}
