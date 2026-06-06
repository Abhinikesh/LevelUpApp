import 'dart:math' as math;
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

enum _VoicePhase { intro, recording, processing, result }

class VoiceVerificationScreen extends ConsumerStatefulWidget {
  final String levelId;
  const VoiceVerificationScreen({super.key, required this.levelId});

  @override
  ConsumerState<VoiceVerificationScreen> createState() =>
      _VoiceVerificationScreenState();
}

class _VoiceVerificationScreenState
    extends ConsumerState<VoiceVerificationScreen>
    with TickerProviderStateMixin {
  _VoicePhase _phase = _VoicePhase.intro;
  int _seconds = 0;
  bool _passed = false;
  late final AnimationController _micPulse;
  late final AnimationController _waveCtrl;
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..repeat(reverse: true);
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _micPulse.dispose();
    _waveCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _phase = _VoicePhase.recording;
      _seconds = 0;
    });
    _runTimer();
  }

  void _runTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _phase != _VoicePhase.recording) return;
      setState(() => _seconds++);
      if (_seconds < 120) _runTimer(); // max 2 minutes
    });
  }

  Future<void> _stopRecording() async {
    setState(() => _phase = _VoicePhase.processing);
    await Future.delayed(const Duration(seconds: 2));
    // 70% pass in demo mode
    final passed = DateTime.now().millisecond % 10 < 7;
    setState(() {
      _passed = passed;
      _phase = _VoicePhase.result;
    });
    if (passed) {
      _confetti.play();
      ref
          .read(levelProvider(widget.levelId.split('-level-').first).notifier)
          .verifyAndCompleteLevel(
            levelId: widget.levelId,
            proofType: 'voice',
            proofData: {
              'transcript': 'Mock voice response explaining the concepts.',
              'passed': passed,
            },
          );
    }
  }

  String get _timerStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
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
                _VoicePhase.intro => _VoiceIntro(
                    key: const ValueKey('intro'),
                    level: level,
                    onStart: _startRecording,
                  ),
                _VoicePhase.recording => _VoiceRecording(
                    key: const ValueKey('recording'),
                    timerStr: _timerStr,
                    micPulse: _micPulse,
                    waveCtrl: _waveCtrl,
                    onStop: _stopRecording,
                  ),
                _VoicePhase.processing => _VoiceProcessing(
                    key: const ValueKey('processing'),
                  ),
                _VoicePhase.result => _VoiceResult(
                    key: const ValueKey('result'),
                    passed: _passed,
                    level: level,
                    onContinue: () => context.pop(),
                    onRetry: () =>
                        setState(() => _phase = _VoicePhase.intro),
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
class _VoiceIntro extends StatelessWidget {
  final LevelModel? level;
  final VoidCallback onStart;
  const _VoiceIntro({super.key, required this.level, required this.onStart});

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
            child: const Icon(Icons.mic_outlined,
                color: Colors.white, size: 48),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text('Voice Explanation',
              style: GoogleFonts.syne(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          if (level != null)
            Text('Explain "${level!.title}" in your own words',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary,
                    height: 1.5),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          // Tips card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 Tips',
                    style: GoogleFonts.syne(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                ...[
                  'Cover the main concepts',
                  'Use examples if possible',
                  '2 minutes maximum',
                ].map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 14, color: AppColors.green),
                          const SizedBox(width: 8),
                          Text(t,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const Spacer(),
          GestureDetector(
            onTap: onStart,
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
                  const Icon(Icons.mic, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('Start Recording',
                      style: GoogleFonts.syne(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Recording ─────────────────────────────────────────────────
class _VoiceRecording extends StatelessWidget {
  final String timerStr;
  final AnimationController micPulse;
  final AnimationController waveCtrl;
  final VoidCallback onStop;

  const _VoiceRecording({
    super.key,
    required this.timerStr,
    required this.micPulse,
    required this.waveCtrl,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic with pulse ring
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: micPulse,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + 0.4 * micPulse.value,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 1 - micPulse.value),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.dangerGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.5),
                      blurRadius: 30, spreadRadius: 4)],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 44),
              ),
            ],
          ).animate().scale(duration: 300.ms),
          const SizedBox(height: 32),
          // Timer
          Text(timerStr,
              style: GoogleFonts.syne(
                  fontSize: 40, fontWeight: FontWeight.w900,
                  color: AppColors.brand))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 8),
          Text('Recording...', style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          // Live transcript area
          Container(
            height: 120, width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: Text(
                'Listening...',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Waveform
          _WaveformWidget(ctrl: waveCtrl),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: onStop,
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.dangerGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stop_circle_outlined,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('Stop Recording',
                      style: GoogleFonts.syne(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformWidget extends StatelessWidget {
  final AnimationController ctrl;
  const _WaveformWidget({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const barCount = 25;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final rng = math.sin((i + ctrl.value * 10) * 0.8) * 0.5 + 0.5;
              final h = 6 + 34 * rng;
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.4 + rng * 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ─── Processing ────────────────────────────────────────────────
class _VoiceProcessing extends StatelessWidget {
  const _VoiceProcessing({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(
                color: AppColors.brand, strokeWidth: 3),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1000.ms),
          const SizedBox(height: 24),
          Text('ARIA is evaluating...',
              style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text('Analysing your explanation',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 800.ms),
        ],
      ),
    );
  }
}

// ─── Result ────────────────────────────────────────────────────
class _VoiceResult extends StatelessWidget {
  final bool passed;
  final LevelModel? level;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const _VoiceResult({
    super.key,
    required this.passed,
    required this.level,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: passed ? AppColors.greenGradient : AppColors.fireGradient,
            ),
            child: Icon(
              passed ? Icons.check_rounded : Icons.refresh_rounded,
              color: Colors.white, size: 52,
            ),
          ).animate().scale(
              begin: const Offset(0.3, 0.3),
              duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            passed ? 'Great Explanation! 🎉' : 'Keep Practicing',
            style: GoogleFonts.syne(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: passed ? AppColors.green : AppColors.warning,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          if (passed) ...[
            Text('+${level?.xpReward ?? 100} XP earned',
                style: GoogleFonts.syne(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.gold))
                .animate()
                .moveY(begin: 20, end: 0, delay: 300.ms)
                .fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
            _ConceptList(
              label: 'Concepts covered well',
              concepts: ['Core definition', 'Key properties', 'Use cases'],
              color: AppColors.green,
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 8),
            _ConceptList(
              label: 'Needs more explanation',
              concepts: ['Time complexity analysis', 'Edge cases', 'Examples'],
              color: AppColors.warning,
            ),
            const SizedBox(height: 24),
            Text(
              'Try explaining more slowly and use concrete examples from your learning.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ConceptList extends StatelessWidget {
  final String label;
  final List<String> concepts;
  final Color color;
  const _ConceptList(
      {required this.label, required this.concepts, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.syne(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: concepts
              .map((c) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(c,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: color,
                            fontWeight: FontWeight.w500)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
