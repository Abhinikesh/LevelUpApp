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
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/stepup_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roadmapProvider.notifier).fetchRoadmaps());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final roadmapState = ref.watch(roadmapProvider);
    final roadmaps = ref.watch(activeRoadmapsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Greeting header ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, AppSpacing.base, AppSpacing.pagePadding, 0),
              child: _GreetingHeader(user: user, now: now)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, end: 0, duration: 400.ms),
            ),
          ),

          // ── XP + Streak row ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, AppSpacing.base, AppSpacing.pagePadding, 0),
              child: Row(
                children: [
                  Expanded(child: _XpCard(user: user)
                      .animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0, delay: 100.ms)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _StreakCard(user: user)
                      .animate().fadeIn(delay: 180.ms).slideX(begin: 0.1, end: 0, delay: 180.ms)),
                ],
              ),
            ),
          ),

          // ── Active level card ─────────────────────────────
          if (roadmaps.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding, AppSpacing.xl, AppSpacing.pagePadding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Continue Where You Left Off',
                        style: GoogleFonts.syne(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    _ActiveLevelCard(roadmap: roadmaps.first),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0, delay: 250.ms),
            ),

          // ── Active roadmaps ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.pagePadding, top: AppSpacing.xl, right: AppSpacing.pagePadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Roadmaps',
                      style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.map),
                    child: Text('See All',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: roadmapState.isLoading && !roadmapState.hasLoaded
                ? const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.pagePadding, top: AppSpacing.md),
                    child: SizedBox(
                      height: 130,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          SizedBox(width: 220, child: ShimmerCard(height: 130)),
                          SizedBox(width: 12),
                          SizedBox(width: 220, child: ShimmerCard(height: 130)),
                        ]),
                      ),
                    ),
                  )
                : roadmaps.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: AppSpacing.base),
                        child: EmptyRoadmaps(onCreateTap: () => context.push(AppRoutes.create)),
                      )
                    : SizedBox(
                        height: 145,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                              left: AppSpacing.pagePadding, top: AppSpacing.md, right: AppSpacing.pagePadding),
                          itemCount: roadmaps.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.md),
                            child: _RoadmapChip(roadmap: roadmaps[i])
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 300 + i * 80))
                                .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: 300 + i * 80)),
                          ),
                        ),
                      ),
          ),

          // ── Streak calendar ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, AppSpacing.xl, AppSpacing.pagePadding, 0),
              child: _StreakCalendar(streakCount: user?.streakCount ?? 0)
                  .animate().fadeIn(delay: 400.ms),
            ),
          ),

          // ── Daily goal ring ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, AppSpacing.xl, AppSpacing.pagePadding, 0),
              child: _DailyGoalCard(user: user)
                  .animate().fadeIn(delay: 480.ms),
            ),
          ),

          // ── Friends activity ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, AppSpacing.xl, AppSpacing.pagePadding, 0),
              child: _FriendsSection()
                  .animate().fadeIn(delay: 560.ms),
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}

// ─── Greeting header ─────────────────────────────────────────
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
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.name.split(' ').first ?? 'Explorer';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting, $name 👋',
            style: GoogleFonts.syne(
                fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(_dateStr,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── XP card ─────────────────────────────────────────────────
class _XpCard extends StatelessWidget {
  final UserModel? user;
  const _XpCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final xp = user?.xpTotal ?? 0;
    final toNext = user?.xpToNextLevel ?? 500;
    final progress = toNext > 0 ? ((xp % toNext) / toNext).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.1), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(child: Text('⚡', style: TextStyle(fontSize: 16))),
            ),
            const Spacer(),
            Text('LV ${user?.level ?? 1}',
                style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          _AnimatedCount(
            value: xp,
            style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gold),
            suffix: ' XP',
          ),
          const SizedBox(height: 2),
          Text('Total earned', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          // Progress to next level
          Stack(children: [
            Container(height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 4)],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${(progress * 100).toInt()}% to Lv ${(user?.level ?? 1) + 1}',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Streak card ─────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final UserModel? user;
  const _StreakCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final streak = user?.streakCount ?? 0;
    final best = user?.longestStreak ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.1), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.fireGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(child: Text('🔥', style: TextStyle(fontSize: 16))),
            ),
            const Spacer(),
            Text('STREAK', style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.coral)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          _AnimatedCount(
            value: streak,
            style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.coral),
            suffix: ' Days',
          ),
          const SizedBox(height: 2),
          Text('Best: $best days', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Row(children: List.generate(7, (i) {
            final active = i < (streak % 7 == 0 ? 7 : streak % 7);
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: active ? AppColors.coral : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          })),
          const SizedBox(height: 4),
          Text('This week', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Animated count-up ────────────────────────────────────────
class _AnimatedCount extends StatefulWidget {
  final int value;
  final TextStyle style;
  final String suffix;
  const _AnimatedCount({required this.value, required this.style, this.suffix = ''});
  @override
  State<_AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<_AnimatedCount> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        '${(_anim.value * widget.value).round()}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}

// ─── Active level card ────────────────────────────────────────
class _ActiveLevelCard extends StatefulWidget {
  final RoadmapModel roadmap;
  const _ActiveLevelCard({required this.roadmap});
  @override
  State<_ActiveLevelCard> createState() => _ActiveLevelCardState();
}

class _ActiveLevelCardState extends State<_ActiveLevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderCtrl;
  late Animation<double> _borderAnim;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _borderAnim = CurvedAnimation(parent: _borderCtrl, curve: Curves.linear);
  }

  @override
  void dispose() { _borderCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.roadmap;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.map}/${r.id}'),
      child: AnimatedBuilder(
        animation: _borderAnim,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: math.pi * 2,
              transform: GradientRotation(_borderAnim.value * math.pi * 2),
              colors: const [
                AppColors.brand, AppColors.coral, AppColors.brand,
              ],
            ),
          ),
          padding: const EdgeInsets.all(1.5),
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl - 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CONTINUE pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text('CONTINUE WHERE YOU LEFT OFF',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.brand, letterSpacing: 0.8)),
              ),
              const SizedBox(height: AppSpacing.sm),
              // World badge
              Text(
                'WORLD ${r.currentLevel}: ${r.type.toUpperCase()}',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Level number gradient
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                child: Text('Level ${r.currentLevel}',
                    style: GoogleFonts.syne(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(r.title,
                  style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (r.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(r.description,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: AppSpacing.base),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              // Info chips row
              Row(children: [
                _InfoChip(icon: '📋', label: r.proofTypeLabel),
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(icon: '⏱', label: '~45 min'),
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(icon: '⚡', label: '150 XP'),
              ]),
              const SizedBox(height: AppSpacing.base),
              StepUpButton(
                label: 'Continue Level',
                onPressed: () => context.push('${AppRoutes.map}/${r.id}'),
              ),
            ],
          ),
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
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ]),
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
        width: 200,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(roadmap.coverEmoji ?? roadmap.typeEmoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              _TypeBadge(roadmap.type),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(roadmap.title,
                style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Stack(children: [
              Container(height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: roadmap.progressPercent,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Level ${roadmap.currentLevel} of ${roadmap.totalLevels}',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
      ),
      child: Text(type.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
              color: AppColors.brand, letterSpacing: 0.6)),
    );
  }
}

// ─── 30-day streak calendar ───────────────────────────────────
class _StreakCalendar extends StatelessWidget {
  final int streakCount;
  const _StreakCalendar({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('30-Day Activity',
            style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(30, (i) {
            final dayIndex = 30 - i;
            final isToday = dayIndex == 1;
            final isCompleted = dayIndex <= streakCount;

            Widget dot = Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCompleted ? AppColors.brandGradient : null,
                color: isCompleted ? null : AppColors.border,
                boxShadow: isToday ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.5), blurRadius: 8)] : null,
              ),
            );

            if (isToday) {
              dot = dot.animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.2, duration: 900.ms);
            }

            return dot;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text('$streakCount Day Streak',
              style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.coral)),
        ]),
      ],
    );
  }
}

// ─── Daily goal ring ─────────────────────────────────────────
class _DailyGoalCard extends StatelessWidget {
  final UserModel? user;
  const _DailyGoalCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final dailyXp = 120;
    final goalXp = 300;
    final progress = (dailyXp / goalXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _RingPainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(progress * 100).toInt()}%',
                        style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Goal',
                    style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text('$dailyXp of $goalXp XP earned today',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                if (progress >= 1.0)
                  Text('🎉 Goal reached!',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green))
                else
                  Text('${goalXp - dailyXp} XP to go',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
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
    final strokeWidth = 8.0;

    // Background ring
    canvas.drawCircle(center, radius, Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round);

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: [AppColors.brand, AppColors.coral])
          .createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Friends activity section ─────────────────────────────────
class _FriendsSection extends StatelessWidget {
  final _mockFriends = const [
    ('Alex K.', 'Completed Level 5 — DSA Basics', '2m ago', 'AK', AppColors.coral),
    ('Sam P.', 'Started a new roadmap', '1h ago', 'SP', AppColors.green),
    ('Maya R.', '🔥 12 day streak!', '3h ago', 'MR', AppColors.brand),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Friends',
                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextButton(
              onPressed: () => context.go(AppRoutes.social),
              child: Text('View All',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _mockFriends.asMap().entries.map((e) {
              final i = e.key;
              final (name, activity, time, initials, color) = e.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Text(initials,
                              style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text(activity,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 560 + i * 80)),
                  if (i < _mockFriends.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
