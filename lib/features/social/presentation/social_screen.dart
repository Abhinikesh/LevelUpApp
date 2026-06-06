import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/social_provider.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});
  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    ref.read(socialProvider.notifier).init();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Custom tab bar
            _SocialTabBar(ctrl: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _FriendsTab(),
                  _LeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Bar ────────────────────────────────────────────────────
class _SocialTabBar extends StatelessWidget {
  final TabController ctrl;
  const _SocialTabBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      child: TabBar(
        controller: ctrl,
        labelColor: AppColors.brand,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.syne(
            fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.syne(fontSize: 14),
        indicatorColor: AppColors.brand,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        tabs: const [Tab(text: 'Friends'), Tab(text: 'Leaderboard')],
      ),
    );
  }
}

// ─── Friends Tab ───────────────────────────────────────────────
class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialProvider);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Search friends by name...',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pending requests
            if (social.pendingRequests.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Friend Requests',
                              style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${social.pendingRequests.length}',
                              style: GoogleFonts.syne(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...social.pendingRequests
                          .map((f) => _RequestCard(friend: f))
                          .toList(),
                    ],
                  ),
                ),
              ),

            // Friends list header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('${social.friends.length} Friends',
                    style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ),
            ),

            // Friends list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _FriendCard(
                  friend: social.friends[i],
                  index: i,
                ),
                childCount: social.friends.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // Add Friend FAB
        Positioned(
          bottom: 24,
          right: 20,
          child: GestureDetector(
            onTap: () => _showAddFriendSheet(context),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.5),
                    blurRadius: 20, spreadRadius: 2)],
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 24),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        ),
      ],
    );
  }

  void _showAddFriendSheet(BuildContext context) {
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
            Text('Add Friend',
                style: GoogleFonts.syne(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              height: 52,
              decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter email to invite...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Text('Send Invite',
                    style: GoogleFonts.syne(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final MockFriend friend;
  const _RequestCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Avatar(name: friend.name, color: friend.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name,
                    style: GoogleFonts.syne(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text('Wants to connect',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.greenGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Accept',
                  style: GoogleFonts.syne(
                      fontSize: 12, color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('Decline',
                  style: GoogleFonts.syne(
                      fontSize: 12, color: AppColors.textMuted,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final MockFriend friend;
  final int index;
  const _FriendCard({required this.friend, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Avatar(name: friend.name, color: friend.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name,
                    style: GoogleFonts.syne(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(friend.status,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text('${friend.streak} day streak',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${friend.progress}%',
                  style: GoogleFonts.syne(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.brand)),
              if (friend.ahead != 0)
                Text(
                  friend.ahead > 0
                      ? '${friend.ahead} ahead'
                      : '${-friend.ahead} behind',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: friend.ahead > 0
                          ? AppColors.green
                          : AppColors.coral),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(
        delay: Duration(milliseconds: index * 70),
        duration: 300.ms);
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.syne(
              fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }
}

// ─── Leaderboard Tab ───────────────────────────────────────────
class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialProvider);
    final leaders = social.leaderboard;

    return CustomScrollView(
      slivers: [
        // Podium
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: _Podium(leaders: leaders.take(3).toList()),
          ),
        ),

        // Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Rankings',
                style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ),
        ),

        // Rank list (4+)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final rank = i + 4;
              final entry = leaders.length > i + 3 ? leaders[i + 3] : null;
              if (entry == null) return null;
              final isMe = entry.isCurrentUser;
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.brand.withValues(alpha: 0.08)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMe ? AppColors.brand.withValues(alpha: 0.4) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('#$rank',
                          style: GoogleFonts.syne(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppColors.textMuted)),
                    ),
                    _Avatar(name: entry.name, color: entry.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(entry.name,
                                  style: GoogleFonts.syne(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('YOU',
                                      style: GoogleFonts.syne(
                                          fontSize: 9, color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                          Text('${entry.xp} XP',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: (leaders.length - 3).clamp(0, leaders.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> leaders;
  const _Podium({required this.leaders});

  @override
  Widget build(BuildContext context) {
    if (leaders.length < 3) return const SizedBox.shrink();
    final first = leaders[0];
    final second = leaders[1];
    final third = leaders[2];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd
        Expanded(child: _PodiumSlot(entry: second, rank: 2, height: 100)),
        const SizedBox(width: 8),
        // 1st
        Expanded(child: _PodiumSlot(entry: first, rank: 1, height: 130)),
        const SizedBox(width: 8),
        // 3rd
        Expanded(child: _PodiumSlot(entry: third, rank: 3, height: 80)),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  const _PodiumSlot(
      {required this.entry, required this.rank, required this.height});

  Color get _podiumColor {
    switch (rank) {
      case 1: return AppColors.gold;
      case 2: return const Color(0xFFC0C0C0);
      default: return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _podiumColor;
    return Column(
      children: [
        if (rank == 1)
          Text('👑', style: const TextStyle(fontSize: 20))
              .animate().moveY(begin: 8, end: 0, duration: 500.ms).fadeIn(),
        const SizedBox(height: 4),
        Container(
          width: rank == 1 ? 56 : 48,
          height: rank == 1 ? 56 : 48,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: c, width: 2),
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3),
                blurRadius: 12, spreadRadius: 2)],
          ),
          child: Center(
            child: Text(entry.name[0].toUpperCase(),
                style: GoogleFonts.syne(
                    fontSize: rank == 1 ? 22 : 18,
                    fontWeight: FontWeight.w900, color: c)),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 6),
        Text(entry.name.split(' ').first,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textPrimary,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        Text('${entry.xp} XP',
            style: GoogleFonts.inter(
                fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity, height: height,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            border: Border(
              top: BorderSide(color: c.withValues(alpha: 0.4), width: 1.5),
              left: BorderSide(color: c.withValues(alpha: 0.2)),
              right: BorderSide(color: c.withValues(alpha: 0.2)),
            ),
          ),
          child: Center(
            child: Text('#$rank',
                style: GoogleFonts.syne(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: c.withValues(alpha: 0.6))),
          ),
        ),
      ],
    );
  }
}
