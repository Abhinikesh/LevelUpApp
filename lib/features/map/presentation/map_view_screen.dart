import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/level_model.dart';
import '../../../models/roadmap_model.dart';
import '../../../shared/providers/level_provider.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final String roadmapId;
  const MapViewScreen({super.key, required this.roadmapId});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(levelProvider(widget.roadmapId).notifier).fetchLevels());
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = ref.watch(roadmapProvider).roadmaps
        .cast<RoadmapModel?>()
        .firstWhere((r) => r?.id == widget.roadmapId, orElse: () => null);
    final levelState = ref.watch(levelProvider(widget.roadmapId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(roadmap?.title ?? 'Roadmap', style: AppTextStyles.h3),
        actions: [
          if (roadmap != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.base),
              child: Center(
                child: Text(
                  '${roadmap.currentLevel}/${roadmap.totalLevels}',
                  style: AppTextStyles.label.copyWith(color: AppColors.brand),
                ),
              ),
            ),
        ],
      ),
      body: levelState.isLoading && !levelState.hasLoaded
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: ShimmerList(count: 5, itemHeight: 80),
            )
          : levelState.levels.isEmpty
              ? const ErrorState(message: 'No levels found for this roadmap.')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    100,
                  ),
                  itemCount: levelState.levels.length,
                  itemBuilder: (context, i) {
                    final level = levelState.levels[i];
                    final isLast = i == levelState.levels.length - 1;
                    return _LevelMapNode(
                      level: level,
                      index: i,
                      isLast: isLast,
                      roadmapId: widget.roadmapId,
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: i * 60))
                        .slideX(
                          begin: i.isEven ? -0.1 : 0.1,
                          end: 0,
                          delay: Duration(milliseconds: i * 60),
                        );
                  },
                ),
    );
  }
}

class _LevelMapNode extends StatelessWidget {
  final LevelModel level;
  final int index;
  final bool isLast;
  final String roadmapId;

  const _LevelMapNode({
    required this.level,
    required this.index,
    required this.isLast,
    required this.roadmapId,
  });

  Color get _nodeColor {
    switch (level.state) {
      case LevelState.completed:
        return AppColors.green;
      case LevelState.active:
        return AppColors.brand;
      case LevelState.locked:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = level.state == LevelState.active;
    final isCompleted = level.state == LevelState.completed;
    final isLocked = level.state == LevelState.locked;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline ────────────────────────────────────────
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Circle node
                GestureDetector(
                  onTap: isLocked
                      ? null
                      : () => context.push('/level/${level.id}'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isCompleted
                          ? AppColors.greenGradient
                          : isActive
                              ? AppColors.brandGradient
                              : null,
                      color: isLocked ? AppColors.bgCardLight : null,
                      border: Border.all(
                        color: _nodeColor,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.brand.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : isCompleted
                              ? [
                                  BoxShadow(
                                    color: AppColors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 22)
                          : isLocked
                              ? const Icon(Icons.lock_outline,
                                  color: AppColors.textMuted, size: 18)
                              : Text(
                                  '${level.levelNumber}',
                                  style: AppTextStyles.h4.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                    ),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _nodeColor.withOpacity(0.6),
                            AppColors.border,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: isLocked
                  ? null
                  : () => context.push('/level/${level.id}'),
              child: AnimatedOpacity(
                opacity: isLocked ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.only(
                      left: AppSpacing.md, bottom: AppSpacing.base),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.brand.withOpacity(0.08)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isActive
                          ? AppColors.brand.withOpacity(0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              level.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isLocked
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(level.proofTypeIcon,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      if (level.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          level.description,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(level.estimatedTime,
                              style: AppTextStyles.caption),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.bolt,
                              size: 13, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text('+${level.xpReward} XP',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gold)),
                          if (isActive) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('START',
                                  style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ],
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
