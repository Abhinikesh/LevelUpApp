import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/friend_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/stepup_card.dart';
import '../../../shared/widgets/streak_badge.dart';

// Simple friend list provider using raw Dio call
final friendsProvider = FutureProvider<List<FriendModel>>((ref) async {
  // Returns empty list if not yet connected — real impl uses DioClient
  return [];
});

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            floating: true,
            title: Text('Social', style: AppTextStyles.h2),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined,
                    color: AppColors.brand),
                onPressed: () => _showAddFriend(context),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Leaderboard banner
                _LeaderboardBanner()
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, end: 0, delay: 100.ms),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Friends', style: AppTextStyles.h3),
                    TextButton(
                      onPressed: () => _showAddFriend(context),
                      child: Text('+ Add',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.brand)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                friendsAsync.when(
                  loading: () => const ShimmerList(count: 3, itemHeight: 80),
                  error: (e, _) => ErrorState(message: e.toString()),
                  data: (friends) => friends.isEmpty
                      ? EmptyFriends(onAddTap: () => _showAddFriend(context))
                      : Column(
                          children: friends.asMap().entries.map((e) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _FriendCard(friend: e.value)
                                  .animate()
                                  .fadeIn(
                                      delay: Duration(
                                          milliseconds: e.key * 80)),
                            );
                          }).toList(),
                        ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFriend(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.xl,
          AppSpacing.pagePadding,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a Friend', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: AppTextStyles.bodyMedium,
              cursorColor: AppColors.brand,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgDark,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                      color: AppColors.brand, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  minimumSize:
                      const Size(double.infinity, AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Send Request', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StepUpCard(
      hasGradientBorder: true,
      hasGlow: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Global Leaderboard', style: AppTextStyles.h4),
                Text('See where you rank this week',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppColors.brand, size: 16),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final FriendModel friend;
  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return StepUpCard(
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: AppSpacing.avatarMd / 2,
                backgroundColor: AppColors.brand.withOpacity(0.2),
                backgroundImage: friend.avatar.isNotEmpty
                    ? NetworkImage(friend.avatar)
                    : null,
                child: friend.avatar.isEmpty
                    ? Text(AppHelpers.initials(friend.name),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.brand))
                    : null,
              ),
              if (friend.isRecentlyActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.bgCard, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                if (friend.currentRoadmapTitle != null)
                  Text(
                    'Working on: ${friend.currentRoadmapTitle}',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StreakBadge(
              streak: friend.streakCount,
              size: StreakBadgeSize.small,
              animated: false),
        ],
      ),
    );
  }
}
