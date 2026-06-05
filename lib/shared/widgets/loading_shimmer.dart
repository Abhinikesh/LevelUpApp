import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

// ─────────────────────────────────────────────────────────────
// Base shimmer wrapper
// ─────────────────────────────────────────────────────────────

class _ShimmerBase extends StatelessWidget {
  final Widget child;

  const _ShimmerBase({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.bgCard,
      highlightColor: AppColors.bgCardLight,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

Widget _shimmerBox({
  double? width,
  double? height,
  double radius = AppSpacing.radiusMd,
}) {
  return Container(
    width: width,
    height: height ?? 16,
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// ShimmerCard  — mirrors a roadmap / content card
// ─────────────────────────────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBox(width: 40, height: 40, radius: 12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: double.infinity, height: 14),
                      const SizedBox(height: 6),
                      _shimmerBox(width: 120, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _shimmerBox(width: double.infinity, height: 8, radius: 4),
            const SizedBox(height: 6),
            _shimmerBox(width: 160, height: 8, radius: 4),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ShimmerList  — a column of shimmer rows
// ─────────────────────────────────────────────────────────────

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final double spacing;

  const ShimmerList({
    super.key,
    this.count = 4,
    this.itemHeight = 120,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < count - 1 ? spacing : 0,
          ),
          child: ShimmerCard(height: itemHeight),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ShimmerCircle  — avatar / badge placeholder
// ─────────────────────────────────────────────────────────────

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = AppSpacing.avatarMd});

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ShimmerText  — single line of text placeholder
// ─────────────────────────────────────────────────────────────

class ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerText({
    super.key,
    this.width = 120,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: _shimmerBox(width: width, height: height),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ShimmerLevelNode  — map node placeholder
// ─────────────────────────────────────────────────────────────

class ShimmerLevelNode extends StatelessWidget {
  const ShimmerLevelNode({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 6),
          _shimmerBox(width: 60, height: 10),
        ],
      ),
    );
  }
}
