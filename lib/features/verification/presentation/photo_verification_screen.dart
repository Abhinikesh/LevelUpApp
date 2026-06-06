import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/level_model.dart';
import '../../../shared/providers/level_provider.dart';

enum _PhotoPhase { intro, preview, result }

class PhotoVerificationScreen extends ConsumerStatefulWidget {
  final String levelId;
  const PhotoVerificationScreen({super.key, required this.levelId});

  @override
  ConsumerState<PhotoVerificationScreen> createState() =>
      _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState
    extends ConsumerState<PhotoVerificationScreen> {
  _PhotoPhase _phase = _PhotoPhase.intro;
  bool _verified = false;
  bool _processing = false;
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _submitPhoto() async {
    setState(() => _processing = true);
    // Simulate AI verification
    await Future.delayed(const Duration(seconds: 2));
    // 80% pass rate in demo mode
    final passed = DateTime.now().millisecond % 10 < 8;
    setState(() {
      _processing = false;
      _verified = passed;
      _phase = _PhotoPhase.result;
    });
    if (passed) {
      _confetti.play();
      ref
          .read(levelProvider(widget.levelId.split('-level-').first).notifier)
          .verifyAndCompleteLevel(
            levelId: widget.levelId,
            proofType: 'photo',
            proofUrl: 'mock_uploaded_photo.jpg',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(levelByIdProvider(widget.levelId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedSwitcher(
              duration: 300.ms,
              child: switch (_phase) {
                _PhotoPhase.intro => _PhotoIntro(
                    key: const ValueKey('intro'),
                    level: level,
                    onTakePhoto: () =>
                        setState(() => _phase = _PhotoPhase.preview),
                  ),
                _PhotoPhase.preview => _PhotoPreview(
                    key: const ValueKey('preview'),
                    level: level,
                    processing: _processing,
                    onRetake: () => setState(() => _phase = _PhotoPhase.intro),
                    onSubmit: _submitPhoto,
                  ),
                _PhotoPhase.result => _PhotoResult(
                    key: const ValueKey('result'),
                    verified: _verified,
                    level: level,
                    onContinue: () => context.pop(),
                    onRetry: () =>
                        setState(() => _phase = _PhotoPhase.intro),
                  ),
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              colors: const [
                AppColors.brand, AppColors.coral, AppColors.green, AppColors.gold,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Intro ─────────────────────────────────────────────────────
class _PhotoIntro extends StatelessWidget {
  final LevelModel? level;
  final VoidCallback onTakePhoto;
  const _PhotoIntro({super.key, required this.level, required this.onTakePhoto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgCard, shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 16),
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_outlined,
                color: Colors.white, size: 48),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text('Photo Proof',
              style: GoogleFonts.syne(
                  fontSize: 30, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          if (level != null)
            Text(level!.title,
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.brand,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          Text('Submit a photo showing your progress or work done',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center)
              .animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 20),
          // Accepted examples
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8, runSpacing: 8,
            children: ['Notes 📝', 'Screenshot 🖥️', 'Work Done ✅', 'Notebook 📒']
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(e,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ))
                .toList(),
          ).animate().fadeIn(delay: 400.ms),
          const Spacer(),
          GestureDetector(
            onTap: onTakePhoto,
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.4),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Take Photo',
                      style: GoogleFonts.syne(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onTakePhoto,
            child: Text('Choose from Gallery',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.brand,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Preview ───────────────────────────────────────────────────
class _PhotoPreview extends StatelessWidget {
  final LevelModel? level;
  final bool processing;
  final VoidCallback onRetake;
  final VoidCallback onSubmit;

  const _PhotoPreview({
    super.key,
    required this.level,
    required this.processing,
    required this.onRetake,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onRetake,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.textPrimary, size: 16),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onRetake,
                child: Text('Retake',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.brand)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder image
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_outlined,
                    color: AppColors.textMuted, size: 60),
                const SizedBox(height: 12),
                Text('Photo Preview',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('(Camera not available on web)',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined,
                    color: AppColors.brand, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'AI will verify this relates to: '),
                        TextSpan(
                          text: level?.title ?? 'your level',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.brand,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (processing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: AppColors.brand, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('AI is checking...',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary)),
              ],
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 500.ms),
          ] else
            GestureDetector(
              onTap: onSubmit,
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.4),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: Text('Submit for Verification',
                      style: GoogleFonts.syne(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Result ────────────────────────────────────────────────────
class _PhotoResult extends StatelessWidget {
  final bool verified;
  final LevelModel? level;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const _PhotoResult({
    super.key,
    required this.verified,
    required this.level,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: verified
                  ? AppColors.greenGradient
                  : AppColors.dangerGradient,
            ),
            child: Icon(
              verified ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white, size: 52,
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 500.ms,
                  curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 24),
          Text(
            verified ? '✅ Proof Verified!' : 'Not Verified',
            style: GoogleFonts.syne(
              fontSize: 28, fontWeight: FontWeight.w800,
              color: verified ? AppColors.green : AppColors.error,
            ),
          ).animate().fadeIn(delay: 200.ms),
          if (verified) ...[
            const SizedBox(height: 8),
            Text('Confidence: 94%',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary))
                .animate().fadeIn(delay: 300.ms),
          ],
          const SizedBox(height: 12),
          Text(
            verified
                ? 'Great work! Your photo clearly demonstrates the required concept for ${level?.title ?? "this level"}.'
                : 'The submitted photo doesn\'t clearly relate to "${level?.title ?? "this level"}". Please try again with a more relevant image.',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 40),
          if (verified) ...[
            Text('+${level?.xpReward ?? 100} XP',
                style: GoogleFonts.syne(
                    fontSize: 24, fontWeight: FontWeight.w900,
                    color: AppColors.gold))
                .animate()
                .moveY(begin: 30, end: 0, delay: 500.ms)
                .fadeIn(delay: 500.ms),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onContinue,
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.4),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: Text('Continue',
                      style: GoogleFonts.syne(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: onRetry,
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('Try Again',
                      style: GoogleFonts.syne(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/coach'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Switch to Quiz Instead',
                  style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
