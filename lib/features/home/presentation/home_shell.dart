import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/streak_badge.dart';
import '../../../shared/widgets/premium_animations.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    _NavItem(label: 'Home',    icon: Icons.grid_view_outlined,   activeIcon: Icons.grid_view_rounded,    path: '/home/dashboard'),
    _NavItem(label: 'Maps',    icon: Icons.explore_outlined,     activeIcon: Icons.explore_rounded,      path: '/home/map'),
    _NavItem(label: 'Create',  icon: Icons.add,                  activeIcon: Icons.add,                  path: '/home/create'),
    _NavItem(label: 'Social',  icon: Icons.people_outline,       activeIcon: Icons.people_rounded,       path: '/home/social'),
    _NavItem(label: 'Profile', icon: Icons.person_outline,       activeIcon: Icons.person_rounded,       path: '/home/profile'),
  ];

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    // Sync index from current route
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) { _selectedIndex = i; break; }
    }
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBody: true,
      // ── Custom top app bar ───────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopBar(
          xp: user?.xpTotal ?? 0,
          streak: user?.streakCount ?? 0,
          screenTitle: _tabs[_selectedIndex].label,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedIndex,
        tabs: _tabs,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Custom top bar ───────────────────────────────────────────
class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  final int xp;
  final int streak;
  final String screenTitle;
  const _TopBar({required this.xp, required this.streak, required this.screenTitle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  // Logo with custom gradient styling
                  ShaderMask(
                    shaderCallback: (b) => AppColors.brandGradient
                        .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                    child: Text(
                      'STEPUP',
                      style: GoogleFonts.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // XP Pill
                  BounceOnTap(
                    onTap: () => _showXpModal(context, xp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            AppHelpers.formatXP(xp),
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Streak Badge
                  BounceOnTap(
                    onTap: () => _showStreakModal(context, streak),
                    child: StreakBadge(streak: streak, size: StreakBadgeSize.small),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Notification bell
                  const _NotificationBell(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showXpModal(BuildContext ctx, int xp) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            top: BorderSide(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Text('⚡', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              '${AppHelpers.formatXP(xp)} XP Total',
              style: GoogleFonts.syne(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'XP measures your total progress on STEPUP. Complete roadmap milestones and AI challenges to level up!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakModal(BuildContext ctx, int streak) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            top: BorderSide(color: AppColors.coral.withValues(alpha: 0.3), width: 1.5),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const WobbleWidget(
                duration: Duration(milliseconds: 1000),
                child: Text('🔥', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$streak Day Streak!',
              style: GoogleFonts.syne(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maintain your learning momentum! Complete at least one level every day to keep the fire burning.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return BounceOnTap(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.3, duration: 800.ms),
          ),
        ],
      ),
    );
  }
}

// ─── Glassmorphic Bottom Navigation Bar ──────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final List<_NavItem> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const double barHeight = 72.0;

    return Container(
      height: barHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.65),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: tabs.asMap().entries.map((e) {
                  final i = e.key;
                  final tab = e.value;
                  final isSelected = i == selected;
                  final isCenter = i == 2;

                  if (isCenter) {
                    return _CenterFab(onTap: () => onTap(i), isSelected: isSelected);
                  }

                  return _NavTab(
                    item: tab,
                    isSelected: isSelected,
                    onTap: () => onTap(i),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;
  const _CenterFab({required this.onTap, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: BounceOnTap(
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.coral.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavTab({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: BounceOnTap(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppColors.brand : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.brand : AppColors.textMuted,
                letterSpacing: 0.2,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.path});
}
