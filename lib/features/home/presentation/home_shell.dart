import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/streak_badge.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    _NavItem(label: 'Home',    icon: Icons.grid_view_rounded,    activeIcon: Icons.grid_view_rounded,  path: '/home/dashboard'),
    _NavItem(label: 'Maps',    icon: Icons.explore_outlined,      activeIcon: Icons.explore,            path: '/home/map'),
    _NavItem(label: 'Create',  icon: Icons.add,                   activeIcon: Icons.add,                path: '/home/create'),
    _NavItem(label: 'Social',  icon: Icons.people_outline,        activeIcon: Icons.people,             path: '/home/social'),
    _NavItem(label: 'Profile', icon: Icons.person_outline,        activeIcon: Icons.person,             path: '/home/profile'),
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
        preferredSize: const Size.fromHeight(60),
        child: _TopBar(
          xp: user?.xpTotal ?? 0,
          streak: user?.streakCount ?? 0,
          screenTitle: _tabs[_selectedIndex].label,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
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
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding, vertical: AppSpacing.sm),
          child: Row(
            children: [
              // Logo
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient
                    .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                child: Text('STEPUP',
                    style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const Spacer(),
              // XP pill
              GestureDetector(
                onTap: () => _showXpModal(context, xp),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(AppHelpers.formatXP(xp),
                          style: GoogleFonts.syne(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Streak badge
              GestureDetector(
                onTap: () => _showStreakModal(context, streak),
                child: StreakBadge(streak: streak, size: StreakBadgeSize.small),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Bell
              _NotificationBell(),
            ],
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
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text('${AppHelpers.formatXP(xp)} XP Total',
                style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.gold)),
            const SizedBox(height: AppSpacing.sm),
            Text('Keep completing levels to earn more XP!',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
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
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text('$streak Day Streak!',
                style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.coral)),
            const SizedBox(height: AppSpacing.sm),
            Text('Complete a level every day to keep your streak alive!',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.textSecondary, size: 18),
          ),
          // Unread dot
          Positioned(
            right: 2, top: 2,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.coral, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.3, duration: 800.ms),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom navigation ────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final List<_NavItem> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
    );
  }
}

class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;
  const _CenterFab({required this.onTap, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.brand.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2),
                BoxShadow(color: AppColors.coral.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: -2),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppColors.brand : AppColors.textMuted,
                  size: AppSpacing.iconLg,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.brand : AppColors.textMuted,
                letterSpacing: 0.3,
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
