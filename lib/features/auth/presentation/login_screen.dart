import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/stepup_button.dart';
import '../../../shared/widgets/stepup_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _emailError = null; _passError = null; });
    final emailErr = Validators.email(_emailCtrl.text);
    final passErr = Validators.required(_passCtrl.text, 'Password');
    if (emailErr != null || passErr != null) {
      setState(() { _emailError = emailErr; _passError = passErr; });
      return;
    }
    final success = await ref.read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final error = authState.error;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 28)),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: AppSpacing.xl),
                Text('Welcome back', style: AppTextStyles.h1)
                    .animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0, delay: 150.ms),
                const SizedBox(height: AppSpacing.sm),
                Text('Sign in to continue levelling up',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary))
                    .animate().fadeIn(delay: 250.ms),

                const SizedBox(height: AppSpacing.xxl),

                if (error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.base),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(error, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                      ],
                    ),
                  ).animate().fadeIn().shake(),

                StepUpInput(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: const Icon(Icons.email_outlined, size: AppSpacing.iconMd),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: AppSpacing.base),

                StepUpInput(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  errorText: _passError,
                  autofillHints: const [AutofillHints.password],
                  prefixIcon: const Icon(Icons.lock_outline, size: AppSpacing.iconMd),
                  onSubmitted: (_) => _login(),
                ).animate().fadeIn(delay: 380.ms),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot password?',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand)),
                  ),
                ).animate().fadeIn(delay: 440.ms),

                const SizedBox(height: AppSpacing.md),

                StepUpButton(
                  label: 'Sign In',
                  isLoading: authState.isLoading,
                  onPressed: _login,
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('or', style: AppTextStyles.label),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ).animate().fadeIn(delay: 550.ms),

                const SizedBox(height: AppSpacing.xl),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.signup),
                        child: Text('Sign Up',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
