import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/level_model.dart';
import '../../../shared/providers/level_provider.dart' hide LevelState;

class LevelDetailScreen extends ConsumerWidget {
  final String levelId;
  const LevelDetailScreen({super.key, required this.levelId});

  LinearGradient _heroGradient(String proofType) {
    switch (proofType) {
      case 'quiz':
        return AppColors.brandGradient;
      case 'code':
        return AppColors.greenGradient;
      case 'photo':
      case 'screenshot':
        return AppColors.fireGradient;
      case 'voice':
        return AppColors.purpleGradient;
      case 'timer':
        return AppColors.goldGradient;
      default:
        return AppColors.brandGradient;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelByIdProvider(levelId));

    if (level == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      );
    }

    final isCompleted = level.state == LevelState.completed;
    final isActive = level.state == LevelState.active;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero area ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.28,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderLight.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: _heroGradient(level.proofType),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid pattern Overlay
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=300&auto=format&fit=crop',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // World Badge
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'WORLD ${((level.levelNumber - 1) ~/ 5) + 1}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    // Large Backdrop Level Number
                    Positioned(
                      bottom: -15,
                      child: Text(
                        level.levelNumber.toString().padLeft(2, '0'),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.12),
                          letterSpacing: -6,
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                            begin: const Offset(0.9, 0.9),
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                    // Proof Type Icon
                    Positioned(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          level.proofTypeIcon,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ).animate().scale(
                            begin: const Offset(0.7, 0.7),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body content ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                24,
                AppSpacing.pagePadding,
                140, // Space for fixed bottom bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    level.title,
                    style: GoogleFonts.spaceMono(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    level.description.isNotEmpty
                        ? level.description
                        : 'Learn and test your mastery of this skill to progress on your roadmap.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 24),

                  // Topics covered
                  if (level.topics.isNotEmpty) ...[
                    Text(
                      'Topics Covered',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: level.topics
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 24),
                  ],

                  // Info Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          emoji: level.proofTypeIcon,
                          label: 'Method',
                          value: level.proofTypeLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          emoji: '⏱️',
                          label: 'Time',
                          value: level.estimatedTime,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          emoji: '⚡',
                          label: 'XP Reward',
                          value: '+${level.xpReward}',
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // AI Coach card
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.coach),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.brand.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.smart_toy_outlined,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stuck? Ask ARIA',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your AI coach is ready to help',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Fixed Bottom Bar ───────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted) ...[
              // Completed Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Level Completed! 🎉',
                      style: GoogleFonts.spaceMono(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (level.completedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Completed ${AppHelpers.timeAgo(level.completedAt!)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ] else if (isActive) ...[
              // Start Button
              GestureDetector(
                onTap: () => context.push(
                  '${AppRoutes.verification}/${level.id}/${level.proofType}',
                ),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.4),
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
                          'Start Level',
                          style: GoogleFonts.spaceMono(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.bolt, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete verification to earn +${level.xpReward} XP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              // Locked Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Level Locked',
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete previous levels first to unlock.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _InfoCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
