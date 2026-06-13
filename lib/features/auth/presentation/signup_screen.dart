import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_input.dart';
import '../../../shared/widgets/premium_animations.dart';

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

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account != null) {
        final email = account.email;
        final name = account.displayName ?? _nameFromEmail(email);
        const password = 'GoogleSignInPasswordSecret123!';
        
        final ok = await ref.read(authProvider.notifier).login(email, password);
        if (!ok && mounted) {
          final regOk = await ref.read(authProvider.notifier).register(
            name: name,
            email: email,
            password: password,
          );
          if (regOk && mounted) {
            context.go(AppRoutes.dashboard);
          } else if (mounted) {
            final err = ref.read(authProvider).error;
            _showErrorSnack(err ?? 'Google Sign-In registration failed.');
          }
        } else if (mounted) {
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      debugPrint('Google Sign-in failed: $e');
      if (mounted) {
        _showGoogleConfigModal();
      }
    }
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    return local[0].toUpperCase() + local.substring(1);
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.error),
        ),
        content: Text(msg, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
      ),
    );
  }

  void _showGoogleConfigModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_outlined, color: AppColors.coral, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Google Web OAuth Setup',
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'To enable Google authentication on Web, configure your Google Cloud Console Client ID:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepRow('1', 'Navigate to your Google Cloud Console.'),
                _buildStepRow('2', 'Go to APIs & Services > Credentials.'),
                _buildStepRow('3', 'Create an OAuth client ID for Web Application.'),
                _buildStepRow('4', 'Add your active web origin (e.g. http://localhost) to Authorized JavaScript Origins.'),
                _buildStepRow('5', 'Add the Client ID inside google_sign_in initializer or web/index.html meta tag.'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    BounceOnTap(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Continue with Email',
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.bgCardLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top buttons bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
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
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Top illustration area (fixed height)
                        SizedBox(
                          height: 180,
                          child: _SignupTopIllustration(),
                        ),
                        const SizedBox(height: 16),
                        // Form
                        _buildSheet(isLoading),
                      ],
                    ),
                  ),
                  // Confetti overlay on top
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(bool isLoading) {
    Widget sheet = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding, 0,
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

          _GoogleButton(onPressed: _handleGoogleSignIn).animate().fadeIn(delay: 490.ms),

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
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BounceOnTap(
      onTap: onPressed,
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
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }
}
