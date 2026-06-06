import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Profile Header ───────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.15),
                    AppColors.coral.withValues(alpha: 0.08),
                    AppColors.bgDark,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile',
                          style: GoogleFonts.syne(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.settings),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.settings_outlined,
                              color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.brandGradient,
                          border: Border.all(
                              color: AppColors.brand.withValues(alpha: 0.5),
                              width: 3),
                          boxShadow: [BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.3),
                              blurRadius: 20, spreadRadius: 4)],
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true)
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.syne(
                                fontSize: 40, fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bgDark, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 14),
                  Text(user?.name ?? 'Learner',
                      style: GoogleFonts.syne(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Level ${user?.level ?? 1} · DSA Learner',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _StatItem(
                            value: '${user?.xpTotal ?? 0}',
                            label: 'XP'),
                        _Divider(),
                        _StatItem(
                            value: '${user?.level ?? 1}',
                            label: 'Levels'),
                        _Divider(),
                        _StatItem(
                            value: '5',
                            label: 'Friends'),
                        _Divider(),
                        _StatItem(
                            value: '${user?.streakCount ?? 0}🔥',
                            label: 'Streak'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),

          // ── Badges ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 8,
                  AppSpacing.pagePadding, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Badges', count: '${_mockBadges.length}'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _mockBadges.length,
                    itemBuilder: (_, i) => _BadgeCell(badge: _mockBadges[i], index: i),
                  ),
                ],
              ),
            ),
          ),

          // ── Trophies ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0,
                  AppSpacing.pagePadding, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Trophies 🏆', count: '0'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
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

          // ── Activity ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0,
                  AppSpacing.pagePadding, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Activity', count: null),
                  const SizedBox(height: 12),
                  ..._mockActivity
                      .asMap()
                      .entries
                      .map((e) => _ActivityItem(item: e.value, index: e.key)),
                ],
              ),
            ),
          ),

          // Sign out
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 8,
                  AppSpacing.pagePadding, 40),
              child: OutlinedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Sign Out',
                    style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Components ────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.border);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? count;
  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.syne(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(count!,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
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
  const _BadgeData(this.emoji, this.name, this.earned, this.color);
}

final _mockBadges = const [
  _BadgeData('🔥', 'On Fire', true, Color(0xFFFF8C00)),
  _BadgeData('⚡', 'Quick Start', true, Color(0xFFFFD93D)),
  _BadgeData('🧠', 'Deep Thinker', true, Color(0xFF6C63FF)),
  _BadgeData('💪', 'Consistent', true, Color(0xFF43E97B)),
  _BadgeData('🏆', 'Champion', false, Color(0xFFFFB800)),
  _BadgeData('🎯', 'Sharpshooter', false, Color(0xFFFF6584)),
  _BadgeData('🌟', 'Star Learner', false, Color(0xFF38F9D7)),
  _BadgeData('🚀', 'Rocket', false, Color(0xFF8B5CF6)),
];

class _BadgeCell extends StatelessWidget {
  final _BadgeData badge;
  final int index;
  const _BadgeCell({required this.badge, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeSheet(context),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: badge.earned
                  ? badge.color.withValues(alpha: 0.15)
                  : AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(
                  color: badge.earned
                      ? badge.color.withValues(alpha: 0.5)
                      : AppColors.border),
            ),
            child: Center(
              child: badge.earned
                  ? Text(badge.emoji,
                      style: const TextStyle(fontSize: 24))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(badge.emoji,
                            style: TextStyle(
                                fontSize: 24,
                                color: Colors.grey.withValues(alpha: 0.3))),
                        const Icon(Icons.lock,
                            size: 16, color: AppColors.textMuted),
                      ],
                    ),
            ),
          ).animate().fadeIn(
              delay: Duration(milliseconds: index * 60),
              duration: 300.ms),
          const SizedBox(height: 4),
          Text(badge.name,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  color: badge.earned
                      ? AppColors.textSecondary
                      : AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showBadgeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(badge.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(badge.name,
                style: GoogleFonts.syne(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(badge.earned
                ? 'You\'ve earned this badge! Keep it up.'
                : 'Complete more challenges to unlock this badge.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Trophy ────────────────────────────────────────────────────
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
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(trophy.name,
              style: GoogleFonts.syne(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              maxLines: 2, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(trophy.date,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textMuted)),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${trophy.levels} levels',
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.gold)),
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
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Complete a\nroadmap to\nearn a trophy!',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Activity ──────────────────────────────────────────────────
class _ActivityData {
  final String text;
  final String time;
  final Color dotColor;
  const _ActivityData(this.text, this.time, this.dotColor);
}

final _mockActivity = const [
  _ActivityData('Started DSA Roadmap', '14 days ago', AppColors.brand),
  _ActivityData('Earned "Quick Start" badge', '12 days ago', AppColors.gold),
  _ActivityData('Completed Level 5 in DSA Roadmap', '10 days ago', AppColors.green),
  _ActivityData('Hit 7-day streak 🔥', '7 days ago', AppColors.coral),
  _ActivityData('Completed Level 8 in DSA Roadmap', '4 days ago', AppColors.green),
];

class _ActivityItem extends StatelessWidget {
  final _ActivityData item;
  final int index;
  const _ActivityItem({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Dot + line
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: item.dotColor, shape: BoxShape.circle),
                  ),
                  if (index < _mockActivity.length - 1)
                    Expanded(
                      child: Container(
                          width: 1, color: AppColors.border),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.text,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(item.time,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
        delay: Duration(milliseconds: index * 80),
        duration: 300.ms);
  }
}
