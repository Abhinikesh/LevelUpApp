import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../models/roadmap_model.dart';
import '../../../shared/providers/roadmap_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class MapListScreen extends ConsumerStatefulWidget {
  const MapListScreen({super.key});

  @override
  ConsumerState<MapListScreen> createState() => _MapListScreenState();
}

class _MapListScreenState extends ConsumerState<MapListScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final _filters = [
    ('all', 'All Campaigns'),
    ('study', '📚 Study'),
    ('gym', '💪 Fitness'),
    ('work', '💼 Career'),
    ('custom', '🎯 Custom'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roadmapProvider.notifier).fetchRoadmaps());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapProvider);
    final allRoadmaps = roadmapState.roadmaps;

    // Filter and search
    final filtered = allRoadmaps.where((r) {
      final matchesFilter = _selectedFilter == 'all' || r.type == _selectedFilter;
      final matchesSearch = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🗺️ My Campaigns',
                          style: GoogleFonts.syne(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${allRoadmaps.length} active roadmap${allRoadmaps.length != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.create),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'New',
                              style: GoogleFonts.syne(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Search Bar & Filter chips
            SliverAppBar(
              backgroundColor: AppColors.bgDark,
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 120,
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search campaigns...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                      itemCount: _filters.length,
                      itemBuilder: (context, i) {
                        final filter = _filters[i];
                        final isSelected = _selectedFilter == filter.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedFilter = filter.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.brand.withValues(alpha: 0.15)
                                    : AppColors.bgCard,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.brand.withValues(alpha: 0.4)
                                      : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  filter.$2,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.brand : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          body: roadmapState.isLoading && !roadmapState.hasLoaded
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.pagePadding),
                  child: Center(child: ShimmerCard(height: 140)),
                )
              : filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.pagePadding),
                      child: Center(
                        child: EmptyRoadmaps(
                          onCreateTap: () => context.push(AppRoutes.create),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: AppSpacing.pagePadding,
                        right: AppSpacing.pagePadding,
                        top: AppSpacing.sm,
                        bottom: MediaQuery.of(context).padding.bottom + 80,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final roadmap = filtered[i];
                        return _RoadmapCard(roadmap: roadmap, index: i)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i * 50))
                            .slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: i * 50));
                      },
                    ),
        ),
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  final RoadmapModel roadmap;
  final int index;

  const _RoadmapCard({required this.roadmap, required this.index});

  Color get _typeColor {
    switch (roadmap.type) {
      case 'gym':
        return AppColors.coral;
      case 'work':
        return AppColors.gold;
      case 'study':
        return AppColors.brand;
      default:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = roadmap.progressPercent;
    final isDone = roadmap.isCompleted;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.map}/${roadmap.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Colored strip at top of card
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _typeColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        roadmap.coverEmoji ?? roadmap.typeEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          roadmap.title,
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          roadmap.type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _typeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (roadmap.description.isNotEmpty) ...[
                    Text(
                      roadmap.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Progress Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${roadmap.currentLevel} of ${roadmap.totalLevels}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _typeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_typeColor, _typeColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Footer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (roadmap.xpEarned > 0) ...[
                            const Text('⚡', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              '${roadmap.xpEarned} XP',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (roadmap.examMode) ...[
                            const Icon(Icons.timer_outlined, size: 12, color: AppColors.coral),
                            const SizedBox(width: 4),
                            Text(
                              'Exam Mode',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.coral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isDone)
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: AppColors.green),
                            const SizedBox(width: 4),
                            Text(
                              'COMPLETED',
                              style: GoogleFonts.syne(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Text(
                              'Play Map',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _typeColor,
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 14, color: _typeColor),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
