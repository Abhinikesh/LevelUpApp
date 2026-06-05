import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/level_model.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_card.dart';

class LevelDetailScreen extends ConsumerWidget {
  final String levelId;
  const LevelDetailScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Level is passed via GoRouter extra; fallback to null
    final extra = GoRouterState.of(context).extra;
    final LevelModel? level = extra is LevelModel ? extra : null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Level ${level?.levelNumber ?? ''}', style: AppTextStyles.h3),
      ),
      body: level == null
          ? const Center(
              child: Text('Level not found',
                  style: TextStyle(color: AppColors.textSecondary)))
          : _LevelDetailBody(level: level),
    );
  }
}

class _LevelDetailBody extends StatelessWidget {
  final LevelModel level;
  const _LevelDetailBody({required this.level});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          StepUpCard(
            hasGradientBorder: level.state == LevelState.active,
            hasGlow: level.state == LevelState.active,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(level.proofTypeIcon,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.title, style: AppTextStyles.h3),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.timer_outlined,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(level.estimatedTime,
                                style: AppTextStyles.bodySmall),
                            const SizedBox(width: AppSpacing.md),
                            const Icon(Icons.bolt,
                                size: 14, color: AppColors.gold),
                            const SizedBox(width: 2),
                            Text('+${level.xpReward} XP',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.gold)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                if (level.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.md),
                  Text(level.description, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.xl),

          // Topics
          if (level.topics.isNotEmpty) ...[
            Text('Topics Covered', style: AppTextStyles.h4)
                .animate().fadeIn(delay: 150.ms),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: level.topics.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                        color: AppColors.brand.withOpacity(0.3)),
                  ),
                  child: Text(t,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.brand)),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Proof type info
          StepUpCard(
            backgroundColor: AppColors.bgCardLight,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(level.proofTypeIcon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verification Type', style: AppTextStyles.label),
                      Text(
                        AppHelpers.capitalize(level.proofType),
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: AppSpacing.xxxl),

          // CTA
          if (level.state == LevelState.active)
            StepUpButton(
              label: 'Start Level ⚡',
              onPressed: () => context.push(
                '${AppRoutes.verification}/${level.id}/${level.proofType}',
                extra: level,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0, delay: 400.ms)
          else if (level.state == LevelState.completed)
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                gradient: AppColors.greenGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Completed!',
                      style: AppTextStyles.button),
                  if (level.completedAt != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppHelpers.timeAgo(level.completedAt!),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 400.ms)
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Complete previous levels to unlock',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
