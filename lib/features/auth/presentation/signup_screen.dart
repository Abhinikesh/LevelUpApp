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
  String? _nameErr, _emailErr, _passErr, _confirmErr;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _nameErr = Validators.name(_nameCtrl.text);
      _emailErr = Validators.email(_emailCtrl.text);
      _passErr = Validators.password(_passCtrl.text);
      _confirmErr = Validators.confirmPassword(_confirmCtrl.text, _passCtrl.text);
    });
    if ([_nameErr, _emailErr, _passErr, _confirmErr].any((e) => e != null)) return;

    final success = await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (success && mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: AppTextStyles.h1)
                  .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppSpacing.sm),
              Text('Join thousands levelling up their lives',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary))
                  .animate().fadeIn(delay: 100.ms),

              const SizedBox(height: AppSpacing.xxl),

              if (authState.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.base),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Text(authState.error!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ).animate().fadeIn().shake(),

              StepUpInput(
                label: 'Full Name',
                hint: 'Your name',
                controller: _nameCtrl,
                errorText: _nameErr,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline, size: AppSpacing.iconMd),
                autofillHints: const [AutofillHints.name],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSpacing.base),

              StepUpInput(
                label: 'Email',
                hint: 'you@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailErr,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.email_outlined, size: AppSpacing.iconMd),
                autofillHints: const [AutofillHints.email],
              ).animate().fadeIn(delay: 280.ms),
              const SizedBox(height: AppSpacing.base),

              StepUpInput(
                label: 'Password',
                hint: '8+ characters',
                controller: _passCtrl,
                obscureText: true,
                errorText: _passErr,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.lock_outline, size: AppSpacing.iconMd),
                autofillHints: const [AutofillHints.newPassword],
              ).animate().fadeIn(delay: 360.ms),
              const SizedBox(height: AppSpacing.base),

              StepUpInput(
                label: 'Confirm Password',
                hint: 'Repeat password',
                controller: _confirmCtrl,
                obscureText: true,
                errorText: _confirmErr,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline, size: AppSpacing.iconMd),
                onSubmitted: (_) => _register(),
              ).animate().fadeIn(delay: 440.ms),

              const SizedBox(height: AppSpacing.xl),

              StepUpButton(
                label: 'Create Account',
                isLoading: authState.isLoading,
                onPressed: _register,
              ).animate().fadeIn(delay: 520.ms),

              const SizedBox(height: AppSpacing.xl),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Sign In',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.brand, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
