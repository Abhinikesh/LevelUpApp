import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _streakReminders = true;
  bool _deadlineWarnings = true;
  bool _friendActivity = false;
  bool _weeklySummary = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 16),
              ),
            ),
            title: Text('Settings',
                style: GoogleFonts.syne(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // ── Account ─────────────────────────────────
              _Section(
                title: 'Account',
                children: [
                  _TileItem(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    subtitle: user?.name ?? 'Set your name',
                    onTap: () {},
                  ),
                  _TileItem(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    onTap: () {},
                  ),
                  _TileItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    subtitle: user?.email ?? '—',
                    trailing: const SizedBox.shrink(),
                  ),
                ],
              ),

              // ── Notifications ───────────────────────────
              _Section(
                title: 'Notifications',
                children: [
                  _ToggleItem(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Streak Reminders',
                    value: _streakReminders,
                    onChanged: (v) => setState(() => _streakReminders = v),
                  ),
                  _ToggleItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Deadline Warnings',
                    value: _deadlineWarnings,
                    onChanged: (v) => setState(() => _deadlineWarnings = v),
                  ),
                  _ToggleItem(
                    icon: Icons.people_outline,
                    label: 'Friend Activity',
                    value: _friendActivity,
                    onChanged: (v) => setState(() => _friendActivity = v),
                  ),
                  _ToggleItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Weekly Summary',
                    value: _weeklySummary,
                    onChanged: (v) => setState(() => _weeklySummary = v),
                  ),
                ],
              ),

              // ── App ──────────────────────────────────────
              _Section(
                title: 'App',
                children: [
                  _TileItem(
                    icon: Icons.offline_bolt_outlined,
                    label: 'Offline Mode',
                    subtitle: 'Data syncs when online',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text('Enabled',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.green)),
                    ),
                  ),
                  _TileItem(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear Cache',
                    onTap: () => _showSnack('Cache cleared!'),
                  ),
                  _TileItem(
                    icon: Icons.download_outlined,
                    label: 'Export My Data',
                    onTap: () => _showSnack('Data export started!'),
                  ),
                ],
              ),

              // ── Subscription ─────────────────────────────
              _Section(
                title: 'Subscription',
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.12),
                          AppColors.coral.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('👑',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text('Upgrade to Pro',
                                style: GoogleFonts.syne(
                                    fontSize: 16, fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...[
                          '✓ Unlimited roadmaps',
                          '✓ AI Coach — unlimited messages',
                          '✓ Advanced analytics',
                          '✓ Priority support',
                        ].map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(f,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            )),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity, height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Upgrade Now',
                                style: GoogleFonts.syne(
                                    fontSize: 15, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),

              // ── About ────────────────────────────────────
              _Section(
                title: 'About',
                children: [
                  _TileItem(
                    icon: Icons.info_outline,
                    label: 'App Version',
                    trailing: Text('1.0.0',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textMuted)),
                  ),
                  _TileItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () {},
                  ),
                  _TileItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _TileItem(
                    icon: Icons.star_outline,
                    label: 'Rate the App',
                    onTap: () {},
                  ),
                ],
              ),

              // ── Danger Zone ───────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: _TileItem(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete Account',
                  color: AppColors.error,
                  onTap: () => _confirmDelete(context),
                ),
              ),

              const SizedBox(height: 60),
            ]),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account?',
            style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.error)),
        content: Text(
            'This action cannot be undone. All your progress and data will be permanently deleted.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.syne(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: Text('Delete',
                style: GoogleFonts.syne(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Components ────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.syne(
                  fontSize: 11, letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: children),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;

  const _TileItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: color ?? AppColors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textMuted)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.brand,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.bgDark,
          ),
        ],
      ),
    );
  }
}
