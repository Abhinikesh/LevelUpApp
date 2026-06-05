import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_input.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  late final ConfettiController _confetti;
  String? _nameErr, _emailErr, _passErr, _confirmErr;
  bool _shakeForm = false;
  double _passStrength = 0;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _passCtrl.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final p = _passCtrl.text;
    double strength = 0;
    if (p.length >= 8) strength += 0.33;
    if (p.contains(RegExp(r'[0-9]'))) strength += 0.33;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength += 0.34;
    setState(() => _passStrength = strength);
  }

  void _triggerShake() {
    setState(() => _shakeForm = true);
    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) setState(() => _shakeForm = false); });
  }

  Future<void> _register() async {
    setState(() {
      _nameErr = Validators.name(_nameCtrl.text);
      _emailErr = Validators.email(_emailCtrl.text);
      _passErr = Validators.password(_passCtrl.text);
      _confirmErr = Validators.confirmPassword(_confirmCtrl.text, _passCtrl.text);
    });
    if ([_nameErr, _emailErr, _passErr, _confirmErr].any((e) => e != null)) {
      _triggerShake();
      return;
    }
    final ok = await ref.read(authProvider.notifier).register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      _confetti.play();
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) context.go(AppRoutes.dashboard);
    } else {
      _triggerShake();
      final err = ref.read(authProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.error),
          ),
          content: Text(err, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Top illustration ────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.38,
            child: _SignupTopIllustration(),
          ),

          // ── Bottom sheet ────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.68,
              child: _buildSheet(isLoading),
            ),
          ),

          // ── Back button ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: AppSpacing.base,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 16),
              ),
            ),
          ),

          // ── Confetti ─────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [
                AppColors.brand, AppColors.coral, AppColors.green,
                AppColors.gold, AppColors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(bool isLoading) {
    Widget sheet = Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXxl + 8),
          topRight: Radius.circular(AppSpacing.radiusXxl + 8),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, AppSpacing.xl,
                AppSpacing.pagePadding, AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Your Journey',
                      style: GoogleFonts.syne(
                          fontSize: 26, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary))
                      .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppSpacing.xs),
                  Text('Create your free account',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))
                      .animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: AppSpacing.xxl),

                  StepUpInput(
                    label: 'Your Name',
                    hint: 'Ash Ketchum',
                    controller: _nameCtrl,
                    errorText: _nameErr,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline, size: AppSpacing.iconMd),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: AppSpacing.base),

                  StepUpInput(
                    label: 'Email Address',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailErr,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.mail_outline, size: AppSpacing.iconMd),
                    autofillHints: const [AutofillHints.email],
                  ).animate().fadeIn(delay: 210.ms),

                  const SizedBox(height: AppSpacing.base),

                  // Password + strength bar
                  StepUpInput(
                    label: 'Create Password',
                    hint: '8+ characters',
                    controller: _passCtrl,
                    obscureText: true,
                    errorText: _passErr,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline, size: AppSpacing.iconMd),
                    autofillHints: const [AutofillHints.newPassword],
                  ).animate().fadeIn(delay: 270.ms),

                  if (_passCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _PasswordStrengthBar(strength: _passStrength),
                  ],

                  const SizedBox(height: AppSpacing.base),

                  // Confirm password + match indicator
                  _ConfirmField(
                    confirmCtrl: _confirmCtrl,
                    passCtrl: _passCtrl,
                    errorText: _confirmErr,
                    onSubmitted: (_) => _register(),
                  ).animate().fadeIn(delay: 330.ms),

                  const SizedBox(height: AppSpacing.xl),

                  StepUpButton(
                    label: 'Create Account 🚀',
                    isLoading: isLoading,
                    onPressed: _register,
                  ).animate().fadeIn(delay: 390.ms),

                  const SizedBox(height: AppSpacing.base),

                  Row(children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('or', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ]).animate().fadeIn(delay: 440.ms),

                  const SizedBox(height: AppSpacing.base),

                  _GoogleButton().animate().fadeIn(delay: 490.ms),

                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Login',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.brand, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 540.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (_shakeForm) {
      sheet = sheet.animate().shake(duration: 500.ms, hz: 4, offset: const Offset(6, 0));
    }
    return sheet;
  }
}

// ─── Top illustration ─────────────────────────────────────────
class _SignupTopIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.3, -0.2),
          radius: 1.0,
          colors: [Color(0xFF1A1040), AppColors.bgDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60, top: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.coral.withValues(alpha: 0.1), Colors.transparent]),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Celebration nodes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CelebNode('🎯', AppColors.coral, 0),
                    const SizedBox(width: AppSpacing.xl),
                    _CelebNode('⚡', AppColors.brand, 200),
                    const SizedBox(width: AppSpacing.xl),
                    _CelebNode('🏆', AppColors.gold, 400),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                ShaderMask(
                  shaderCallback: (b) => AppColors.brandGradient
                      .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: Text('STEPUP',
                      style: GoogleFonts.syne(
                          fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebNode extends StatelessWidget {
  final String emoji;
  final Color color;
  final int delay;
  const _CelebNode(this.emoji, this.color, this.delay);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: color.withValues(alpha: 0.1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 1200.ms + Duration(milliseconds: delay), curve: Curves.easeInOut)
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .scale(begin: const Offset(0.6, 0.6), delay: Duration(milliseconds: delay), duration: 500.ms, curve: Curves.elasticOut);
  }
}

// ─── Password strength bar ───────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  const _PasswordStrengthBar({required this.strength});

  Color get _color {
    if (strength < 0.34) return AppColors.error;
    if (strength < 0.67) return AppColors.yellow;
    return AppColors.green;
  }

  String get _label {
    if (strength < 0.34) return 'Weak';
    if (strength < 0.67) return 'Fair';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              widthFactor: strength,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.5), blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(_label,
            style: GoogleFonts.inter(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Confirm field with match indicator ──────────────────────
class _ConfirmField extends StatefulWidget {
  final TextEditingController confirmCtrl;
  final TextEditingController passCtrl;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  const _ConfirmField({
    required this.confirmCtrl, required this.passCtrl,
    this.errorText, this.onSubmitted,
  });
  @override
  State<_ConfirmField> createState() => _ConfirmFieldState();
}

class _ConfirmFieldState extends State<_ConfirmField> {
  bool? _matches;

  @override
  void initState() {
    super.initState();
    widget.confirmCtrl.addListener(_check);
  }

  void _check() {
    final c = widget.confirmCtrl.text;
    if (c.isEmpty) { setState(() => _matches = null); return; }
    setState(() => _matches = c == widget.passCtrl.text);
  }

  @override
  void dispose() {
    widget.confirmCtrl.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StepUpInput(
      label: 'Confirm Password',
      hint: 'Repeat your password',
      controller: widget.confirmCtrl,
      obscureText: true,
      errorText: widget.errorText,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.lock_outline, size: AppSpacing.iconMd),
      suffixIcon: _matches == null
          ? null
          : Icon(
              _matches! ? Icons.check_circle : Icons.cancel,
              color: _matches! ? AppColors.green : AppColors.error,
              size: AppSpacing.iconLg,
            ),
      onSubmitted: widget.onSubmitted,
    );
  }
}

// ─── Google button (shared) ──────────────────────────────────
class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: const Color(0xFFDDDDDD)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('G',
              style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700,
                foreground: Paint()..shader = const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFFEA4335)],
                ).createShader(const Rect.fromLTWH(0, 0, 22, 22)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Continue with Google',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }
}
