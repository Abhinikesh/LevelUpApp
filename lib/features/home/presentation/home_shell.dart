import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/notifications_provider.dart';
import '../../../core/network/sync_manager.dart';
import '../../../shared/widgets/premium_animations.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;
  late SyncManager _syncManager;

  @override
  void initState() {
    super.initState();
    _syncManager = SyncManager(ref);
    _syncManager.start();
  }

  @override
  void dispose() {
    _syncManager.stop();
    super.dispose();
  }

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
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) { _selectedIndex = i; break; }
    }
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBody: true,
      body: Column(
        children: [
          _TopBar(
            xp: user?.xpTotal ?? 0,
            streak: user?.streakCount ?? 0,
            screenTitle: _tabs[_selectedIndex].label,
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
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
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomNav(
                    selected: _selectedIndex,
                    tabs: _tabs,
                    onTap: _onTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom top bar ───────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final int xp;
  final int streak;
  final String screenTitle;
  const _TopBar({required this.xp, required this.streak, required this.screenTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).unreadCount;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding, vertical: 8.0),
          child: Row(
            children: [
              // Logo: SpaceMono, 20px, brand purple, tracked (letterSpacing)
              Text(
                'STEPUP',
                style: GoogleFonts.spaceMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // XP Pill: gold background, lightning icon, XP number (SpaceGrotesk)
              BounceOnTap(
                onTap: () => _showXpModal(context, xp),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        AppHelpers.formatXP(xp),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.bgDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Streak Pill: dark orange background, fire emoji, streak number (SpaceGrotesk)
              BounceOnTap(
                onTap: () => _showStreakModal(context, streak),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD84315), // Dark orange
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Bell with live unread badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                    onPressed: () async {
                      await context.push(AppRoutes.notifications);
                      // Refresh unread count after returning from notifications
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: const Border(
            top: BorderSide(color: AppColors.gold, width: 1.5),
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
              style: GoogleFonts.spaceMono(
                fontSize: 26,
                fontWeight: FontWeight.bold,
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
          border: const Border(
            top: BorderSide(color: AppColors.coral, width: 1.5),
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
              style: GoogleFonts.spaceMono(
                fontSize: 26,
                fontWeight: FontWeight.bold,
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

// ─── Bottom Navigation Bar with Stack ────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final List<_NavItem> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const double barHeight = 72.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: barHeight + bottomPadding + 36, // Allow height for the lifted FAB
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. The actual bottom nav bar (72px, dark background)
          Container(
            height: barHeight + bottomPadding,
            decoration: const BoxDecoration(
              color: AppColors.bgCard, // Color(0xFF0F0F1A)
              border: Border(
                top: BorderSide(
                  color: AppColors.border, // Color(0xFF1C1C2E)
                  width: 1.0,
                ),
              ),
            ),
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
                      // Placeholder for the center FAB so it spaces properly
                      return const SizedBox(width: 60);
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
          // 2. Positioned FAB centered, bottom: 16px above bar (which is bottom: 36px total)
          Positioned(
            left: 0,
            right: 0,
            bottom: 36 + bottomPadding,
            child: Center(
              child: _CenterFab(
                onTap: () => onTap(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BounceOnTap(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.brand, AppColors.coral], // brand purple to coral
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
      width: 60,
      height: 60, // 60px touch target
      child: BounceOnTap(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.brand : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.brand : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            // small dot indicator below
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.brand : Colors.transparent,
              ),
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
