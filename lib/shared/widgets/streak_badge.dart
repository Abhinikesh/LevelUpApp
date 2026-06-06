import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum StreakBadgeSize { small, medium, large }

class StreakBadge extends StatelessWidget {
  final int streak;
  final StreakBadgeSize size;
  final bool animated;

  const StreakBadge({
    super.key,
    required this.streak,
    this.size = StreakBadgeSize.medium,
    this.animated = true,
  });

  double get _height {
    switch (size) {
      case StreakBadgeSize.small:
        return 28;
      case StreakBadgeSize.medium:
        return 36;
      case StreakBadgeSize.large:
        return 52;
    }
  }

  double get _hPadding {
    switch (size) {
      case StreakBadgeSize.small:
        return 8;
      case StreakBadgeSize.medium:
        return 12;
      case StreakBadgeSize.large:
        return 18;
    }
  }

  double get _emojiSize {
    switch (size) {
      case StreakBadgeSize.small:
        return 14;
      case StreakBadgeSize.medium:
        return 18;
      case StreakBadgeSize.large:
        return 26;
    }
  }

  TextStyle get _textStyle {
    switch (size) {
      case StreakBadgeSize.small:
        return AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
      case StreakBadgeSize.medium:
        return AppTextStyles.labelLarge.copyWith(color: Colors.white);
      case StreakBadgeSize.large:
        return AppTextStyles.streakNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: _hPadding),
      decoration: BoxDecoration(
        gradient: AppColors.fireGradient,
        borderRadius: BorderRadius.circular(100),
        boxShadow: streak > 0
            ? [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: _emojiSize)),
          const SizedBox(width: 4),
          Text(
            streak.toString(),
            style: _textStyle,
          ),
        ],
      ),
    );

    if (!animated || streak == 0) return badge;

    // Pulsing glow animation for active streaks
    return badge
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .custom(
          duration: 1500.ms,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C00)
                        .withValues(alpha: 0.15 + 0.25 * value),
                    blurRadius: 8 + 12 * value,
                    spreadRadius: value * 2,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
  }
}
