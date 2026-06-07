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
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/empty_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final roadmaps = ref.watch(activeRoadmapsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        color: AppColors.brand,
        backgroundColor: const Color(0xFF12121A),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Premium Header ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding, AppSpacing.base, AppSpacing.pagePadding, 0),
                child: _PremiumHeader(user: user, now: now)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.05, end: 0),
              ),
            ),

            // ── XP & Streak Row ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding, AppSpacing.base + 10, AppSpacing.pagePadding, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: HoverShift(
                        child: _XpCard(user: user)
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideX(begin: -0.05, end: 0),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: HoverShift(
                        child: _StreakCard(user: user)
                            .animate()
                            .fadeIn(delay: 150.ms)
                            .slideX(begin: 0.05, end: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Active Level Card ─────────────────────────────
            if (dashboardState.activeRoadmap != null && dashboardState.activeLevel != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding, AppSpacing.xl, AppSpacing.pagePadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue Where You Left Off',
                        style: GoogleFonts.syne(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ActiveLevelCard(
                        roadmap: dashboardState.activeRoadmap!,
                        levelName: dashboardState.activeLevel!.title,
                        proofType: dashboardState.activeLevel!.proofTypeLabel,
                        estimatedMinutes: dashboardState.activeLevel!.estimatedMinutes,
                        xpReward: dashboardState.activeLevel!.xpReward,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
              ),

            // ── Your Roadmaps (Horizontal Scroll) ──────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.pagePadding, top: AppSpacing.xl, right: AppSpacing.pagePadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Roadmaps',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.map),
                      child: Text(
                        'See All',
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
                      padding: EdgeInsets.only(left: AppSpacing.pagePadding, top: AppSpacing.md),
                      child: SizedBox(
                        height: 145,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(width: 160, child: ShimmerCard(height: 145)),
                              SizedBox(width: 12),
                              SizedBox(width: 160, child: ShimmerCard(height: 145)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : roadmaps.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: AppSpacing.base),
                          child: EmptyRoadmaps(onCreateTap: () => context.push(AppRoutes.create)),
                        )
                      : SizedBox(
                          height: 155,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                left: AppSpacing.pagePadding, top: AppSpacing.md, right: AppSpacing.pagePadding),
                            itemCount: roadmaps.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.md),
                              child: HoverShift(
                                child: _RoadmapChip(roadmap: roadmaps[i])
                                    .animate()
                                    .fadeIn(delay: Duration(milliseconds: 250 + i * 50))
                                    .slideX(begin: 0.05, end: 0),
                              ),
                            ),
                          ),
                        ),
            ),

            // ── 30-Day Activity Dot Grid ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding, AppSpacing.xl + 8, AppSpacing.pagePadding, 0),
                child: _ActivityDotGrid(streakCount: user?.streakCount ?? 0)
                    .animate()
                    .fadeIn(delay: 300.ms),
              ),
            ),

            // ── Daily Goal Card ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding, AppSpacing.xl, AppSpacing.pagePadding, 0),
                child: _DailyGoalCard(user: user)
                    .animate()
                    .fadeIn(delay: 350.ms),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Header ──────────────────────────────────────────
class _PremiumHeader extends StatelessWidget {
  final UserModel? user;
  final DateTime now;
  const _PremiumHeader({required this.user, required this.now});

  String get _dateStr {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.name.split(' ').first ?? 'Explorer';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        // Avatar circle
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.brand.withOpacity(0.2),
          child: Text(
            initial,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, $name 👋',
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF12121A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E1E2E)),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.textSecondary,
              size: 20,
            ),
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

class _XpCardState extends State<_XpCard> with SingleTickerProviderStateMixin {
  late AnimationController _borderCtrl;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xp = widget.user?.xpTotal ?? 0;
    final toNext = widget.user?.xpToNextLevel ?? 500;
    final progress = toNext > 0 ? ((xp % toNext) / toNext).clamp(0.0, 1.0) : 0.0;

    return AnimatedBuilder(
      animation: _borderCtrl,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: SweepGradient(
            center: Alignment.center,
            transform: GradientRotation(_borderCtrl.value * math.pi * 2),
            colors: const [AppColors.gold, Colors.orange, AppColors.gold],
          ),
        ),
        padding: const EdgeInsets.all(1.0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 24)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LV ${widget.user?.level ?? 1}',
                    style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CountUpText(
              end: xp,
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              suffix: ' XP',
            ),
            const SizedBox(height: 2),
            Text(
              'Total earned',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _AnimatedProgressBar(
              progress: progress,
              colors: const [AppColors.gold, Colors.orange],
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toInt()}% to Level ${(widget.user?.level ?? 1) + 1}',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
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

class _StreakCardState extends State<_StreakCard> with SingleTickerProviderStateMixin {
  late AnimationController _borderCtrl;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.user?.streakCount ?? 0;
    final best = widget.user?.longestStreak ?? 0;

    return AnimatedBuilder(
      animation: _borderCtrl,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: SweepGradient(
            center: Alignment.center,
            transform: GradientRotation(_borderCtrl.value * math.pi * 2),
            colors: const [Colors.orange, AppColors.coral, Colors.orange],
          ),
        ),
        padding: const EdgeInsets.all(1.0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const WobbleWidget(
                  child: Text('🔥', style: TextStyle(fontSize: 24)),
                ),
                const Spacer(),
                Text(
                  'STREAK',
                  style: GoogleFonts.syne(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CountUpText(
              end: streak,
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              suffix: ' Days',
            ),
            const SizedBox(height: 2),
            Text(
              'Best: $best days',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active = i < (streak % 7 == 0 && streak > 0 ? 7 : streak % 7);
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? AppColors.coral : const Color(0xFF1E1E2E),
                    boxShadow: active
                        ? [BoxShadow(color: AppColors.coral.withOpacity(0.5), blurRadius: 4)]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              'This week',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
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

class _ActiveLevelCardState extends State<_ActiveLevelCard> with SingleTickerProviderStateMixin {
  late AnimationController _borderCtrl;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.roadmap;

    return AnimatedBuilder(
      animation: _borderCtrl,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: SweepGradient(
            center: Alignment.center,
            transform: GradientRotation(_borderCtrl.value * math.pi * 2),
            colors: const [AppColors.brand, AppColors.coral, AppColors.brand],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.2),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient.createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
              child: Text(
                'Level ${r.currentLevel}',
                style: GoogleFonts.syne(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.levelName,
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue Level',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E3E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
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

// ─── Roadmap horizontal chip ─────────────────────────────────
class _RoadmapChip extends StatelessWidget {
  final RoadmapModel roadmap;
  const _RoadmapChip({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.map}/${roadmap.id}'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E2E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  roadmap.coverEmoji ?? roadmap.typeEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roadmap.type.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              roadmap.title,
              style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _AnimatedProgressBar(
              progress: roadmap.progressPercent,
              colors: const [AppColors.brand, AppColors.teal],
            ),
            const SizedBox(height: 6),
            Text(
              'Level ${roadmap.currentLevel} of ${roadmap.totalLevels}',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 30-Day Activity Dot Grid ──────────────────────────────────
class _ActivityDotGrid extends StatefulWidget {
  final int streakCount;
  const _ActivityDotGrid({required this.streakCount});

  @override
  State<_ActivityDotGrid> createState() => _ActivityDotGridState();
}

class _ActivityDotGridState extends State<_ActivityDotGrid> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '30-Day Activity',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF12121A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E1E2E)),
          ),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: 30,
                itemBuilder: (context, idx) {
                  // Index 29 is Today.
                  final isToday = idx == 29;
                  // If user has a streak, light up index 29 down to 29 - streakCount + 1
                  final isCompleted = idx >= (29 - widget.streakCount + 1) && idx < 29;

                  if (isToday) {
                    return AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brand.withOpacity(0.6 * _pulseCtrl.value),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else if (isCompleted) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.brandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E1E2E),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.streakCount} Day Streak',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Daily Goal Card ─────────────────────────────────────────
class _DailyGoalCard extends StatelessWidget {
  final UserModel? user;
  const _DailyGoalCard({required this.user});

  @override
  Widget build(BuildContext context) {
    const dailyXp = 120;
    const goalXp = 300;
    const progress = (dailyXp / goalXp);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _RingPainter(progress: progress),
              child: Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Goal',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dailyXp of $goalXp XP earned today',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  '${goalXp - dailyXp} XP to go',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
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

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1E1E2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: [AppColors.brand, AppColors.coral]).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Animated Progress Bar ──────────────────────────────────
class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final List<Color> colors;
  const _AnimatedProgressBar({required this.progress, required this.colors});

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _ctrl.reset();
      _anim = Tween<double>(begin: 0, end: widget.progress).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl.forward();
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
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: _anim.value,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.colors),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
