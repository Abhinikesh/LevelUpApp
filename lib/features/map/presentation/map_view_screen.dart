import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../models/level_model.dart';
import '../../../models/roadmap_model.dart';
import '../../../shared/providers/level_provider.dart';
import '../../../shared/providers/roadmap_provider.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final String roadmapId;
  const MapViewScreen({super.key, required this.roadmapId});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(levelProvider(widget.roadmapId).notifier).fetchLevels();
      _scrollToActive();
    });
  }

  void _scrollToActive() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_scrollController.hasClients) {
        final levels = ref.read(levelProvider(widget.roadmapId)).levels;
        final activeIdx =
            levels.indexWhere((l) => l.status == LevelStatus.active);
        if (activeIdx >= 0) {
          final offset =
              (levels.length - activeIdx) * (_kNodeSpacing + _kNodeSize) -
                  MediaQuery.of(context).size.height / 2;
          _scrollController.animateTo(
            offset.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelState = ref.watch(levelProvider(widget.roadmapId));
    final roadmapState = ref.watch(roadmapProvider);
    final roadmap = roadmapState.roadmaps
        .cast<RoadmapModel?>()
        .firstWhere((r) => r?.id == widget.roadmapId, orElse: () => null);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Dot grid background
          CustomPaint(
            painter: _DotGridPainter(),
            size: Size.infinite,
          ),

          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Top bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _MapTopBarDelegate(
                  roadmap: roadmap,
                  onBack: () => context.pop(),
                ),
              ),

              // Level nodes
              if (levelState.isLoading && levelState.levels.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: _MapLoadingShimmer()),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 40,
                    top: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _MapBody(
                      levels: levelState.levels,
                      pulseCtrl: _pulseCtrl,
                      roadmapId: widget.roadmapId,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Constants ─────────────────────────────────────────────────
const double _kNodeSize = 72;
const double _kNodeSpacing = 100;
const double _kHorizontalOffset = 80;

// ─── Dot Grid Painter ──────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Top Bar ───────────────────────────────────────────────────
class _MapTopBarDelegate extends SliverPersistentHeaderDelegate {
  final RoadmapModel? roadmap;
  final VoidCallback onBack;

  _MapTopBarDelegate({required this.roadmap, required this.onBack});

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bgDark.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.textPrimary, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      roadmap?.title ?? 'Loading...',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Level ${roadmap?.currentLevel ?? 0} of ${roadmap?.totalLevels ?? 0}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // XP progress pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${roadmap?.xpEarned ?? 0} XP',
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MapTopBarDelegate oldDelegate) =>
      oldDelegate.roadmap != roadmap;
}

// ─── Map Body ──────────────────────────────────────────────────
class _MapBody extends StatelessWidget {
  final List<LevelModel> levels;
  final AnimationController pulseCtrl;
  final String roadmapId;

  const _MapBody({
    required this.levels,
    required this.pulseCtrl,
    required this.roadmapId,
  });

  double _xOffset(int index) {
    final pattern = index % 4;
    switch (pattern) {
      case 0:
        return 0;
      case 1:
        return _kHorizontalOffset;
      case 2:
        return 0;
      case 3:
        return -_kHorizontalOffset;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final center = screenW / 2 - _kNodeSize / 2;
    // Reversed: bottom of column = level 1
    final reversed = levels.reversed.toList();

    return Column(
      children: [
        for (int i = 0; i < reversed.length; i++) ...[
          // World header every 5 levels
          if ((reversed.length - 1 - i) % 5 == 4)
            _WorldHeader(world: (reversed.length - 1 - i) ~/ 5 + 1)
                .animate()
                .fadeIn(duration: 300.ms),

          // Connector above (not for last item)
          if (i > 0)
            _ConnectorWidget(
              isCompleted: reversed[i].status == LevelStatus.completed ||
                  reversed[i - 1].status == LevelStatus.completed,
              fromOffset: center + _xOffset(reversed.length - 1 - i),
              toOffset: center + _xOffset(reversed.length - i),
            ),

          // Level node
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(_xOffset(reversed.length - 1 - i), 0),
                  child: _LevelNode(
                    level: reversed[i],
                    pulseCtrl: pulseCtrl,
                    roadmapId: roadmapId,
                  )
                      .animate()
                      .fadeIn(
                          delay: Duration(milliseconds: i * 60),
                          duration: 300.ms)
                      .scale(
                          begin: const Offset(0.6, 0.6),
                          delay: Duration(milliseconds: i * 60),
                          curve: Curves.elasticOut),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ─── World Header ──────────────────────────────────────────────
class _WorldHeader extends StatelessWidget {
  final int world;
  const _WorldHeader({required this.world});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brand.withValues(alpha: 0.15),
            AppColors.coral.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.brand.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 14)),
          const Text('⭐', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 12),
          Text(
            'WORLD $world',
            style: GoogleFonts.syne(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.brand,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          const Text('⭐', style: TextStyle(fontSize: 11)),
          const Text('⭐', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Connector Widget ──────────────────────────────────────────
class _ConnectorWidget extends StatelessWidget {
  final bool isCompleted;
  final double fromOffset;
  final double toOffset;

  const _ConnectorWidget({
    required this.isCompleted,
    required this.fromOffset,
    required this.toOffset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kNodeSpacing - _kNodeSize,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(
          isCompleted: isCompleted,
          fromX: fromOffset + _kNodeSize / 2,
          toX: toOffset + _kNodeSize / 2,
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool isCompleted;
  final double fromX;
  final double toX;

  _ConnectorPainter(
      {required this.isCompleted, required this.fromX, required this.toX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted ? AppColors.green : AppColors.border
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(fromX, 0)
      ..cubicTo(
        fromX, size.height * 0.3,
        toX, size.height * 0.7,
        toX, size.height,
      );

    if (isCompleted) {
      canvas.drawPath(path, paint);
    } else {
      // Dashed
      _drawDashed(canvas, path, paint);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashLen = 8.0;
    const gapLen = 6.0;
    final metric = path.computeMetrics().first;
    double d = 0;
    while (d < metric.length) {
      final end = (d + dashLen).clamp(0, metric.length);
      canvas.drawPath(metric.extractPath(d, end.toDouble()), paint);
      d += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter o) =>
      o.isCompleted != isCompleted;
}

// ─── Level Node ────────────────────────────────────────────────
class _LevelNode extends ConsumerWidget {
  final LevelModel level;
  final AnimationController pulseCtrl;
  final String roadmapId;

  const _LevelNode({
    required this.level,
    required this.pulseCtrl,
    required this.roadmapId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Column(
        children: [
          SizedBox(
            width: _kNodeSize + 24,
            height: _kNodeSize + 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring for active
                if (level.status == LevelStatus.active)
                  AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (_, __) {
                      final scale = 1.0 + 0.6 * pulseCtrl.value;
                      final opacity = (1.0 - pulseCtrl.value) * 0.6;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: _kNodeSize,
                          height: _kNodeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.brand.withValues(alpha: opacity),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Main node circle
                _NodeCircle(status: level.status),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _NodeLabel(level: level),
        ],
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (level.status == LevelStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border)),
          content: Row(children: [
            const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text('Complete previous level first',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          ]),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (level.status == LevelStatus.active) {
      _showActiveLevelSheet(context);
    } else {
      _showCompletedLevelSheet(context);
    }
  }

  void _showActiveLevelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelBottomSheet(level: level, isCompleted: false),
    );
  }

  void _showCompletedLevelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelBottomSheet(level: level, isCompleted: true),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  final LevelStatus status;
  const _NodeCircle({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LevelStatus.completed:
        return Container(
          width: _kNodeSize,
          height: _kNodeSize,
          decoration: BoxDecoration(
            gradient: AppColors.greenGradient,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2)
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
        );

      case LevelStatus.active:
        return Container(
          width: _kNodeSize,
          height: _kNodeSize,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brand, width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.6),
                  blurRadius: 30,
                  spreadRadius: 4)
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 28),
        );

      case LevelStatus.locked:
        return Container(
          width: _kNodeSize,
          height: _kNodeSize,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: const Icon(Icons.lock_outline,
              color: AppColors.textMuted, size: 22),
        );
    }
  }
}

class _NodeLabel extends StatelessWidget {
  final LevelModel level;
  const _NodeLabel({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          Text(
            'Level ${level.levelNumber}',
            style: GoogleFonts.inter(
                fontSize: 10, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          Text(
            level.title,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (level.status == LevelStatus.active)
            Text(
              'TAP TO PLAY',
              style: GoogleFonts.syne(
                fontSize: 9,
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -3, duration: 600.ms),
        ],
      ),
    );
  }
}

// ─── Level Bottom Sheet ────────────────────────────────────────
class _LevelBottomSheet extends StatelessWidget {
  final LevelModel level;
  final bool isCompleted;

  const _LevelBottomSheet({required this.level, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.75,
      minChildSize: 0.35,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  // World badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'WORLD ${((level.levelNumber - 1) ~/ 5) + 1}',
                        style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Level number
                  Center(
                    child: ShaderMask(
                      shaderCallback: (b) => AppColors.brandGradient
                          .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: Text(
                        'Level ${level.levelNumber}',
                        style: GoogleFonts.syne(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      level.title,
                      style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level.description,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Info chips
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                          icon: Icons.quiz_outlined,
                          label: level.proofTypeLabel,
                          color: AppColors.brand),
                      _InfoChip(
                          icon: Icons.timer_outlined,
                          label: '${level.estimatedMinutes} min',
                          color: AppColors.teal),
                      _InfoChip(
                          icon: Icons.bolt,
                          label: '${level.xpReward} XP',
                          color: AppColors.gold),
                    ],
                  ),

                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Completed • +${level.xpReward} XP earned',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.green,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        side: const BorderSide(color: AppColors.brand),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text('Review Level',
                          style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700)),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                          '${AppRoutes.verification}/${level.id}/${level.proofType}',
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.brand.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Start Level',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Loading Shimmer ───────────────────────────────────────────
class _MapLoadingShimmer extends StatelessWidget {
  const _MapLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 1200.ms, color: AppColors.brand.withValues(alpha: 0.1)),
        const SizedBox(height: 16),
        Text('Loading map...',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }
}
