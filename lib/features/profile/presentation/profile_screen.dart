import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_card.dart';
import '../../../shared/widgets/streak_badge.dart';
import '../../../shared/widgets/xp_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roadmapState = ref.watch(roadmapProvider);
    final completed = roadmapState.roadmaps.where((r) => r.isCompleted).length;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textPrimary),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1040), Color(0xFF0A0A0F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.brand.withOpacity(0.2),
                            backgroundImage: user.avatar.isNotEmpty
                                ? NetworkImage(user.avatar)
                                : null,
                            child: user.avatar.isEmpty
                                ? Text(
                                    AppHelpers.initials(user.name),
                                    style: AppTextStyles.h2
                                        .copyWith(color: AppColors.brand),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.bgDark, width: 2),
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: AppSpacing.md),
                      Text(user.name, style: AppTextStyles.h3)
                          .animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 4),
                      Text(user.email,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary))
                          .animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // XP + Level
                StepUpCard(
                  hasGlow: true,
                  glowColor: AppColors.brand,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat('Level', '${user.level}', AppColors.brand),
                          Container(
                              width: 1, height: 40, color: AppColors.border),
                          _Stat('XP', AppHelpers.formatXP(user.xpTotal),
                              AppColors.gold),
                          Container(
                              width: 1, height: 40, color: AppColors.border),
                          _Stat('Done', '$completed', AppColors.green),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      XpBar(
                        currentXp: user.xpTotal % user.xpToNextLevel,
                        maxXp: user.xpToNextLevel,
                        showLabel: true,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: AppSpacing.md),

                // Streak card
                StepUpCard(
                  child: Row(
                    children: [
                      StreakBadge(
                          streak: user.streakCount,
                          size: StreakBadgeSize.large),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${user.streakCount} day streak!',
                                style: AppTextStyles.h4),
                            const SizedBox(height: 4),
                            Text(
                              'Longest: ${user.longestStreak} days',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: AppSpacing.md),

                // Badges
                if (user.badges.isNotEmpty) ...[
                  Text('Badges', style: AppTextStyles.h3)
                      .animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: user.badges.map((b) {
                      return Tooltip(
                        message: b.badgeName,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.bgCardLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text(b.icon,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Logout
                StepUpButton.danger(
                  label: 'Sign Out',
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}
