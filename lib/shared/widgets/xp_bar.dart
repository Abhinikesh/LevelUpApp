import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;
  final bool showLabel;
  final double height;
  final Gradient? gradient;

  const XpBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
    this.showLabel = true,
    this.height = 8.0,
    this.gradient,
  });

  double get _fraction => maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('XP', style: AppTextStyles.label),
                Text(
                  '$currentXp / $maxXp XP',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final fillWidth = totalWidth * _fraction;
            return Stack(
              children: [
                // Track
                Container(
                  width: totalWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(height / 2),
                  ),
                ),
                // Fill — animated
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: fillWidth,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: gradient ?? AppColors.brandGradient,
                    borderRadius:
                        BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0, duration: 400.ms),
              ],
            );
          },
        ),
      ],
    );
  }
}
