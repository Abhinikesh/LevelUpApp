import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/app_color_scheme.dart';

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

  // Theme configuration
  int _currentThemeIndex = 0;

  // AI Configuration
  final _openAiKeyCtrl = TextEditingController();
  bool _showApiKey = false;
  bool _keySaved = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadThemePref();
  }

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentThemeIndex = prefs.getInt('map_bg_theme') ?? 0;
      });
    }
  }

  Future<void> _saveThemePref(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('map_bg_theme', index);
    if (mounted) {
      setState(() => _currentThemeIndex = index);
    }
  }

  String _themeName(int index) {
    switch (index) {
      case 0:
        return 'Dark Purple';
      case 1:
        return 'Deep Ocean';
      case 2:
        return 'Dark Forest';
      case 3:
        return 'Midnight';
      default:
        return 'Dark Purple';
    }
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Map Background Theme',
                style: GoogleFonts.spaceMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a theme for your level map',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  (0, 'Dark Purple', const Color(0xFF1A0A3E)),
                  (1, 'Deep Ocean', const Color(0xFF071A2E)),
                  (2, 'Dark Forest', const Color(0xFF071A0E)),
                  (3, 'Midnight', const Color(0xFF000000)),
                ].map((item) {
                  final idx = item.$1;
                  final name = item.$2;
                  final swatchColor = item.$3;
                  final isSelected = _currentThemeIndex == idx;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {});
                      _saveThemePref(idx);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: swatchColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brand
                                  : AppColors.border,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.brand.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isSelected
                                ? AppColors.brand
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('openai_api_key') ?? '';
    if (mounted) {
      _openAiKeyCtrl.text = stored;
      setState(() => _keySaved = stored.isNotEmpty);
    }
  }

  Future<void> _saveApiKey() async {
    final key = _openAiKeyCtrl.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', key);
    setState(() => _keySaved = key.isNotEmpty);
    if (mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Text('✅  ', style: TextStyle(fontSize: 16)),
            Text(
              key.isEmpty ? 'API key cleared' : 'API key saved securely',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: key.isEmpty
            ? AppColors.bgCard
            : const Color(0xFF0D2B1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showAppThemeSheet(BuildContext context, WidgetRef ref, AppTheme activeTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final currentTheme = ref.watch(themeProvider);
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose App Theme',
                  style: GoogleFonts.spaceMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an accent theme for your application',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: appThemes.map((theme) {
                    final isSelected = currentTheme.id == theme.id;
                    return GestureDetector(
                      onTap: () {
                        ref.read(themeProvider.notifier).setTheme(theme.id);
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${theme.name} theme applied!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.border,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: theme.primary.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            theme.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isSelected
                                  ? AppColors.brand
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisplayModeSelector(BuildContext context, WidgetRef ref, String activeMode) {
    final modes = [
      ('light', 'Light', Icons.wb_sunny_outlined),
      ('dark', 'Dark', Icons.nightlight_round_outlined),
      ('system', 'System', Icons.settings_brightness_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.display_settings_outlined, size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                'Display Mode',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: modes.map((m) {
                final modeId = m.$1;
                final modeName = m.$2;
                final modeIcon = m.$3;
                final isSelected = activeMode == modeId;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(appModeProvider.notifier).setMode(modeId);
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            modeIcon,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            modeName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _openAiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final activeTheme = ref.watch(themeProvider);
    final activeMode = ref.watch(appModeProvider);

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

              // ── Appearance ──────────────────────────────
              _Section(
                title: 'Appearance',
                children: [
                  _TileItem(
                    icon: Icons.map_outlined,
                    label: 'Map Theme',
                    subtitle: _themeName(_currentThemeIndex),
                    onTap: _showThemeSheet,
                  ),
                  _TileItem(
                    icon: Icons.palette_outlined,
                    label: 'App Accent Theme',
                    subtitle: activeTheme.name,
                    onTap: () => _showAppThemeSheet(context, ref, activeTheme),
                  ),
                  _buildDisplayModeSelector(context, ref, activeMode),
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

              // ── AI Configuration ─────────────────────────────────
              _Section(
                title: 'AI Configuration',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _keySaved
                                ? AppColors.green.withValues(alpha: 0.08)
                                : AppColors.brand.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _keySaved
                                  ? AppColors.green.withValues(alpha: 0.3)
                                  : AppColors.brand.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _keySaved ? '✅' : '✨',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _keySaved
                                      ? 'OpenAI API key configured — AI generation active'
                                      : 'Add your OpenAI key to enable real AI generation',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: _keySaved
                                        ? AppColors.green
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Key input
                        Text(
                          'OpenAI API Key',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: TextField(
                            controller: _openAiKeyCtrl,
                            obscureText: !_showApiKey,
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'sk-...',
                              hintStyle: GoogleFonts.spaceMono(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showApiKey
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () =>
                                    setState(() => _showApiKey = !_showApiKey),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextButton(
                              onPressed: _saveApiKey,
                              child: Text(
                                'Save API Key',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🔒  Stored locally only. Never sent to our servers.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),

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
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.brand,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.bgDark,
          ),
        ],
      ),
    );
  }
}
