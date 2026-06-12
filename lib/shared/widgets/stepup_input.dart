import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

class StepUpInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<String>? autofillHints;

  const StepUpInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.autofillHints,
  });

  @override
  State<StepUpInput> createState() => _StepUpInputState();
}

class _StepUpInputState extends State<StepUpInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label ─────────────────────────────────────────────
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
        ],

        // ── Input field ───────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: _isFocused && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : hasError
                    ? [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            readOnly: widget.readOnly,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            autofocus: widget.autofocus,
            autofillHints: widget.autofillHints,
            style: AppTextStyles.bodyMedium,
            cursorColor: AppColors.brand,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.bgDark,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.inputPadding,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.sm,
                      ),
                      child: widget.prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: widget.obscureText
                  ? GestureDetector(
                      onTap: () =>
                          setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: AppSpacing.iconMd,
                      ),
                    )
                  : widget.suffixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.md,
                          ),
                          child: widget.suffixIcon,
                        )
                      : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(height: 0), // handled below
              counterText: '',
            ),
          ),
        ),

        // ── Error / helper text ───────────────────────────────
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 13,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.helperText!, style: AppTextStyles.bodySmall),
        ],
      ],
    );
  }
}
