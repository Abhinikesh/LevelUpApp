import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/providers/social_provider.dart';
import '../../../shared/widgets/premium_animations.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(socialProvider.notifier).init();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SocialState>(socialProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.coral,
              content: Text(
                next.error!,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          );
          ref.read(socialProvider.notifier).clearError();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Custom modern pill tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SocialTabBar(ctrl: _tabCtrl),
            ),
            const SizedBox(height: 12),
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

// ─── Modern Pill Tab Bar ─────────────────────────────────────────
class _SocialTabBar extends StatelessWidget {
  final TabController ctrl;
  const _SocialTabBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: ctrl,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.syne(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.syne(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Friends'),
          Tab(text: 'Leaderboard'),
        ],
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
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: BounceOnTap(
                  onTap: () => _showAddFriendSheet(context, ref),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Add friend by email address...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'INVITE',
                            style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Pending Friend Requests
            if (social.pendingRequests.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Friend Requests',
                            style: GoogleFonts.syne(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${social.pendingRequests.length}',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...social.pendingRequests.map((f) {
                        return SlideFadeTransition(
                          child: _RequestCard(friend: f),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Friends List Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Circle',
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${social.friends.length} active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Friends List Grid/List
            if (social.friends.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.group_add_rounded,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Solo Journey?',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Invite friends to level up together!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => HoverShift(
                    child: _FriendCard(
                      friend: social.friends[i],
                      index: i,
                    ),
                  ),
                  childCount: social.friends.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // Add Friend Quick FAB
        Positioned(
          bottom: 24,
          right: 20,
          child: BounceOnTap(
            onTap: () => _showAddFriendSheet(context, ref),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        ),
      ],
    );
  }

  void _showAddFriendSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
            Text(
              'Add Friend',
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a friend invitation to kickstart the friendly competition.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your friend\'s email address...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  icon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            BounceOnTap(
              onTap: () async {
                final email = controller.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(context);
                final success = await ref.read(socialProvider.notifier).sendFriendInvite(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Invite sent to $email!' : 'Failed to send invite',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: success ? AppColors.green : AppColors.coral,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    'Send Invitation',
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final MockFriend friend;
  const _RequestCard({required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                Text(
                  friend.name,
                  style: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pending invitation request',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          BounceOnTap(
            onTap: () async {
              if (friend.id != null) {
                final success = await ref.read(socialProvider.notifier).acceptRequest(friend.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Request accepted!' : 'Failed to accept request'),
                      backgroundColor: success ? AppColors.green : AppColors.coral,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.greenGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Accept',
                style: GoogleFonts.syne(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BounceOnTap(
            onTap: () async {
              if (friend.id != null) {
                final success = await ref.read(socialProvider.notifier).declineRequest(friend.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Request declined' : 'Failed to decline request'),
                      backgroundColor: AppColors.coral,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Decline',
                style: GoogleFonts.syne(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Avatar(name: friend.name, color: friend.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  friend.status,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const WobbleWidget(
                      duration: Duration(milliseconds: 1200),
                      child: Text('🔥', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${friend.streak} day streak',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${friend.progress}%',
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 2),
              if (friend.ahead != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: friend.ahead > 0
                        ? AppColors.green.withValues(alpha: 0.08)
                        : AppColors.coral.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    friend.ahead > 0
                        ? '${friend.ahead} levels ahead'
                        : '${-friend.ahead} levels behind',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: friend.ahead > 0 ? AppColors.green : AppColors.coral,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: index * 60),
          duration: 350.ms,
        );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.syne(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
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
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top 3 Podium
        if (leaders.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: _Podium(leaders: leaders.take(3).toList()),
            ),
          ),

        // Leaderboard title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Leaderboard Standings',
              style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),

        // Rank list (4+)
        if (leaders.length <= 3)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox.shrink(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final rank = i + 4;
                final entry = leaders.length > i + 3 ? leaders[i + 3] : null;
                if (entry == null) return null;
                final isMe = entry.isCurrentUser;
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.brand.withValues(alpha: 0.08)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isMe ? AppColors.brand.withValues(alpha: 0.4) : AppColors.border,
                      width: isMe ? 1.5 : 1.0,
                    ),
                    boxShadow: isMe
                        ? [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          '#$rank',
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isMe ? AppColors.brand : AppColors.textMuted,
                          ),
                        ),
                      ),
                      _Avatar(name: entry.name, color: entry.color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  entry.name,
                                  style: GoogleFonts.syne(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.brandGradient,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      'YOU',
                                      style: GoogleFonts.syne(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.xp} XP total earned',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: i * 40),
                      duration: 300.ms,
                    );
              },
              childCount: leaders.length - 3,
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
    if (leaders.isEmpty) return const SizedBox.shrink();
    
    final first = leaders[0];
    final second = leaders.length > 1 ? leaders[1] : null;
    final third = leaders.length > 2 ? leaders[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place Column
        if (second != null)
          Expanded(child: _PodiumSlot(entry: second, rank: 2, height: 105))
        else
          Expanded(child: Container()),
        const SizedBox(width: 10),

        // 1st Place Column
        Expanded(child: _PodiumSlot(entry: first, rank: 1, height: 140)),
        const SizedBox(width: 10),

        // 3rd Place Column
        if (third != null)
          Expanded(child: _PodiumSlot(entry: third, rank: 3, height: 85))
        else
          Expanded(child: Container()),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.height,
  });

  Color get _podiumColor {
    switch (rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _podiumColor;
    final isMe = entry.isCurrentUser;

    return Column(
      children: [
        if (rank == 1)
          const Text('👑', style: TextStyle(fontSize: 24))
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: 4, end: -4, duration: 800.ms, curve: Curves.easeInOutSine)
        else
          const SizedBox(height: 24),
        const SizedBox(height: 6),

        // Avatar
        Container(
          width: rank == 1 ? 64 : 52,
          height: rank == 1 ? 64 : 52,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: c, width: rank == 1 ? 2.5 : 2.0),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: Center(
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: GoogleFonts.syne(
                fontSize: rank == 1 ? 24 : 18,
                fontWeight: FontWeight.w900,
                color: c,
              ),
            ),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 8),

        // User Name
        Text(
          entry.name.split(' ').first,
          style: GoogleFonts.syne(
            fontSize: rank == 1 ? 14 : 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),

        // XP Text
        Text(
          '${entry.xp} XP',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Podium Column Block
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: isMe ? AppColors.brand.withValues(alpha: 0.12) : c.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: isMe ? AppColors.brand : c, width: 2),
              left: BorderSide(color: isMe ? AppColors.brand.withValues(alpha: 0.25) : c.withValues(alpha: 0.15)),
              right: BorderSide(color: isMe ? AppColors.brand.withValues(alpha: 0.25) : c.withValues(alpha: 0.15)),
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: GoogleFonts.syne(
                  fontSize: rank == 1 ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: isMe ? AppColors.brand.withValues(alpha: 0.8) : c.withValues(alpha: 0.6),
                ),
              ),
              if (isMe) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'YOU',
                    style: GoogleFonts.syne(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
