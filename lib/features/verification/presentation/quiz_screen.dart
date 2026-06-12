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

// ─── Quiz question model ───────────────────────────────────────
class _Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  const _Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

// ─── Mock question generator ───────────────────────────────────
List<_Question> _generateQuestions(LevelModel level) {
  return [
    _Question(
      question: 'What is the primary concept covered in "${level.title}"?',
      options: [
        'Efficient data organization and retrieval',
        'Random memory allocation',
        'Sequential file processing',
        'CPU scheduling algorithms',
      ],
      correctIndex: 0,
      explanation:
          '${level.title} focuses on efficient data organization and retrieval, which is the core principle of this topic.',
    ),
    _Question(
      question:
          'Which approach is most commonly used when solving ${level.title} problems?',
      options: [
        'Brute force only',
        'Divide and conquer / optimized traversal',
        'Random shuffling',
        'Exhaustive enumeration without optimization',
      ],
      correctIndex: 1,
      explanation:
          'Divide and conquer or optimized traversal is the standard approach, reducing time complexity significantly.',
    ),
    _Question(
      question: 'What is the typical time complexity for a well-optimized solution in this area?',
      options: ['O(n²)', 'O(n log n) or better', 'O(2ⁿ)', 'O(n!)'],
      correctIndex: 1,
      explanation:
          'Well-optimized solutions in this domain run in O(n log n) or better by leveraging the right data structures.',
    ),
    _Question(
      question: 'Which of the following best describes a key property of "${level.title}"?',
      options: [
        'It requires unbounded memory',
        'Order of operations does not matter',
        'It builds on foundational patterns from previous levels',
        'It cannot be combined with other techniques',
      ],
      correctIndex: 2,
      explanation:
          'Like all advanced topics, ${level.title} builds on foundational patterns, making prior knowledge essential.',
    ),
    _Question(
      question: 'When implementing a solution for this level, which is the most important consideration?',
      options: [
        'Using the longest variable names',
        'Avoiding all loops',
        'Correctness first, then optimization',
        'Writing code without comments',
      ],
      correctIndex: 2,
      explanation:
          'Always prioritize correctness first, then optimize. This is a universal principle in software engineering.',
    ),
  ];
}

// ─── Quiz states ───────────────────────────────────────────────
enum _QuizPhase { intro, question, results }

class QuizScreen extends ConsumerStatefulWidget {
  final String levelId;
  const QuizScreen({super.key, required this.levelId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  _QuizPhase _phase = _QuizPhase.intro;
  int _currentQ = 0;
  int? _selected;
  bool _revealed = false;
  final List<int?> _answers = [];
  late final ConfettiController _confetti;
  LevelModel? _level;

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

  late final List<_Question> _q = [];

  void _startQuiz() {
    setState(() {
      _phase = _QuizPhase.question;
      _currentQ = 0;
      _selected = null;
      _revealed = false;
    });
  }

  void _selectOption(int idx) {
    if (_revealed) return;
    setState(() {
      _selected = idx;
      _revealed = true;
      if (_currentQ < _answers.length) {
        _answers[_currentQ] = idx;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQ < _q.length - 1) {
      setState(() {
        _currentQ++;
        _selected = null;
        _revealed = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    setState(() => _phase = _QuizPhase.results);
    final correct = _correctCount;
    if (correct >= (_q.length * 0.8).ceil()) {
      _confetti.play();
      final level = ref.read(levelByIdProvider(widget.levelId));
      final roadmapId = level?.roadmapId ?? widget.levelId.split('-level-').first;
      ref.read(levelProvider(roadmapId).notifier)
          .verifyAndCompleteLevel(
            levelId: widget.levelId,
            proofType: 'quiz',
            proofData: {
              'score': correct,
              'total': _q.length,
            },
          );
    }
  }

  int get _correctCount {
    int c = 0;
    for (int i = 0; i < _answers.length && i < _q.length; i++) {
      if (_answers[i] == _q[i].correctIndex) c++;
    }
    return c;
  }

  bool get _passed => _correctCount >= (_q.length * 0.8).ceil();

  @override
  Widget build(BuildContext context) {
    final levelData = ref.watch(levelByIdProvider(widget.levelId));
    if (levelData != null && _q.isEmpty) {
      _q.addAll(_generateQuestions(levelData));
      for (int i = 0; i < _q.length; i++) _answers.add(null);
      _level = levelData;
    }
    final level = levelData ?? _level;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedSwitcher(
              duration: 300.ms,
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: switch (_phase) {
                _QuizPhase.intro => _IntroView(
                    key: const ValueKey('intro'),
                    level: level,
                    onStart: _startQuiz,
                  ),
                _QuizPhase.question => _QuestionView(
                    key: ValueKey('q$_currentQ'),
                    question: _q.isNotEmpty ? _q[_currentQ] : null,
                    questionIndex: _currentQ,
                    total: _q.length,
                    selected: _selected,
                    revealed: _revealed,
                    isLast: _currentQ == _q.length - 1,
                    onSelect: _selectOption,
                    onNext: _nextQuestion,
                  ),
                _QuizPhase.results => _ResultsView(
                    key: const ValueKey('results'),
                    correct: _correctCount,
                    total: _q.length,
                    passed: _passed,
                    level: level,
                    onContinue: () => context.pop(),
                    onRetry: () {
                      setState(() {
                        _phase = _QuizPhase.intro;
                        _answers.clear();
                        for (int i = 0; i < _q.length; i++) _answers.add(null);
                      });
                    },
                  ),
              },
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              colors: const [
                AppColors.brand, AppColors.coral, AppColors.green,
                AppColors.gold, Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Intro View ────────────────────────────────────────────────
class _IntroView extends StatelessWidget {
  final LevelModel? level;
  final VoidCallback onStart;
  const _IntroView({super.key, required this.level, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          // Back
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
          // Icon
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_outlined, color: Colors.white, size: 44),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 28),
          Text('Quiz Time!',
              style: GoogleFonts.syne(
                  fontSize: 32, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          if (level != null)
            Text(level!.title,
                style: GoogleFonts.inter(
                    fontSize: 16, color: AppColors.brand,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          // Info pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Pill(icon: Icons.help_outline, label: '5 Questions', color: AppColors.brand),
              const SizedBox(width: 10),
              _Pill(icon: Icons.star_outline, label: 'Score 4/5 to pass', color: AppColors.gold),
            ],
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),
          _Pill(
              icon: Icons.bolt,
              label: '+${level?.xpReward ?? 100} XP on pass',
              color: AppColors.green)
              .animate().fadeIn(delay: 500.ms),
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
              child: Center(
                child: Text('Begin Quiz',
                    style: GoogleFonts.syne(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Question View ─────────────────────────────────────────────
class _QuestionView extends StatelessWidget {
  final _Question? question;
  final int questionIndex;
  final int total;
  final int? selected;
  final bool revealed;
  final bool isLast;
  final void Function(int) onSelect;
  final VoidCallback onNext;

  const _QuestionView({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.total,
    required this.selected,
    required this.revealed,
    required this.isLast,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    if (q == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (questionIndex + 1) / total,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${questionIndex + 1}/$total',
                  style: GoogleFonts.syne(
                      fontSize: 13, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 28),

          // Question card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question ${questionIndex + 1}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(q.question,
                    style: GoogleFonts.inter(
                        fontSize: 17, color: AppColors.textPrimary,
                        height: 1.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.1),

          const SizedBox(height: 20),

          // Options
          ...List.generate(q.options.length, (i) {
            final optionLetters = ['A', 'B', 'C', 'D'];
            final isSelected = selected == i;
            final isCorrect = i == q.correctIndex;
            Color borderColor = AppColors.border;
            Color bgColor = AppColors.bgDark;
            Widget? trailing;

            if (revealed) {
              if (isCorrect) {
                borderColor = isSelected
                    ? AppColors.green
                    : AppColors.green.withValues(alpha: 0.4);
                bgColor = AppColors.green.withValues(
                    alpha: isSelected ? 0.12 : 0.05);
                if (isSelected)
                  trailing = const Icon(Icons.check_circle,
                      color: AppColors.green, size: 20);
              } else if (isSelected) {
                borderColor = AppColors.error;
                bgColor = AppColors.error.withValues(alpha: 0.1);
                trailing = const Icon(Icons.cancel,
                    color: AppColors.error, size: 20);
              }
            } else if (isSelected) {
              borderColor = AppColors.brand;
              bgColor = AppColors.brand.withValues(alpha: 0.1);
            }

            return GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(optionLetters[i],
                            style: GoogleFonts.syne(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(q.options[i],
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textPrimary)),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
              ).animate().fadeIn(
                  delay: Duration(milliseconds: i * 80),
                  duration: 250.ms),
            );
          }),

          // Explanation
          if (revealed) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Explanation',
                      style: GoogleFonts.syne(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(q.explanation,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary,
                          height: 1.5)),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onNext,
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(isLast ? 'See Results' : 'Next Question',
                      style: GoogleFonts.syne(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ).animate().fadeIn(duration: 250.ms),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Results View ──────────────────────────────────────────────
class _ResultsView extends StatelessWidget {
  final int correct;
  final int total;
  final bool passed;
  final LevelModel? level;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const _ResultsView({
    super.key,
    required this.correct,
    required this.total,
    required this.passed,
    required this.level,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.green : AppColors.warning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Score ring
          SizedBox(
            width: 160, height: 160,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                  score: correct / total, color: color),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$correct/$total',
                        style: GoogleFonts.syne(
                            fontSize: 36, fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary)),
                    Text(passed ? 'PASSED' : 'TRY AGAIN',
                        style: GoogleFonts.syne(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: color, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 28),

          Text(passed ? '🎉 Level Complete!' : '😅 Almost There!',
              style: GoogleFonts.syne(
                  fontSize: 26, fontWeight: FontWeight.w800,
                  color: passed ? AppColors.green : AppColors.warning),
              textAlign: TextAlign.center)
              .animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),
          if (passed) ...[
            Text('+${level?.xpReward ?? 100} XP earned',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.gold,
                    fontWeight: FontWeight.w600))
                .animate()
                .moveY(begin: 20, end: 0, delay: 400.ms)
                .fadeIn(delay: 400.ms),
          ] else ...[
            Text('You need ${((total * 0.8).ceil())}/$total to pass',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],

          const SizedBox(height: 28),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(label: 'Correct', value: '$correct', color: AppColors.green),
              const SizedBox(width: 16),
              _StatChip(label: 'Wrong', value: '${total - correct}',
                  color: AppColors.error),
            ],
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 40),

          if (passed)
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
            )
          else ...[
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
              child: Text('Ask ARIA for Help',
                  style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.syne(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Score Ring Painter ────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;
  const _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;

    // Track
    canvas.drawCircle(
        c, r,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12);

    // Fill arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter o) => o.score != score;
}
