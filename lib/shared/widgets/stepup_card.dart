import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class StepUpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool hasGradientBorder;
  final bool hasGlow;
  final Color? glowColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const StepUpCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.hasGradientBorder = false,
    this.hasGlow = false,
    this.glowColor,
    this.borderRadius = AppSpacing.radiusLg,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasGradientBorder
            ? null
            : Border.all(color: AppColors.border, width: 1),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.brand).withOpacity(0.2),
                  blurRadius: AppSpacing.shadowBlur,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: child,
    );

    // Gradient border using a Stack + DecoratedBox outer container
    if (hasGradientBorder) {
      card = Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(1.5), // border thickness
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: hasGlow
              ? [
                  BoxShadow(
                    color:
                        (glowColor ?? AppColors.brand).withOpacity(0.25),
                    blurRadius: AppSpacing.shadowBlur,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Container(
          padding:
              padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.bgCard,
            borderRadius:
                BorderRadius.circular(borderRadius - 1.5),
          ),
          child: child,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
