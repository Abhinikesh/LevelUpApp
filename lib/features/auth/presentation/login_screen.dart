import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_input.dart';
import '../../../shared/widgets/premium_animations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _emailErr, _passErr;
  bool _shakeForm = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _emailErr = Validators.email(_emailCtrl.text);
      _passErr = Validators.required(_passCtrl.text, 'Password');
    });
    if (_emailErr != null || _passErr != null) {
      _triggerShake();
      return;
    }
    final ok = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.dashboard);
    } else {
      _triggerShake();
      final err = ref.read(authProvider).error;
      if (err != null) _showErrorSnack(err);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final idToken = auth.idToken;

        // If in Demo Mode and idToken is null, use a mock token to log in instantly.
        // Otherwise, require the real idToken to authenticate against the backend.
        final isDemo = ApiConstants.baseUrl.isEmpty;
        final finalToken = idToken ?? (isDemo ? 'mock-google-id-token' : null);

        if (finalToken != null) {
          final ok = await ref.read(authProvider.notifier).loginWithGoogle(finalToken);
          if (ok && mounted) {
            context.go(AppRoutes.dashboard);
          } else if (mounted) {
            final err = ref.read(authProvider).error;
            _showErrorSnack(err ?? 'Google Sign-In failed.');
          }
        } else {
          if (mounted) {
            _showGoogleConfigModal();
          }
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

  void _showServerSettingsModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ServerSettingsDialog(),
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

  void _triggerShake() {
    setState(() => _shakeForm = true);
    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) setState(() => _shakeForm = false); });
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
        content: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Top illustration area ─────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: _TopIllustration(),
          ),

          // ── Bottom sheet ──────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.64,
              child: _FormSheet(
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                emailErr: _emailErr,
                passErr: _passErr,
                isLoading: isLoading,
                shakeForm: _shakeForm,
                onLogin: _login,
                onGoogleSignIn: _handleGoogleSignIn,
                onForgot: () {},
                onSignUp: () => context.push(AppRoutes.signup),
              ),
            ),
          ),

          // ── Back button ───────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: AppSpacing.base,
            child: IconButton(
              onPressed: () => context.canPop() ? context.pop() : null,
              icon: Container(
                width: 36,
                height: 36,
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

          // ── Server Settings Button ─────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: AppSpacing.base,
            child: IconButton(
              onPressed: _showServerSettingsModal,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.dns_outlined,
                    color: AppColors.textPrimary, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top illustration ─────────────────────────────────────────
class _TopIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.0,
          colors: [Color(0xFF1A1040), AppColors.bgDark],
        ),
      ),
      child: Stack(
        children: [
          // Glow
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.brand.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Logo + mini map
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.brandGradient
                      .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: Text(
                    'STEPUP',
                    style: GoogleFonts.syne(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ).fadeIn(duration: 400.ms),
                const SizedBox(height: AppSpacing.xl),
                _MiniMap(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MiniNode(color: AppColors.green, icon: Icons.check_rounded, delay: 0),
        _MiniConnector(),
        _MiniNode(color: AppColors.brand, label: '2', pulse: true, delay: 150),
        _MiniConnector(dashed: true),
        _MiniNode(color: AppColors.borderLight, icon: Icons.lock_outline, delay: 300),
      ],
    );
  }
}

class _MiniNode extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String? label;
  final bool pulse;
  final int delay;
  const _MiniNode({required this.color, this.icon, this.label, this.pulse = false, required this.delay});

  @override
  Widget build(BuildContext context) {
    Widget node = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color == AppColors.borderLight ? AppColors.bgCardLight : null,
        gradient: color == AppColors.green
            ? AppColors.greenGradient
            : color == AppColors.brand
                ? AppColors.brandGradient
                : null,
        border: Border.all(color: color, width: 1.5),
        boxShadow: pulse ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)] : null,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 16)
            : Text(label ?? '', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
    if (pulse) {
      node = node.animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.12, duration: 900.ms, curve: Curves.easeInOut);
    }
    return node.animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .scale(begin: const Offset(0.6, 0.6), delay: Duration(milliseconds: delay), duration: 400.ms, curve: Curves.elasticOut);
  }
}

class _MiniConnector extends StatelessWidget {
  final bool dashed;
  const _MiniConnector({this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: dashed
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (_) => Container(
                width: 4, height: 2,
                color: AppColors.borderLight,
              )),
            )
          : Container(height: 2, color: AppColors.green.withValues(alpha: 0.6)),
    );
  }
}

// ─── Form sheet ───────────────────────────────────────────────
class _FormSheet extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final String? emailErr, passErr;
  final bool isLoading, shakeForm;
  final VoidCallback onLogin, onGoogleSignIn, onForgot, onSignUp;

  const _FormSheet({
    required this.emailCtrl, required this.passCtrl,
    required this.emailErr, required this.passErr,
    required this.isLoading, required this.shakeForm,
    required this.onLogin, required this.onGoogleSignIn, required this.onForgot, required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    Widget form = Container(
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
          // Drag handle
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, AppSpacing.xl,
                AppSpacing.pagePadding, AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Back',
                      style: GoogleFonts.syne(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ))
                      .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppSpacing.xs),
                  Text('Continue your journey',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))
                      .animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: AppSpacing.xxl),

                  StepUpInput(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: emailErr,
                    prefixIcon: const Icon(Icons.mail_outline, size: AppSpacing.iconMd),
                    autofillHints: const [AutofillHints.email],
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: AppSpacing.base),

                  StepUpInput(
                    label: 'Password',
                    hint: '••••••••',
                    controller: passCtrl,
                    obscureText: true,
                    errorText: passErr,
                    prefixIcon: const Icon(Icons.lock_outline, size: AppSpacing.iconMd),
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => onLogin(),
                  ).animate().fadeIn(delay: 220.ms),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgot,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text('Forgot Password?',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w500)),
                    ),
                  ).animate().fadeIn(delay: 290.ms),

                  const SizedBox(height: AppSpacing.sm),

                  StepUpButton(label: 'Login', isLoading: isLoading, onPressed: onLogin)
                      .animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: AppSpacing.base),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('or', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ]).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: AppSpacing.base),

                  // Google button
                  _GoogleButton(onPressed: onGoogleSignIn).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: GestureDetector(
                      onTap: onSignUp,
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Sign Up',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.brand,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (shakeForm) {
      form = form.animate().shake(duration: 500.ms, hz: 4, offset: const Offset(6, 0));
    }

    return form;
  }
}

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
            // Google G
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Stack(children: [
                Center(child: Text('G',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
                    foreground: Paint()..shader = const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFFEA4335)],
                    ).createShader(const Rect.fromLTWH(0, 0, 22, 22)),
                  ),
                )),
              ]),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Continue with Google',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }
}

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  final _urlCtrl = TextEditingController();
  bool _isDemoMode = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDemoMode = prefs.getBool('is_demo_mode') ?? true;
      _urlCtrl.text = prefs.getString('custom_api_base_url') ?? "http://10.66.71.97:8000/api";
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_demo_mode', _isDemoMode);
      
      String finalUrl = _urlCtrl.text.trim();
      if (finalUrl.isNotEmpty) {
        await prefs.setString('custom_api_base_url', finalUrl);
      }
      
      // Update constants at runtime
      if (_isDemoMode) {
        ApiConstants.baseUrl = "";
      } else {
        ApiConstants.baseUrl = finalUrl;
      }
      
      // Update WS Url
      if (ApiConstants.baseUrl.isNotEmpty) {
        final uri = Uri.tryParse(ApiConstants.baseUrl);
        if (uri != null) {
          final host = uri.host;
          final port = uri.port;
          ApiConstants.wsUrl = "ws://$host:$port";
        }
      } else {
        ApiConstants.wsUrl = "ws://localhost:8000";
      }

      // Reset Dio Client to pick up the new base URL
      DioClient.reset();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bgCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: const BorderSide(color: AppColors.green),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isDemoMode 
                        ? 'Switched to Demo Mode (Mock Data)' 
                        : 'Server API URL updated successfully!',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bgCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: const BorderSide(color: AppColors.error),
            ),
            content: Text('Failed to save server settings', style: GoogleFonts.inter(color: AppColors.textPrimary)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.dns_outlined, color: AppColors.brand, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Server Connection',
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
              'Select whether to use local simulated demo data (Mock Mode) or connect to a running backend server.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            
            // Switch for Demo Mode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_queue, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demo Mode (Mock Data)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Run without internet/backend',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isDemoMode,
                    activeThumbColor: AppColors.brand,
                    activeTrackColor: AppColors.brand.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() {
                        _isDemoMode = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            if (!_isDemoMode) ...[
              const SizedBox(height: 18),
              Text(
                'API Base URL',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlCtrl,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'http://localhost:8000/api',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgDark.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.brand),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Ensure your local backend is running and CORS is enabled to allow Chrome connections.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.coral,
                  height: 1.3,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                BounceOnTap(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Save & Connect',
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
  }
}
