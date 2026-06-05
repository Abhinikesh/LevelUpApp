import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_card.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String proofType;

  const VerificationScreen({
    super.key,
    required this.levelId,
    required this.proofType,
  });

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _answerCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _completed = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    // In a real app, roadmapId would be passed or looked up
    // For now we use a placeholder — providers are family-keyed by roadmapId
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() { _isSubmitting = false; _completed = true; });
  }

  String get _emoji {
    switch (widget.proofType) {
      case 'quiz':   return '🧠';
      case 'photo':  return '📸';
      case 'code':   return '💻';
      case 'voice':  return '🎤';
      case 'timer':  return '⏱️';
      case 'screenshot': return '🖼️';
      default:       return '✍️';
    }
  }

  String get _instruction {
    switch (widget.proofType) {
      case 'quiz':   return 'Answer the questions below to prove mastery.';
      case 'photo':  return 'Take or upload a photo as proof of completion.';
      case 'code':   return 'Paste your code solution below.';
      case 'voice':  return 'Record a voice note explaining what you learned.';
      case 'timer':  return 'Complete the timed task and submit when done.';
      case 'screenshot': return 'Upload a screenshot as your proof.';
      default:       return 'Describe what you completed in the box below.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Verification', style: AppTextStyles.h3),
      ),
      body: _completed
          ? _CompletionView(onDone: () => context.pop())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brand.withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(_emoji,
                                style: const TextStyle(fontSize: 36)),
                          ),
                        )
                            .animate()
                            .scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '${_emoji}  Proof of Completion',
                          style: AppTextStyles.h3,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _instruction,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Input area
                  if (widget.proofType == 'photo' ||
                      widget.proofType == 'screenshot') ...[
                    _MediaUploadBox().animate().fadeIn(delay: 350.ms),
                  ] else ...[
                    StepUpCard(
                      child: TextField(
                        controller: _answerCtrl,
                        maxLines: widget.proofType == 'code' ? 10 : 5,
                        style: widget.proofType == 'code'
                            ? AppTextStyles.bodySmall.copyWith(
                                fontFamily: 'monospace',
                                color: AppColors.green,
                              )
                            : AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.proofType == 'code'
                              ? '// Paste your code here...'
                              : 'Describe what you accomplished...',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textMuted),
                        ),
                        cursorColor: AppColors.brand,
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ],

                  const SizedBox(height: AppSpacing.xxxl),

                  StepUpButton(
                    label: 'Submit Proof ⚡',
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ).animate().fadeIn(delay: 450.ms),
                ],
              ),
            ),
    );
  }
}

class _MediaUploadBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.brand.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.brand, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text('Tap to upload photo',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('PNG, JPG up to 10MB',
                style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final VoidCallback onDone;
  const _CompletionView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -8, duration: 1000.ms),
            const SizedBox(height: AppSpacing.xl),
            Text('Level Complete!', style: AppTextStyles.h1, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text('+100 XP', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).scale(delay: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xxxl),
            StepUpButton(
              label: 'Continue',
              onPressed: onDone,
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}
