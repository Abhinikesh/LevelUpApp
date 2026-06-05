import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: AppTextStyles.h3),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _SectionTitle('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionTitle('Preferences'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.brand,
            ),
          ),
          _SettingsTile(
            icon: Icons.vibration_outlined,
            label: 'Haptic Feedback',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionTitle('Data'),
          _SettingsTile(
            icon: Icons.cloud_sync_outlined,
            label: 'Sync Now',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            label: 'Clear Cache',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionTitle('About'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'App Version',
            trailing: Text('1.0.0', style: AppTextStyles.bodySmall),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xl),

          // Danger zone
          _SettingsTile(
            icon: Icons.logout,
            label: 'Sign Out',
            labelColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  title: Text('Sign Out?', style: AppTextStyles.h3),
                  content: Text(
                    'You will need to sign in again.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Sign Out',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              }
            },
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            label: 'Delete Account',
            labelColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title.toUpperCase(),
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted,
              letterSpacing: 1.2)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? labelColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.md),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: iconColor ?? AppColors.textSecondary,
                size: AppSpacing.iconLg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: labelColor ?? AppColors.textPrimary)),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.arrow_forward_ios,
                        color: AppColors.textMuted, size: 14)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
