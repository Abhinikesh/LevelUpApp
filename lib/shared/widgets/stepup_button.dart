import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

enum StepUpButtonVariant { primary, secondary, danger, success }

class StepUpButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final StepUpButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double borderRadius;

  const StepUpButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = StepUpButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius = AppSpacing.radiusMd,
  });

  const StepUpButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius = AppSpacing.radiusMd,
  }) : variant = StepUpButtonVariant.primary;

  const StepUpButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius = AppSpacing.radiusMd,
  }) : variant = StepUpButtonVariant.secondary;

  const StepUpButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius = AppSpacing.radiusMd,
  }) : variant = StepUpButtonVariant.danger;

  @override
  State<StepUpButton> createState() => _StepUpButtonState();
}

class _StepUpButtonState extends State<StepUpButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (_isDisabled) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  Gradient? get _gradient {
    switch (widget.variant) {
      case StepUpButtonVariant.primary:
        return AppColors.brandGradient;
      case StepUpButtonVariant.danger:
        return AppColors.dangerGradient;
      case StepUpButtonVariant.success:
        return AppColors.greenGradient;
      case StepUpButtonVariant.secondary:
        return null;
    }
  }

  Color get _borderColor {
    switch (widget.variant) {
      case StepUpButtonVariant.secondary:
        return AppColors.brand;
      case StepUpButtonVariant.danger:
        return AppColors.error;
      default:
        return Colors.transparent;
    }
  }


  List<BoxShadow> get _shadows {
    if (_isDisabled) return [];
    switch (widget.variant) {
      case StepUpButtonVariant.primary:
        return [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      case StepUpButtonVariant.danger:
        return [
          BoxShadow(
            color: AppColors.error.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _isDisabled
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onPressed?.call();
            },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedOpacity(
          opacity: _isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.isFullWidth
                ? double.infinity
                : widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: _gradient,
              color: widget.variant == StepUpButtonVariant.secondary
                  ? Colors.transparent
                  : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _borderColor,
                width: widget.variant == StepUpButtonVariant.secondary
                    ? 1.5
                    : 0,
              ),
              boxShadow: _shadows,
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.prefixIcon != null) ...[
                          widget.prefixIcon!,
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(widget.label, style: AppTextStyles.button),
                        if (widget.suffixIcon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          widget.suffixIcon!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
