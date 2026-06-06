import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../models/level_model.dart';
import '../../../shared/providers/level_provider.dart';

class LevelDetailScreen extends ConsumerWidget {
  final String levelId;
  const LevelDetailScreen({super.key, required this.levelId});

  LinearGradient _heroGradient(String proofType) {
    switch (proofType) {
      case 'quiz': return AppColors.brandGradient;
      case 'code': return const LinearGradient(
          colors: [Color(0xFF0D4A2F), Color(0xFF0A2E1C)]);
      case 'photo': return const LinearGradient(
          colors: [Color(0xFFFF6584), Color(0xFFFF8E53)]);
      case 'voice':
      case 'timer': return AppColors.fireGradient;
      default: return AppColors.purpleGradient;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelByIdProvider(levelId));

    if (level == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      );
    }

    final canStart = level.status == LevelStatus.active;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Hero area ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.30,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
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
                    // World badge top right
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'WORLD ${((level.levelNumber - 1) ~/ 5) + 1}',
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    // Big level number
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${level.levelNumber}',
                          style: GoogleFonts.syne(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ).animate().scale(
                            begin: const Offset(0.7, 0.7),
                            duration: 400.ms,
                            curve: Curves.elasticOut),
                        Text(
                          level.proofTypeIcon,
                          style: const TextStyle(fontSize: 32),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 24,
                  AppSpacing.pagePadding, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(level.title,
                      style: GoogleFonts.syne(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    level.description,
                    style: GoogleFonts.inter(
                        fontSize: 15, color: AppColors.textSecondary,
                        height: 1.6),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 24),

                  // Topics
                  if (level.topics.isNotEmpty) ...[
                    Text('What you\'ll cover',
                        style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: level.topics
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(t,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Info cards row
                  Row(
                    children: [
                      Expanded(
                          child: _InfoCard(
                              emoji: level.proofTypeIcon,
                              label: 'Method',
                              value: level.proofTypeLabel)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _InfoCard(
                              emoji: '⏱️',
                              label: 'Time',
                              value: level.estimatedTime)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _InfoCard(
                              emoji: '⚡',
                              label: 'XP Reward',
                              value: '+${level.xpReward}')),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 20),

                  // AI Coach card
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.coach),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.brand.withValues(alpha: 0.4)),
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
                                Text('Stuck? Ask ARIA',
                                    style: GoogleFonts.syne(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    )),
                                Text('Your AI coach is ready to help',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Fixed bottom bar ───────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24,
            MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('Complete to earn ${level.xpReward} XP',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: canStart
                  ? () => context.push(
                      '${AppRoutes.verification}/${level.id}/${level.proofType}')
                  : null,
              child: AnimatedOpacity(
                opacity: canStart ? 1.0 : 0.5,
                duration: 200.ms,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: canStart
                        ? AppColors.brandGradient
                        : const LinearGradient(
                            colors: [AppColors.border, AppColors.border]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canStart
                        ? [
                            BoxShadow(
                                color: AppColors.brand.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      canStart ? 'Start Level' : 'Level Locked',
                      style: GoogleFonts.syne(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
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

class _InfoCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _InfoCard(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
