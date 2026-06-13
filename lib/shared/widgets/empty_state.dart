import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import 'stepup_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? emoji;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final bool animate;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.emoji,
    this.ctaLabel,
    this.onCtaTap,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget illustration = Text(
      emoji ?? '🗺️',
      style: const TextStyle(fontSize: 72),
    );

    // Gentle floating animation on illustration
    if (animate) {
      illustration = illustration
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: -10,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        illustration,
        const SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (ctaLabel != null && onCtaTap != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 200,
            child: StepUpButton(
              label: ctaLabel!,
              onPressed: onCtaTap,
              isFullWidth: false,
              width: 200,
            ),
          ),
        ],
      ],
    );

    if (animate) {
      content = content
          .animate()
          .fadeIn(duration: 500.ms, delay: 150.ms)
          .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 150.ms);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }
}

// ── Preset empty states ───────────────────────────────────────

class EmptyRoadmaps extends StatelessWidget {
  final VoidCallback? onCreateTap;
  const EmptyRoadmaps({super.key, this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '🗺️',
      title: 'No Roadmaps Yet',
      subtitle:
          'Create your first roadmap and start levelling up your skills.',
      ctaLabel: '+ Create Roadmap',
      onCtaTap: onCreateTap,
    );
  }
}

class EmptyFriends extends StatelessWidget {
  final VoidCallback? onAddTap;
  const EmptyFriends({super.key, this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '🤝',
      title: 'No Friends Yet',
      subtitle:
          'Add friends to compete on the leaderboard and share progress.',
      ctaLabel: 'Find Friends',
      onCtaTap: onAddTap,
    );
  }
}

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      emoji: '🔔',
      title: 'All Caught Up!',
      subtitle: 'No new notifications. Keep levelling up!',
    );
  }
}

class EmptyBadges extends StatelessWidget {
  const EmptyBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      emoji: '🏅',
      title: 'No Badges Yet',
      subtitle: 'Complete levels and streaks to earn your first badge.',
    );
  }
}

class EmptyLeaderboard extends StatelessWidget {
  const EmptyLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      emoji: '🏆',
      title: 'Leaderboard Empty',
      subtitle: 'Add friends and earn XP to appear on the leaderboard.',
    );
  }
}

class EmptyAchievements extends StatelessWidget {
  const EmptyAchievements({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      emoji: '⭐',
      title: 'No Achievements Yet',
      subtitle: 'Keep levelling up to unlock achievements!',
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '⚠️',
      title: 'Something went wrong',
      subtitle: message,
      ctaLabel: onRetry != null ? 'Try Again' : null,
      onCtaTap: onRetry,
    );
  }
}
