import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/social_provider.dart';
import '../../../shared/widgets/premium_animations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    final social = ref.watch(socialProvider);
    final friendsCount = social.friends.length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Premium Profile Header ───────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.18),
                    AppColors.coral.withValues(alpha: 0.05),
                    AppColors.bgDark,
                  ],
                  center: Alignment.topCenter,
                  radius: 1.2,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile',
                        style: GoogleFonts.syne(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      BounceOnTap(
                        onTap: () => context.push(AppRoutes.settings),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.settings_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Avatar with Rotating/Glowing gradient border
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow background
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.35),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: AppColors.coral.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Animated outer border
                      RotationTransition(
                        turns: const AlwaysStoppedAnimation(0.2),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                AppColors.brand,
                                AppColors.coral,
                                AppColors.teal,
                                AppColors.brand,
                              ],
                            ),
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                          .rotate(duration: 6.seconds),
                      // Inner circle avatar
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgDark,
                        ),
                        child: Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.darkGradient,
                            ),
                            child: Center(
                              child: Text(
                                (user?.name.isNotEmpty == true)
                                    ? user!.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.syne(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Camera overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: BounceOnTap(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Avatar uploads coming soon in Beta!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.bgDark, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 18),
                  Text(
                    user?.name ?? 'Learner',
                    style: GoogleFonts.syne(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Level ${user?.level ?? 1} · Explorer',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Premium Stats Grid (Cards instead of a single bar)
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: user?.xpTotal ?? 0,
                          label: 'TOTAL XP',
                          icon: Icons.star_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: user?.level ?? 1,
                          label: 'LEVEL',
                          icon: Icons.shield_rounded,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: friendsCount,
                          label: 'FRIENDS',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: user?.streakCount ?? 0,
                          label: 'STREAK',
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.coral,
                          isStreak: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Badges Grid ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 16,
                  AppSpacing.pagePadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Badges Inventory', count: '${_mockBadges.length}'),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _mockBadges.length,
                    itemBuilder: (_, i) => HoverShift(
                      child: _BadgeCell(badge: _mockBadges[i], index: i),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Trophies Showcase ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0,
                  AppSpacing.pagePadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Trophy Cabinet 🏆', count: '0'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _EmptyTrophyCard(),
                        ..._mockTrophies.map((t) => _TrophyCard(trophy: t)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Activity Timeline ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0,
                  AppSpacing.pagePadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Recent Activity', count: null),
                  const SizedBox(height: 16),
                  ..._mockActivity.asMap().entries.map((e) {
                    return SlideFadeTransition(
                      delay: Duration(milliseconds: e.key * 80),
                      child: _ActivityItem(
                        item: e.value,
                        index: e.key,
                        isLast: e.key == _mockActivity.length - 1,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Sign out button with Premium Aesthetics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 16,
                  AppSpacing.pagePadding, 48),
              child: BounceOnTap(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out Session',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card Widget ───────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isStreak;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.isStreak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isStreak
                    ? Row(
                        children: [
                          CountUpText(
                            end: value,
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const WobbleWidget(
                            duration: Duration(milliseconds: 1000),
                            child: Text('🔥', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      )
                    : CountUpText(
                        end: value,
                        style: GoogleFonts.syne(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? count;
  const _SectionTitle({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              count!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Badge Data ────────────────────────────────────────────────
class _BadgeData {
  final String emoji;
  final String name;
  final bool earned;
  final Color color;
  final String description;

  const _BadgeData(this.emoji, this.name, this.earned, this.color, this.description);
}

final _mockBadges = const [
  _BadgeData('🔥', 'On Fire', true, Color(0xFFFF8C00), 'Maintain a streak of 7 days or more.'),
  _BadgeData('⚡', 'Quick Start', true, Color(0xFFFFD93D), 'Complete your first level on the same day you sign up.'),
  _BadgeData('🧠', 'Deep Thinker', true, Color(0xFF6C63FF), 'Spend more than 1 hour learning in a single session.'),
  _BadgeData('💪', 'Consistent', true, Color(0xFF43E97B), 'Complete 5 levels within a single week.'),
  _BadgeData('🏆', 'Champion', false, Color(0xFFFFB800), 'Reach first place in the weekly leaderboard.'),
  _BadgeData('🎯', 'Sharpshooter', false, Color(0xFFFF6584), 'Complete 3 levels in a row without failing any proof checks.'),
  _BadgeData('🌟', 'Star Learner', false, Color(0xFF38F9D7), 'Earn a total of 5,000 XP across all roadmaps.'),
  _BadgeData('🚀', 'Rocket Speed', false, Color(0xFF8B5CF6), 'Complete an entire roadmap within 3 days.'),
];

class _BadgeCell extends StatelessWidget {
  final _BadgeData badge;
  final int index;
  const _BadgeCell({required this.badge, required this.index});

  @override
  Widget build(BuildContext context) {
    return BounceOnTap(
      onTap: () => _showBadgeSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: badge.earned
                  ? badge.color.withValues(alpha: 0.12)
                  : AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: badge.earned
                    ? badge.color.withValues(alpha: 0.6)
                    : AppColors.border,
                width: 1.5,
              ),
              boxShadow: badge.earned
                  ? [
                      BoxShadow(
                        color: badge.color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: badge.earned
                  ? Text(badge.emoji, style: const TextStyle(fontSize: 28))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          badge.emoji,
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.bgCardLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: badge.earned ? FontWeight.w700 : FontWeight.w500,
              color: badge.earned ? AppColors.textPrimary : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showBadgeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            top: BorderSide(color: badge.color.withValues(alpha: 0.3), width: 1.5),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: badge.earned
                    ? badge.color.withValues(alpha: 0.15)
                    : AppColors.bgDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.earned ? badge.color : AppColors.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              badge.name,
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: badge.earned
                    ? AppColors.green.withValues(alpha: 0.1)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                badge.earned ? 'UNLOCKED' : 'LOCKED',
                style: GoogleFonts.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: badge.earned ? AppColors.green : AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trophy Showcase ───────────────────────────────────────────
class _TrophyData {
  final String name;
  final String date;
  final int levels;
  const _TrophyData(this.name, this.date, this.levels);
}

final _mockTrophies = <_TrophyData>[];

class _TrophyCard extends StatelessWidget {
  final _TrophyData trophy;
  const _TrophyCard({required this.trophy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            trophy.name,
            style: GoogleFonts.syne(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            trophy.date,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrophyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing trophy shape
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Text('🏆', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 12),
          Text(
            'Cabinet Empty',
            style: GoogleFonts.syne(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete your active roadmap to claim your first trophy.',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Activity Timeline ──────────────────────────────────────────
class _ActivityData {
  final String text;
  final String time;
  final Color dotColor;
  const _ActivityData(this.text, this.time, this.dotColor);
}

final _mockActivity = const [
  _ActivityData('Started DSA Challenge Roadmap', '14 days ago', AppColors.brand),
  _ActivityData('Unlocked "Quick Start" badge', '12 days ago', AppColors.gold),
  _ActivityData('Completed Level 5: Arrays & Strings', '10 days ago', AppColors.green),
  _ActivityData('Reached 7-day learning streak 🔥', '7 days ago', AppColors.coral),
  _ActivityData('Completed Level 8: Binary Trees recursion', '4 days ago', AppColors.green),
];

class _ActivityItem extends StatelessWidget {
  final _ActivityData item;
  final int index;
  final bool isLast;

  const _ActivityItem({
    required this.item,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node (Line & Dot)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Glowing Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.bgDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: item.dotColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: item.dotColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                // Upward/Downward Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.dotColor.withValues(alpha: 0.4),
                            _mockActivity[index + 1].dotColor.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.time,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
