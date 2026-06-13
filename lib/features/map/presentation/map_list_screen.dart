import 'dart:math';
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
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/premium_animations.dart';

class MapListScreen extends ConsumerStatefulWidget {
  const MapListScreen({super.key});

  @override
  ConsumerState<MapListScreen> createState() => _MapListScreenState();
}

class _MapListScreenState extends ConsumerState<MapListScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // filter id, label (no emoji for cleaner chips)
  static const _filters = [
    ('all', 'All'),
    ('study', 'Study'),
    ('gym', 'Fitness'),
    ('work', 'Work'),
    ('custom', 'Custom'),
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
    final activeCount = allRoadmaps.where((r) => !r.isCompleted).length;

    final filtered = allRoadmaps.where((r) {
      final matchesFilter =
          _selectedFilter == 'all' || r.type == _selectedFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      // FAB: gradient circle, navigates to create
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: BounceOnTap(
          onTap: () => context.push(AppRoutes.create),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Roadmaps',
                    style: GoogleFonts.spaceMono(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$activeCount active roadmap${activeCount != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.04),
            ),

            const SizedBox(height: 14),

            // ── Search bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search roadmaps...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close,
                              size: 16, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 60.ms),
            ),

            const SizedBox(height: 12),

            // ── Filter chips ─────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final (id, label) = _filters[i];
                  final isSelected = _selectedFilter == id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected ? AppColors.brandGradient : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.border,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.brand.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: roadmapState.isLoading && !roadmapState.hasLoaded
                  ? _buildShimmer()
                  : filtered.isEmpty
                      ? _buildEmpty(context)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: AppSpacing.pagePadding,
                            right: AppSpacing.pagePadding,
                            top: 4,
                            bottom:
                                MediaQuery.of(context).padding.bottom + 100,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            return _RoadmapListCard(
                                    roadmap: filtered[i])
                                .animate()
                                .fadeIn(
                                    delay:
                                        Duration(milliseconds: 120 + i * 55))
                                .slideY(
                                    begin: 0.06,
                                    end: 0,
                                    delay: Duration(
                                        milliseconds: 120 + i * 55));
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding, vertical: 8),
      itemCount: 4,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerCard(height: 90),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EmptyStateMapWidget(),
          const SizedBox(height: 16),
          Text(
            'No roadmaps yet',
            style: GoogleFonts.spaceMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first goal to get started',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BounceOnTap(
            onTap: () => context.push(AppRoutes.create),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                '+ Create Roadmap',
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State Map Widget ──────────────────────────────────────
class _EmptyStateMapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 140,
      child: CustomPaint(
        painter: _WindingRoadmapPainter(),
      ),
    );
  }
}

class _WindingRoadmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Draw winding pathway path
    final path = Path()
      ..moveTo(20, size.height - 20)
      ..cubicTo(size.width * 0.2, size.height * 0.8, size.width * 0.1, size.height * 0.3, size.width * 0.5, size.height * 0.4)
      ..cubicTo(size.width * 0.8, size.height * 0.5, size.width * 0.7, size.height * 0.1, size.width - 20, 20);

    canvas.drawPath(path, pathPaint);

    // Draw nodes on path
    final nodePaint = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.fill;

    final activeNodePaint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(35, 110), 8, nodePaint);
    canvas.drawCircle(const Offset(90, 75), 8, nodePaint);
    canvas.drawCircle(const Offset(140, 35), 8, activeNodePaint);

    // Draw some stars
    final starPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    _drawStar(canvas, const Offset(30, 30), 6, starPaint);
    _drawStar(canvas, const Offset(150, 110), 4, starPaint);
    _drawStar(canvas, const Offset(100, 20), 5, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      double angle = i * 4 * pi / 5 - pi / 2;
      double x = center.dx + radius * (i % 2 == 0 ? 1.0 : 0.4) * cos(angle);
      double y = center.dy + radius * (i % 2 == 0 ? 1.0 : 0.4) * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Style Chip for Map style selector ────────────────────────────
class _StyleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.brand : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Roadmap List Card ─────────────────────────────────────────
class _RoadmapListCard extends ConsumerWidget {
  final RoadmapModel roadmap;
  const _RoadmapListCard({required this.roadmap});

  Color get _accentColor {
    switch (roadmap.type) {
      case 'study':
        return AppColors.brand;
      case 'gym':
        return const Color(0xFFFF8C00);
      case 'work':
        return AppColors.green;
      default:
        return AppColors.coral;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _accentColor;
    final progress = roadmap.progressPercent;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.map}/${roadmap.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Left accent bar: 4px full height
              Container(
                width: 4,
                color: color,
              ),

              // Emoji circle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      roadmap.coverEmoji ?? roadmap.typeEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),

              // Center content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        roadmap.title,
                        style: GoogleFonts.spaceMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Map style choice chips
                      Row(
                        children: [
                          _StyleChip(
                            label: 'Simple',
                            isSelected: roadmap.mapStyle == 'simple',
                            onTap: () {
                              if (roadmap.mapStyle != 'simple') {
                                final updated = roadmap.copyWith(mapStyle: 'simple');
                                ref.read(roadmapProvider.notifier).updateRoadmapLocally(updated);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _StyleChip(
                            label: 'Topics',
                            isSelected: roadmap.mapStyle == 'sublevels',
                            onTap: () {
                              if (roadmap.mapStyle != 'sublevels') {
                                final updated = roadmap.copyWith(mapStyle: 'sublevels');
                                ref.read(roadmapProvider.notifier).updateRoadmapLocally(updated);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress subtitle
                      Text(
                        'Level ${roadmap.currentLevel} of ${roadmap.totalLevels} • ${(progress * 100).toInt()}% complete',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Thin 3px progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(
                              height: 3,
                              color: AppColors.bgCardLight,
                            ),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
