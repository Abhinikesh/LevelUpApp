import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/roadmap_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/providers/social_provider.dart';
import '../../../shared/widgets/premium_animations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    Future.microtask(() {
      ref.read(profileHistoryProvider.notifier).fetchHistory();
      ref.read(roadmapProvider.notifier).fetchRoadmaps();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _userTitle(int level) {
    if (level <= 5) return 'Explorer';
    if (level <= 15) return 'Warrior';
    return 'Legend';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    final social = ref.watch(socialProvider);
    final friendsCount = social.friends.length;
    final completedRoadmaps = ref.watch(completedRoadmapsProvider);

    // Dynamic tagline title
    final title = _userTitle(user?.level ?? 1);

    // Fetch and combine history logs
    final historyState = ref.watch(profileHistoryProvider);
    final historyList = historyState.history;
    final userBadges = user?.badges ?? [];
    final roadmaps = ref.watch(roadmapProvider).roadmaps;

    final List<_TimelineActivity> activities = [];

    for (final c in historyList) {
      activities.add(_TimelineActivity(
        text: 'Completed Level ${c.levelNumber}: ${c.levelTitle}',
        time: c.createdAt,
        dotColor: AppColors.green,
      ));
    }

    for (final b in userBadges) {
      activities.add(_TimelineActivity(
        text: 'Unlocked "${b.badgeName}" badge',
        time: b.earnedAt,
        dotColor: AppColors.gold,
      ));
    }

    for (final r in roadmaps) {
      activities.add(_TimelineActivity(
        text: 'Started ${r.title} Roadmap',
        time: r.createdAt,
        dotColor: AppColors.brand,
      ));
    }

    // Sort by time descending
    activities.sort((a, b) => b.time.compareTo(a.time));
    final recentActivities = activities.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Profile Header ───────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                color: AppColors.bgDark,
              ),
              child: Stack(
                children: [
                  // 1. RadialGradient background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.2,
                          colors: [
                            Color(0xFF2D1B69),
                            Color(0xFF080810),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 2. Subtle noise texture overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: Image.network(
                        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=300&auto=format&fit=crop',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Header contents
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Center Profile title & settings
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              context.canPop()
                                  ? GestureDetector(
                                      onTap: () => context.pop(),
                                      child: const Icon(Icons.arrow_back_ios_new,
                                          color: Colors.white, size: 20),
                                    )
                                  : const SizedBox(width: 24),
                              Text(
                                'Profile',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.settings),
                                child: const Icon(Icons.settings_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Avatar (centered, 96px)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _rotationController,
                              builder: (_, __) => CustomPaint(
                                size: const Size(96, 96),
                                painter: _AvatarRingPainter(
                                    angle: _rotationController.value *
                                        2 *
                                        math.pi),
                              ),
                            ),
                            Container(
                              width: 86,
                              height: 86,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.bgDark,
                              ),
                              child: Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.darkGradient,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (user?.name.isNotEmpty == true)
                                          ? user!.name[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Edit button bottom right
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: BounceOnTap(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Avatar uploads coming soon in Beta!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C2E),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.bgDark, width: 2),
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
                        ).animate().scale(
                            duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          user?.name ?? 'Learner',
                          style: GoogleFonts.spaceMono(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tagline
                        Text(
                          'Level ${user?.level ?? 1} • $title',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats row ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding, vertical: 16),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        value: user?.xpTotal ?? 0,
                        label: 'TOTAL XP',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: _StatItem(
                        value: user?.level ?? 1,
                        label: 'LEVEL',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: _StatItem(
                        value: friendsCount,
                        label: 'FRIENDS',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: _StatItem(
                        value: user?.streakCount ?? 0,
                        label: 'STREAK',
                        isStreak: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Badges Inventory Section ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 8, AppSpacing.pagePadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Text(
                        'Badges',
                        style: GoogleFonts.spaceMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${userBadges.length}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Wrap-based Badges Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final spacing = (width - (80 * 4)) / 3.0;
                      return Wrap(
                        spacing: spacing.clamp(4.0, 24.0),
                        runSpacing: 16,
                        children: _allBadges.map((badge) {
                          final earned = userBadges
                              .any((b) => b.badgeType == badge.slug);
                          return SizedBox(
                            width: 80,
                            height: 100,
                            child: _BadgeCell(badge: badge, earned: earned),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Trophy Cabinet ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Trophy Cabinet 🏆',
                        style: GoogleFonts.spaceMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${completedRoadmaps.length}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (completedRoadmaps.isEmpty)
                          _EmptyTrophyCard()
                        else
                          ...completedRoadmaps.map((r) => _TrophyCard(roadmap: r)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Recent Activity ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (recentActivities.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'No activity yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(recentActivities.length, (i) {
                      return _ActivityItem(
                        item: recentActivities[i],
                        isLast: i == recentActivities.length - 1,
                      );
                    }),
                ],
              ),
            ),
          ),

          // Sign out session
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 64),
              child: BounceOnTap(
                onTap: () => ref.read(authProvider.notifier).logout(),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out Session',
                          style: GoogleFonts.spaceMono(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

// ─── Stat Item Widget ──────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  final bool isStreak;

  const _StatItem({
    required this.value,
    required this.label,
    this.isStreak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CountUpText(
              end: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (isStreak) ...[
              const SizedBox(width: 2),
              const WobbleWidget(
                child: Text('🔥', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─── Predefined Badge structure ───────────────────────────────
class _PredefinedBadge {
  final String slug;
  final String name;
  final String emoji;
  final Color color;
  final String description;

  const _PredefinedBadge({
    required this.slug,
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
  });
}

const _allBadges = [
  _PredefinedBadge(
    slug: 'first_level',
    name: 'First Step',
    emoji: '👟',
    color: Color(0xFF00E5A0),
    description: 'Complete your first level milestone.',
  ),
  _PredefinedBadge(
    slug: 'level_5',
    name: 'On a Roll',
    emoji: '🎯',
    color: Color(0xFF7B6EF6),
    description: 'Complete 5 levels on your journey.',
  ),
  _PredefinedBadge(
    slug: 'level_10',
    name: 'Dedicated',
    emoji: '💪',
    color: Color(0xFFFF5E7D),
    description: 'Complete 10 levels on your journey.',
  ),
  _PredefinedBadge(
    slug: 'level_25',
    name: 'Champion',
    emoji: '🏆',
    color: Color(0xFFFFB300),
    description: 'Complete 25 levels on your journey.',
  ),
  _PredefinedBadge(
    slug: 'streak_3',
    name: 'Consistent',
    emoji: '🔥',
    color: Color(0xFFFF5E7D),
    description: 'Reach a 3-day active streak.',
  ),
  _PredefinedBadge(
    slug: 'streak_7',
    name: 'Week Warrior',
    emoji: '⚡',
    color: Color(0xFF7B6EF6),
    description: 'Reach a 7-day active streak.',
  ),
  _PredefinedBadge(
    slug: 'streak_30',
    name: 'Iron Will',
    emoji: '🦾',
    color: Color(0xFFFFB300),
    description: 'Reach a 30-day active streak.',
  ),
  _PredefinedBadge(
    slug: 'xp_500',
    name: 'XP Earner',
    emoji: '⭐',
    color: Color(0xFF00E5A0),
    description: 'Earn a total of 500 XP.',
  ),
  _PredefinedBadge(
    slug: 'xp_2000',
    name: 'XP Hunter',
    emoji: '🌟',
    color: Color(0xFF7B6EF6),
    description: 'Earn a total of 2,000 XP.',
  ),
  _PredefinedBadge(
    slug: 'xp_5000',
    name: 'XP Legend',
    emoji: '💎',
    color: Color(0xFFFFB300),
    description: 'Earn a total of 5,000 XP.',
  ),
  _PredefinedBadge(
    slug: 'roadmap_done',
    name: 'Completionist',
    emoji: '🎓',
    color: Color(0xFF00E5A0),
    description: 'Complete an entire roadmap challenge.',
  ),
  _PredefinedBadge(
    slug: 'code_ninja',
    name: 'Code Ninja',
    emoji: '🥷',
    color: Color(0xFF7B6EF6),
    description: 'Complete a coding verification level.',
  ),
];

// ─── Badge Cell Widget ─────────────────────────────────────────
class _BadgeCell extends StatelessWidget {
  final _PredefinedBadge badge;
  final bool earned;

  const _BadgeCell({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    Widget circle = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: earned ? badge.color.withValues(alpha: 0.12) : AppColors.bgCard,
        shape: BoxShape.circle,
        border: Border.all(
          color: earned ? badge.color.withValues(alpha: 0.6) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          badge.emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );

    if (!earned) {
      circle = Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: Opacity(
              opacity: 0.3,
              child: circle,
            ),
          ),
          Positioned(
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.bgCardLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      );
    }

    return HoverShift(
      child: BounceOnTap(
        onTap: () => _showBadgeSheet(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circle,
            const SizedBox(height: 6),
            Text(
              badge.name,
              style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: earned ? FontWeight.bold : FontWeight.normal,
                color: earned ? AppColors.textPrimary : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
            top: BorderSide(
              color: badge.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
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
                color: earned
                    ? badge.color.withValues(alpha: 0.15)
                    : AppColors.bgDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: earned ? badge.color : AppColors.border,
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
              style: GoogleFonts.spaceMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
                color: earned
                    ? AppColors.green.withValues(alpha: 0.1)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                earned ? 'UNLOCKED' : 'LOCKED',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: earned ? AppColors.green : AppColors.textMuted,
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

// ─── Empty Trophy Cabinet Widget ───────────────────────────────
class _EmptyTrophyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Text('🏆', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 8),
          Text(
            'Cabinet Empty',
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Complete your active roadmap to claim your first trophy.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Trophy Card Widget ─────────────────────────────────────────
class _TrophyCard extends StatelessWidget {
  final RoadmapModel roadmap;
  const _TrophyCard({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            roadmap.title,
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppHelpers.timeAgo(roadmap.updatedAt ?? roadmap.createdAt),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Activity Item ────────────────────────────────────
class _TimelineActivity {
  final String text;
  final DateTime time;
  final Color dotColor;

  _TimelineActivity({
    required this.text,
    required this.time,
    required this.dotColor,
  });
}

class _ActivityItem extends StatelessWidget {
  final _TimelineActivity item;
  final bool isLast;

  const _ActivityItem({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: item.dotColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppHelpers.timeAgo(item.time),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

// ─── Custom Painter for Rotating Avatar Gradient Ring ──────────
class _AvatarRingPainter extends CustomPainter {
  final double angle;

  const _AvatarRingPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF7B6EF6),
          Color(0xFFFF5E7D),
          Color(0xFF00E5A0),
          Color(0xFF7B6EF6),
        ],
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawCircle(Offset(size.width / 2, size.height / 2),
        size.width / 2 - 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
