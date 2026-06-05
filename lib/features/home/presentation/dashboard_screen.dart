import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/roadmap_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/stepup_card.dart';
import '../../../shared/widgets/streak_badge.dart';
import '../../../shared/widgets/xp_bar.dart';

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
    final activeRoadmaps = ref.watch(activeRoadmapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            flexibleSpace: FlexibleSpaceBar(
              background: _DashboardHeader(
                userName: user?.name ?? 'Explorer',
                streakCount: user?.streakCount ?? 0,
                xpTotal: user?.xpTotal ?? 0,
                level: user?.level ?? 1,
                xpToNext: user?.xpToNextLevel ?? 500,
                levelProgress: user?.levelProgress ?? 0,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // AI Coach CTA
                _CoachBanner()
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1, end: 0, delay: 200.ms),

                const SizedBox(height: AppSpacing.xl),

                // Active Roadmaps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Roadmaps', style: AppTextStyles.h3),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.create),
                      child: Text('+ New',
                          style: AppTextStyles.label.copyWith(color: AppColors.brand)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                if (roadmapState.isLoading && !roadmapState.hasLoaded)
                  const ShimmerList(count: 3, itemHeight: 130)
                else if (activeRoadmaps.isEmpty)
                  EmptyRoadmaps(onCreateTap: () => context.push(AppRoutes.create))
                else
                  ...activeRoadmaps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final roadmap = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RoadmapCard(roadmap: roadmap)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 + i * 80))
                          .slideY(begin: 0.1, end: 0,
                              delay: Duration(milliseconds: 100 + i * 80)),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final int streakCount;
  final int xpTotal;
  final int level;
  final int xpToNext;
  final double levelProgress;

  const _DashboardHeader({
    required this.userName,
    required this.streakCount,
    required this.xpTotal,
    required this.level,
    required this.xpToNext,
    required this.levelProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        bottom: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF12082A), Color(0xFF0A0A0F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hey, ${userName.split(' ').first} 👋',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary)),
                    Text('Level $level', style: AppTextStyles.h2),
                  ],
                ),
              ),
              StreakBadge(streak: streakCount, size: StreakBadgeSize.medium),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 3),
                    Text(AppHelpers.formatXP(xpTotal),
                        style: AppTextStyles.label.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          XpBar(currentXp: xpTotal % xpToNext, maxXp: xpToNext, showLabel: false),
          const SizedBox(height: 4),
          Text(
            '${AppHelpers.formatXP(xpTotal % xpToNext)} / ${AppHelpers.formatXP(xpToNext)} XP to Level ${level + 1}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _CoachBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.coach),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1040), Color(0xFF12121A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.brand.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Coach', style: AppTextStyles.h4),
                  Text('Get personalised advice for your goals',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.brand, size: 16),
          ],
        ),
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  final RoadmapModel roadmap;
  const _RoadmapCard({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    return StepUpCard(
      onTap: () => context.push('${AppRoutes.map}/${roadmap.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(roadmap.coverEmoji ?? roadmap.typeEmoji,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roadmap.title,
                        style: AppTextStyles.h4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _Tag(roadmap.type),
                        if (roadmap.examMode) ...[
                          const SizedBox(width: 6),
                          _Tag('Exam Mode', color: AppColors.coral),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${roadmap.currentLevel}/${roadmap.totalLevels}',
                      style: AppTextStyles.label.copyWith(color: AppColors.brand)),
                  Text('levels', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: roadmap.progressPercent,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(roadmap.progressPercent * 100).toInt()}% complete',
                  style: AppTextStyles.caption),
              if (roadmap.daysRemaining >= 0)
                Text(
                  roadmap.isUrgent
                      ? '⚠️ ${roadmap.daysRemaining}d left'
                      : '${roadmap.daysRemaining}d left',
                  style: AppTextStyles.caption.copyWith(
                    color: roadmap.isUrgent ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  const _Tag(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.tag.copyWith(color: c, fontSize: 10),
      ),
    );
  }
}
