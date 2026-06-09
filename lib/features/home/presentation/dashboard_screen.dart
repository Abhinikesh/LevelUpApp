import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../models/roadmap_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/widgets/premium_animations.dart';
import '../../../shared/widgets/loading_shimmer.dart';

// ─── Daily XP: backed by SharedPreferences via todayXpProvider ──

// ─── Dashboard Screen ─────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(dashboardProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final roadmaps = ref.watch(activeRoadmapsProvider);
    final dailyXp = ref.watch(todayXpProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardProvider.notifier).loadDashboard(),
        color: AppColors.brand,
        backgroundColor: AppColors.bgCard,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Greeting header (no bell — that's in AppBar) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.base,
                    AppSpacing.pagePadding,
                    0),
                child: _GreetingHeader(user: user, now: now)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.04, end: 0),
              ),
            ),

            // ── XP & Streak stat cards ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.base + 8,
                    AppSpacing.pagePadding,
                    0),
                child: Row(
                  children: [
                    Expanded(
                      child: HoverShift(
                        child: _XpCard(user: user)
                            .animate()
                            .fadeIn(delay: 80.ms)
                            .slideX(begin: -0.04, end: 0),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: HoverShift(
                        child: _StreakCard(user: user)
                            .animate()
                            .fadeIn(delay: 130.ms)
                            .slideX(begin: 0.04, end: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Continue card ──────────────────────────────────
            if (dashboardState.activeRoadmap != null &&
                dashboardState.activeLevel != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding,
                      AppSpacing.xl, AppSpacing.pagePadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue Where You Left Off',
                        style: GoogleFonts.spaceMono(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ActiveLevelCard(
                        roadmap: dashboardState.activeRoadmap!,
                        levelName: dashboardState.activeLevel!.title,
                        proofType:
                            dashboardState.activeLevel!.proofTypeLabel,
                        estimatedMinutes:
                            dashboardState.activeLevel!.estimatedMinutes,
                        xpReward: dashboardState.activeLevel!.xpReward,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 180.ms)
                    .slideY(begin: 0.04, end: 0),
              ),

            // ── FIX 3: Your Roadmaps ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.pagePadding,
                    top: AppSpacing.xl,
                    right: AppSpacing.pagePadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Roadmaps',
                      style: GoogleFonts.spaceMono(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.map),
                      child: Text(
                        'See All →',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: dashboardState.isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(
                          left: AppSpacing.pagePadding,
                          top: AppSpacing.md),
                      child: SizedBox(
                        height: 140,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 180,
                                  child: ShimmerCard(height: 140)),
                              SizedBox(width: 12),
                              SizedBox(
                                  width: 180,
                                  child: ShimmerCard(height: 140)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : roadmaps.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pagePadding,
                              AppSpacing.md,
                              AppSpacing.pagePadding,
                              0),
                          child: _EmptyRoadmapsState(
                              onTap: () =>
                                  context.push(AppRoutes.create)),
                        )
                      : SizedBox(
                          height: 158,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                left: AppSpacing.pagePadding,
                                top: AppSpacing.md,
                                right: AppSpacing.pagePadding),
                            itemCount: roadmaps.length,
                            itemBuilder: (_, i) => Padding(
                              padding:
                                  const EdgeInsets.only(right: 12),
                              child: HoverShift(
                                child: _RoadmapCard(
                                        roadmap: roadmaps[i])
                                    .animate()
                                    .fadeIn(
                                        delay: Duration(
                                            milliseconds:
                                                220 + i * 50))
                                    .slideX(begin: 0.04, end: 0),
                              ),
                            ),
                          ),
                        ),
            ),

            // ── FIX 4: 30-Day Activity grid ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding,
                    AppSpacing.xl + 4, AppSpacing.pagePadding, 0),
                child: _ActivityDotGrid(
                        streakCount: user?.streakCount ?? 0)
                    .animate()
                    .fadeIn(delay: 280.ms),
              ),
            ),

            // ── FIX 5: Daily Goal card ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding,
                    AppSpacing.xl, AppSpacing.pagePadding, 0),
                child: _DailyGoalCard(dailyXpEarned: dailyXp)
                    .animate()
                    .fadeIn(delay: 320.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─── FIX 1: Greeting Header (NO bell — bell is in home_shell TopBar) ─
class _GreetingHeader extends StatelessWidget {
  final UserModel? user;
  final DateTime now;
  const _GreetingHeader({required this.user, required this.now});

  String get _greeting {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateStr {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.name.split(' ').first ?? 'Explorer';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        // Avatar with gradient ring
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgCard,
            child: Text(
              initial,
              style: GoogleFonts.spaceMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $name 👋',
                style: GoogleFonts.spaceMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── XP Card ─────────────────────────────────────────────────
class _XpCard extends StatefulWidget {
  final UserModel? user;
  const _XpCard({required this.user});
  @override
  State<_XpCard> createState() => _XpCardState();
}

class _XpCardState extends State<_XpCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xp = widget.user?.xpTotal ?? 0;
    final level = widget.user?.level ?? 1;
    final progress = widget.user?.levelProgress ?? 0.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: SweepGradient(
            center: Alignment.center,
            transform: GradientRotation(_ctrl.value * math.pi * 2),
            colors: const [
              AppColors.gold,
              Color(0xFFFF8C00),
              AppColors.gold
            ],
          ),
        ),
        padding: const EdgeInsets.all(1.2),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 22)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LV $level',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CountUpText(
              end: xp,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              suffix: ' XP',
            ),
            const SizedBox(height: 2),
            Text(
              'Total earned',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            _AnimatedProgressBar(
              progress: progress,
              colors: const [AppColors.gold, Color(0xFFFF8C00)],
            ),
            const SizedBox(height: 5),
            Text(
              '${(progress * 100).toInt()}% to Level ${level + 1}',
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Streak Card ─────────────────────────────────────────────
class _StreakCard extends StatefulWidget {
  final UserModel? user;
  const _StreakCard({required this.user});
  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.user?.streakCount ?? 0;
    final best = widget.user?.longestStreak ?? 0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: SweepGradient(
            center: Alignment.center,
            transform: GradientRotation(_ctrl.value * math.pi * 2),
            colors: const [
              Color(0xFFFF8C00),
              AppColors.coral,
              Color(0xFFFF8C00),
            ],
          ),
        ),
        padding: const EdgeInsets.all(1.2),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const WobbleWidget(
                  child: Text('🔥', style: TextStyle(fontSize: 22)),
                ),
                const Spacer(),
                Text(
                  'STREAK',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CountUpText(
              end: streak,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              suffix: ' Days',
            ),
            const SizedBox(height: 2),
            Text(
              'Best: $best days',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active =
                    i < (streak % 7 == 0 && streak > 0 ? 7 : streak % 7);
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? AppColors.coral
                        : const Color(0xFF1C1C2E),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: AppColors.coral.withOpacity(0.5),
                                blurRadius: 5)
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 5),
            Text(
              'This week',
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Level Card ────────────────────────────────────────
class _ActiveLevelCard extends StatefulWidget {
  final RoadmapModel roadmap;
  final String levelName;
  final String proofType;
  final int estimatedMinutes;
  final int xpReward;

  const _ActiveLevelCard({
    required this.roadmap,
    required this.levelName,
    required this.proofType,
    required this.estimatedMinutes,
    required this.xpReward,
  });

  @override
  State<_ActiveLevelCard> createState() => _ActiveLevelCardState();
}

class _ActiveLevelCardState extends State<_ActiveLevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.roadmap;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: SweepGradient(
            center: Alignment.center,
            transform: GradientRotation(_ctrl.value * math.pi * 2),
            colors: const [AppColors.brand, AppColors.coral, AppColors.brand],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.18),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.3),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.brand.withOpacity(0.25), width: 1),
                  ),
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'WORLD ${((r.currentLevel - 1) ~/ 5) + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient
                  .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
              child: Text(
                'Level ${r.currentLevel}',
                style: GoogleFonts.spaceMono(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.levelName,
              style: GoogleFonts.spaceMono(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(icon: '📋', label: widget.proofType),
                const SizedBox(width: 8),
                _InfoChip(icon: '⏱', label: '${widget.estimatedMinutes} min'),
                const SizedBox(width: 8),
                _InfoChip(icon: '⚡', label: '${widget.xpReward} XP'),
              ],
            ),
            const SizedBox(height: 18),
            BounceOnTap(
              onTap: () => context.push('${AppRoutes.map}/${r.id}'),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue Level',
                        style: GoogleFonts.spaceMono(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 17),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FIX 3: Empty Roadmaps State (dashed border) ─────────────
class _EmptyRoadmapsState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyRoadmapsState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.brand,
        strokeWidth: 2,
        dashLength: 8,
        gap: 5,
        radius: 20,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.brand.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No roadmaps yet',
              style: GoogleFonts.spaceMono(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first goal to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            BounceOnTap(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  '+ Create Roadmap',
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a dashed rounded-rect border
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gap;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
              size.width - strokeWidth, size.height - strokeWidth),
          Radius.circular(radius)));

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gap;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => false;
}

// ─── FIX 3: Roadmap Card (180×140, gradient top) ─────────────
class _RoadmapCard extends StatelessWidget {
  final RoadmapModel roadmap;
  const _RoadmapCard({required this.roadmap});

  LinearGradient _topGradient() {
    switch (roadmap.type) {
      case 'study':
        return const LinearGradient(
          colors: [Color(0xFF7B6EF6), Color(0xFF9F93FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gym':
        return const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF5E7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'work':
        return const LinearGradient(
          colors: [Color(0xFF00E5A0), Color(0xFF00C788)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default: // custom
        return const LinearGradient(
          colors: [Color(0xFFFF5E7D), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = roadmap.coverEmoji ?? roadmap.typeEmoji;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.map}/${roadmap.id}'),
      child: Container(
        width: 180,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top 50px: gradient with emoji
              Container(
                height: 50,
                decoration: BoxDecoration(gradient: _topGradient()),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              // Bottom 90px: info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roadmap.title,
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _AnimatedProgressBar(
                        progress: roadmap.progressPercent,
                        colors: const [AppColors.brand, AppColors.coral],
                        height: 4,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Level ${roadmap.currentLevel} of ${roadmap.totalLevels}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FIX 4: 30-Day Activity Grid ─────────────────────────────
class _ActivityDotGrid extends StatefulWidget {
  final int streakCount;
  const _ActivityDotGrid({required this.streakCount});

  @override
  State<_ActivityDotGrid> createState() => _ActivityDotGridState();
}

class _ActivityDotGridState extends State<_ActivityDotGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streakCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            Text(
              '30-Day Activity',
              style: GoogleFonts.spaceMono(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            if (streak > 0)
              Text(
                '🔥 $streak Day Streak',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Grid: 5 rows × 6 columns with W labels on left
              ...List.generate(5, (row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Week label
                      SizedBox(
                        width: 24,
                        child: Text(
                          'W${row + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 6 dots per row
                      ...List.generate(6, (col) {
                        final idx = row * 6 + col; // 0..29
                        // idx 29 = today
                        final isToday = idx == 29;
                        // completed: past days within streak
                        final isCompleted =
                            idx >= (29 - streak + 1) && idx < 29 && streak > 0;
                        // future: beyond today (won't happen in 0..29, idx 29 is today)
                        // We treat any idx > 29 as future but since max=29 that's none.
                        return Padding(
                          padding: EdgeInsets.only(right: col < 5 ? 8 : 0),
                          child: isToday
                              ? AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (_, __) {
                                    return SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outer pulsing ring
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.brand.withOpacity(
                                                  0.4 * _pulseCtrl.value),
                                            ),
                                          ),
                                          // Inner solid dot
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.brand,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : isCompleted
                                  ? Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppColors.brandGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.brand
                                                .withOpacity(0.35),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                        );
                      }),
                    ],
                  ),
                );
              }),

              // Below grid: streak or motivational text
              const SizedBox(height: 6),
              if (streak > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      '$streak Day Streak — Keep it up!',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Start your streak today!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── FIX 5: Daily Goal Card (animated ring, real data) ───────
class _DailyGoalCard extends StatefulWidget {
  final int dailyXpEarned;
  const _DailyGoalCard({required this.dailyXpEarned});

  @override
  State<_DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<_DailyGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progressAnim;

  static const int kDailyGoal = 300;

  double get _rawProgress =>
      (widget.dailyXpEarned / kDailyGoal).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: _rawProgress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_DailyGoalCard old) {
    super.didUpdateWidget(old);
    if (old.dailyXpEarned != widget.dailyXpEarned) {
      _progressAnim =
          Tween<double>(begin: _progressAnim.value, end: _rawProgress)
              .animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earned = widget.dailyXpEarned;
    final remaining = (kDailyGoal - earned).clamp(0, kDailyGoal);
    final isGoalReached = earned >= kDailyGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Animated ring
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) {
              return SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: _GoalRingPainter(
                    progress: _progressAnim.value,
                    isGoalReached: isGoalReached,
                  ),
                  child: Center(
                    child: isGoalReached
                        ? const Text('🎯',
                            style: TextStyle(fontSize: 28))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_progressAnim.value * 100).toInt()}%',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Today',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGoalReached ? 'Goal Reached!' : 'Daily Goal',
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isGoalReached
                        ? AppColors.gold
                        : AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$earned of $kDailyGoal XP earned today',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                if (!isGoalReached)
                  Text(
                    '$remaining XP to go',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  )
                else
                  Text(
                    '🏆 Amazing work today!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                const SizedBox(height: 10),
                // Thin gradient progress bar
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.bgCardLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progressAnim.value,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: isGoalReached
                                ? AppColors.goldGradient
                                : AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double progress;
  final bool isGoalReached;
  const _GoalRingPainter(
      {required this.progress, required this.isGoalReached});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    const strokeWidth = 8.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1A1A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final List<Color> gradColors = isGoalReached
        ? [AppColors.gold, Color(0xFFFF8C00)]
        : [AppColors.brand, AppColors.coral];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: gradColors).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.progress != progress || old.isGoalReached != isGoalReached;
}

// ─── Animated Progress Bar ──────────────────────────────────
class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final List<Color> colors;
  final double height;
  const _AnimatedProgressBar({
    required this.progress,
    required this.colors,
    this.height = 6,
  });

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: _anim.value, end: widget.progress).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        children: [
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: _anim.value,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: widget.colors),
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
