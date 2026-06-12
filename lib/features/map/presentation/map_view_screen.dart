import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/level_model.dart';
import '../../../models/roadmap_model.dart';
import '../../../shared/providers/level_provider.dart';
import '../../../shared/providers/roadmap_provider.dart';

// ─── Constants ──────────────────────────────────────────────────
const double _kNodeSize = 80.0;
const double _kSubNodeSize = 48.0;
const double _kNodeSpacing = 110.0;
const String _kBgPrefKey = 'map_bg_theme';

// ─── Map Background Themes ──────────────────────────────────────
enum _MapBg {
  darkPurple,
  deepOcean,
  darkForest,
  midnight,
}

extension _MapBgExt on _MapBg {
  String get label {
    switch (this) {
      case _MapBg.darkPurple:
        return 'Dark Purple';
      case _MapBg.deepOcean:
        return 'Deep Ocean';
      case _MapBg.darkForest:
        return 'Dark Forest';
      case _MapBg.midnight:
        return 'Midnight';
    }
  }

  Color get swatch {
    switch (this) {
      case _MapBg.darkPurple:
        return const Color(0xFF1A0A3E);
      case _MapBg.deepOcean:
        return const Color(0xFF071A2E);
      case _MapBg.darkForest:
        return const Color(0xFF071A0E);
      case _MapBg.midnight:
        return const Color(0xFF000000);
    }
  }

  RadialGradient get gradient {
    switch (this) {
      case _MapBg.darkPurple:
        return const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF1A0A3E), Color(0xFF080810)],
        );
      case _MapBg.deepOcean:
        return const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF071A2E), Color(0xFF080810)],
        );
      case _MapBg.darkForest:
        return const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF071A0E), Color(0xFF080810)],
        );
      case _MapBg.midnight:
        return const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
        );
    }
  }

  Color get dotColor {
    switch (this) {
      case _MapBg.darkPurple:
        return AppColors.brand;
      case _MapBg.deepOcean:
        return const Color(0xFF4A9EFF);
      case _MapBg.darkForest:
        return AppColors.green;
      case _MapBg.midnight:
        return const Color(0xFF444444);
    }
  }
}

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
  late final AnimationController _pulse2Ctrl;
  _MapBg _currentBg = _MapBg.darkPurple;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulse2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pulse2Ctrl.repeat();
    });

    _loadBgPref();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(levelProvider(widget.roadmapId).notifier).fetchLevels();
      _scrollToActive();
    });
  }

  Future<void> _loadBgPref() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_kBgPrefKey) ?? 0;
    if (mounted) {
      setState(() => _currentBg = _MapBg.values[idx]);
    }
  }

  Future<void> _saveBgPref(_MapBg bg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBgPrefKey, bg.index);
    if (mounted) setState(() => _currentBg = bg);
  }

  void _scrollToActive() {
    final screenHeight = MediaQuery.of(context).size.height;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || !_scrollController.hasClients) return;
      final levels = ref.read(levelProvider(widget.roadmapId)).levels;
      final activeIdx =
          levels.indexWhere((l) => l.status == LevelStatus.active);
      if (activeIdx >= 0) {
        final offset =
            (levels.length - activeIdx) * (_kNodeSpacing + _kNodeSize) -
                screenHeight / 2;
        _scrollController.animateTo(
          offset.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showBgSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BgPickerSheet(
        current: _currentBg,
        onSelect: (bg) {
          Navigator.pop(context);
          _saveBgPref(bg);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pulse2Ctrl.dispose();
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brand,
        elevation: 8,
        onPressed: _scrollToActive,
        child: const Icon(Icons.gps_fixed, color: Colors.white),
      ),
      body: Stack(
        children: [
          // ── Radial gradient background ──────────────────────
          Container(
            decoration: BoxDecoration(gradient: _currentBg.gradient),
          ),

          // ── Dot grid overlay ────────────────────────────────
          CustomPaint(
            painter: _DotGridPainter(color: _currentBg.dotColor),
            size: Size.infinite,
          ),

          // ── Scroll content ──────────────────────────────────
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Top bar (pinned)
              SliverPersistentHeader(
                pinned: true,
                delegate: _MapTopBarDelegate(
                  roadmap: roadmap,
                  onBack: () => context.pop(),
                  onSettings: _showBgSheet,
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
                    bottom: MediaQuery.of(context).padding.bottom + 110,
                    top: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _MapBody(
                      levels: levelState.levels,
                      pulseCtrl: _pulseCtrl,
                      pulse2Ctrl: _pulse2Ctrl,
                      roadmapId: widget.roadmapId,
                      hasSubLevels: roadmap?.hasSubLevels ?? false,
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

// ─── Background Settings Picker Sheet ──────────────────────────
class _BgPickerSheet extends StatelessWidget {
  final _MapBg current;
  final ValueChanged<_MapBg> onSelect;
  const _BgPickerSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Map Background',
            style: GoogleFonts.spaceMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a theme for your level map',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _MapBg.values.map((bg) {
              final isSelected = current == bg;
              return GestureDetector(
                onTap: () => onSelect(bg),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: bg.swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brand
                              : AppColors.border,
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.brand.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 24)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bg.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.brand
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Dot Grid Painter ───────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

// ─── Top Bar Delegate ───────────────────────────────────────────
class _MapTopBarDelegate extends SliverPersistentHeaderDelegate {
  final RoadmapModel? roadmap;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  _MapTopBarDelegate({
    required this.roadmap,
    required this.onBack,
    required this.onSettings,
  });

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bgDark.withValues(alpha: 0.94),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Back button
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
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      roadmap?.title ?? 'Loading...',
                      style: GoogleFonts.spaceMono(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          'Level ${roadmap?.currentLevel ?? 0} of ${roadmap?.totalLevels ?? 0}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (roadmap?.hasSubLevels == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'TOPICS',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // XP pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${roadmap?.xpEarned ?? 0} XP',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Settings icon → background picker
              GestureDetector(
                onTap: onSettings,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MapTopBarDelegate old) =>
      old.roadmap != roadmap;
}

// ─── Map Body ───────────────────────────────────────────────────
class _MapBody extends StatelessWidget {
  final List<LevelModel> levels;
  final AnimationController pulseCtrl;
  final AnimationController pulse2Ctrl;
  final String roadmapId;
  final bool hasSubLevels;

  const _MapBody({
    required this.levels,
    required this.pulseCtrl,
    required this.pulse2Ctrl,
    required this.roadmapId,
    required this.hasSubLevels,
  });

  double _xOffsetForIndex(int idx) {
    switch (idx % 4) {
      case 0: return 0.0;
      case 1: return 80.0;
      case 2: return 0.0;
      case 3: return -80.0;
      default: return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final center = screenW / 2 - _kNodeSize / 2;
    final reversed = levels.reversed.toList();

    return Column(
      children: [
        for (int i = 0; i < reversed.length; i++) ...[
          // World banner every 5 levels
          if (i == 0 ||
              (reversed[i].levelNumber % 5 == 1 && i != 0))
            _WorldHeader(
              world: (reversed[i].levelNumber - 1) ~/ 5 + 1,
            ).animate().fadeIn(duration: 300.ms),

          // Connector between nodes
          if (i > 0)
            _ConnectorWidget(
              isCompleted:
                  reversed[i].isCompletedActual ||
                      reversed[i - 1].isCompletedActual,
              fromX: center +
                  _xOffsetForIndex(reversed[i].levelNumber - 1) +
                  _kNodeSize / 2,
              toX: center +
                  _xOffsetForIndex(reversed[i - 1].levelNumber - 1) +
                  _kNodeSize / 2,
            ),

          // Level node (with optional sub-level cluster below)
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset:
                      Offset(_xOffsetForIndex(reversed[i].levelNumber - 1), 0),
                  child: Column(
                    children: [
                      _LevelNode(
                        level: reversed[i],
                        pulseCtrl: pulseCtrl,
                        pulse2Ctrl: pulse2Ctrl,
                        roadmapId: roadmapId,
                        hasSubLevels: hasSubLevels,
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: i * 55),
                              duration: 300.ms)
                          .scale(
                              begin: const Offset(0.6, 0.6),
                              delay: Duration(milliseconds: i * 55),
                              curve: Curves.elasticOut),

                      // ── Sub-level cluster ───────────────────
                      if (hasSubLevels && reversed[i].subLevels.isNotEmpty)
                        _SubLevelCluster(
                          level: reversed[i],
                          animDelay: i * 55,
                        )
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: i * 55 + 120),
                                duration: 300.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

// ─── Sub-Level Cluster ──────────────────────────────────────────
class _SubLevelCluster extends StatelessWidget {
  final LevelModel level;
  final int animDelay;

  const _SubLevelCluster({required this.level, required this.animDelay});

  @override
  Widget build(BuildContext context) {
    final subs = level.subLevels;
    final completedCount = level.completedSubLevelCount;

    return Column(
      children: [
        // Connector from main node to sub cluster
        Container(
          width: 2,
          height: 16,
          color: AppColors.brand.withValues(alpha: 0.3),
        ),
        // Sub-level nodes row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Progress label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 12,
                    color: AppColors.brand.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$completedCount/${subs.length} sub-topics done',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: completedCount == subs.length
                          ? AppColors.green
                          : AppColors.brand.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Sub-level circles
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: subs.asMap().entries.map((e) {
                  final si = e.key;
                  final sub = e.value;
                  return _SubLevelNode(
                    sub: sub,
                    label: '${level.levelNumber}.${si + 1}',
                    parentLevel: level,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sub-Level Node ─────────────────────────────────────────────
class _SubLevelNode extends StatelessWidget {
  final SubLevel sub;
  final String label;
  final LevelModel parentLevel;

  const _SubLevelNode({
    required this.sub,
    required this.label,
    required this.parentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = sub.isCompleted;
    final isActive = !isCompleted && !parentLevel.isLocked;

    Color circleColor;
    Color borderColor;
    Widget centerWidget;

    if (isCompleted) {
      circleColor = AppColors.green.withValues(alpha: 0.2);
      borderColor = AppColors.green;
      centerWidget = const Icon(Icons.check_rounded, size: 16, color: AppColors.green);
    } else if (isActive) {
      circleColor = AppColors.brand.withValues(alpha: 0.2);
      borderColor = AppColors.brand;
      centerWidget = Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.brand,
        ),
      );
    } else {
      circleColor = AppColors.bgCard;
      borderColor = AppColors.border;
      centerWidget = const Icon(Icons.lock_outline, size: 13, color: AppColors.textMuted);
    }

    return GestureDetector(
      onTap: () => _onTap(context, isActive, isCompleted),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _kSubNodeSize,
            height: _kSubNodeSize,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: isActive ? 2 : 1.5),
              boxShadow: isCompleted
                  ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.25), blurRadius: 10)]
                  : isActive
                      ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 12)]
                      : null,
            ),
            child: Center(child: centerWidget),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              sub.title,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: isActive || isCompleted
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, bool isActive, bool isCompleted) {
    if (!isActive && !isCompleted) {
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
            Text('Complete parent level first',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ]),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubLevelBottomSheet(
        sub: sub,
        parentLevel: parentLevel,
        label: label,
        isCompleted: isCompleted,
      ),
    );
  }
}

// ─── Sub-Level Bottom Sheet ─────────────────────────────────────
class _SubLevelBottomSheet extends StatelessWidget {
  final SubLevel sub;
  final LevelModel parentLevel;
  final String label;
  final bool isCompleted;

  const _SubLevelBottomSheet({
    required this.sub,
    required this.parentLevel,
    required this.label,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      maxChildSize: 0.78,
      minChildSize: 0.35,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  // Sub-level badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'SUB-TOPIC $label',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brand,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ShaderMask(
                      shaderCallback: (b) => AppColors.brandGradient
                          .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: Text(
                        sub.title,
                        style: GoogleFonts.spaceMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Part of: ${parentLevel.title}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (sub.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      sub.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
                        label: sub.proofType,
                        color: AppColors.brand,
                      ),
                      _InfoChip(
                        icon: Icons.bolt,
                        label: '${parentLevel.xpReward ~/ (parentLevel.subLevels.isEmpty ? 1 : parentLevel.subLevels.length)} XP',
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Sub-topic completed!',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text('Close', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                          '${AppRoutes.verification}/${sub.compositeId}/${sub.proofType}',
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
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Start Sub-topic',
                            style: GoogleFonts.spaceMono(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

// ─── World Header Banner ────────────────────────────────────────
class _WorldHeader extends StatelessWidget {
  final int world;
  const _WorldHeader({required this.world});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.brand.withValues(alpha: 0.30), width: 1),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.brand, size: 16),
            const SizedBox(width: 8),
            Text(
              'WORLD $world',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.brand,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star_rounded, color: AppColors.brand, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Connector Widget ───────────────────────────────────────────
class _ConnectorWidget extends StatelessWidget {
  final bool isCompleted;
  final double fromX;
  final double toX;

  const _ConnectorWidget({
    required this.isCompleted,
    required this.fromX,
    required this.toX,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(
          isCompleted: isCompleted,
          fromX: fromX,
          toX: toX,
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
      ..strokeWidth = isCompleted ? 4 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(fromX, size.height)
      ..cubicTo(
        fromX, size.height * 0.5,
        toX, size.height * 0.5,
        toX, 0,
      );

    if (isCompleted) {
      canvas.drawPath(path, paint);
    } else {
      _drawDashed(canvas, path, paint);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashLen = 8.0;
    const gapLen = 6.0;
    final metrics = path.computeMetrics();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    double d = 0;
    while (d < metric.length) {
      final end = (d + dashLen).clamp(0, metric.length);
      canvas.drawPath(metric.extractPath(d, end.toDouble()), paint);
      d += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter o) =>
      o.isCompleted != isCompleted || o.fromX != fromX || o.toX != toX;
}

// ─── Level Node ─────────────────────────────────────────────────
class _LevelNode extends ConsumerWidget {
  final LevelModel level;
  final AnimationController pulseCtrl;
  final AnimationController pulse2Ctrl;
  final String roadmapId;
  final bool hasSubLevels;

  const _LevelNode({
    required this.level,
    required this.pulseCtrl,
    required this.pulse2Ctrl,
    required this.roadmapId,
    required this.hasSubLevels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Column(
        children: [
          SizedBox(
            width: _kNodeSize + 44,
            height: _kNodeSize + 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Active: two animated pulse rings ──────────
                if (level.status == LevelStatus.active) ...[
                  AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (_, __) {
                      final scale = 1.0 + 0.4 * pulseCtrl.value;
                      final opacity =
                          (0.6 * (1.0 - pulseCtrl.value)).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: _kNodeSize,
                          height: _kNodeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand
                                .withValues(alpha: opacity * 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: pulse2Ctrl,
                    builder: (_, __) {
                      final scale = 1.0 + 0.6 * pulse2Ctrl.value;
                      final opacity =
                          (0.4 * (1.0 - pulse2Ctrl.value)).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: _kNodeSize,
                          height: _kNodeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand
                                .withValues(alpha: opacity * 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // ── Glow ring when all sub-topics done ────────
                if (hasSubLevels && level.isCompletedActual)
                  Container(
                    width: _kNodeSize + 16,
                    height: _kNodeSize + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),

                // ── Main node circle ───────────────────────────
                _NodeCircle(
                  status: level.status,
                  subProgress: hasSubLevels ? level.subLevelProgress : null,
                ),
              ],
            ),
          ),
          // Label
          _NodeLabel(level: level, hasSubLevels: hasSubLevels),
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
            const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 16),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelBottomSheet(
          level: level, isCompleted: level.isCompletedActual),
    );
  }
}

// ─── Node Circle ────────────────────────────────────────────────
class _NodeCircle extends StatelessWidget {
  final LevelStatus status;
  final double? subProgress; // 0.0–1.0, null = no sub-levels

  const _NodeCircle({required this.status, this.subProgress});

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
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 4,
              )
            ],
          ),
          child: const Icon(Icons.check_rounded,
              color: Colors.white, size: 32),
        );

      case LevelStatus.active:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _kNodeSize,
              height: _kNodeSize,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 6)
                ],
              ),
              child: subProgress != null && subProgress! > 0
                  ? Center(
                      child: Text(
                        '${(subProgress! * 100).round()}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
            ),
            // Circular progress arc for sub-levels
            if (subProgress != null && subProgress! > 0)
              SizedBox(
                width: _kNodeSize,
                height: _kNodeSize,
                child: CircularProgressIndicator(
                  value: subProgress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        );

      case LevelStatus.locked:
        return Container(
          width: _kNodeSize,
          height: _kNodeSize,
          decoration: BoxDecoration(
            color: const Color(0xFF161625),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: const Icon(Icons.lock_outline,
              color: AppColors.textMuted, size: 24),
        );
    }
  }
}

// ─── Node Label ─────────────────────────────────────────────────
class _NodeLabel extends StatelessWidget {
  final LevelModel level;
  final bool hasSubLevels;
  const _NodeLabel({required this.level, required this.hasSubLevels});

  @override
  Widget build(BuildContext context) {
    final numStr = level.levelNumber.toString().padLeft(2, '0');

    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Text(
            numStr,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          Text(
            level.title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (level.status == LevelStatus.active && !hasSubLevels)
            Text(
              'TAP TO PLAY',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: AppColors.brand,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -3, duration: 600.ms),
          if (hasSubLevels && level.subLevels.isNotEmpty)
            Text(
              '${level.completedSubLevelCount}/${level.subLevels.length} done',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: level.isCompletedActual
                    ? AppColors.green
                    : AppColors.brand.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Level Bottom Sheet ─────────────────────────────────────────
class _LevelBottomSheet extends StatelessWidget {
  final LevelModel level;
  final bool isCompleted;
  const _LevelBottomSheet({required this.level, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      maxChildSize: 0.80,
      minChildSize: 0.35,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
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
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  // World badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'WORLD ${((level.levelNumber - 1) ~/ 5) + 1}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ShaderMask(
                      shaderCallback: (b) => AppColors.brandGradient
                          .createShader(
                              Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: Text(
                        'Level ${level.levelNumber}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      level.title,
                      style: GoogleFonts.spaceMono(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (level.description.isNotEmpty)
                    Center(
                      child: Text(
                        level.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                        color: AppColors.brand,
                      ),
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: '${level.estimatedMinutes} min',
                        color: AppColors.teal,
                      ),
                      _InfoChip(
                        icon: Icons.bolt,
                        label: '${level.xpReward} XP',
                        color: AppColors.gold,
                      ),
                      if (level.subLevels.isNotEmpty)
                        _InfoChip(
                          icon: Icons.account_tree_outlined,
                          label: '${level.subLevels.length} sub-topics',
                          color: const Color(0xFFFF9F43),
                        ),
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
                              fontWeight: FontWeight.w600,
                            ),
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
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text('Review Level',
                          style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold)),
                    ),
                  ] else if (level.subLevels.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined,
                              color: AppColors.brand, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This level has ${level.subLevels.length} sub-topics. Tap each sub-topic node on the map to complete them.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
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
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text('View Sub-topics on Map',
                          style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold)),
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
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Start Level',
                            style: GoogleFonts.spaceMono(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

// ─── Info Chip ──────────────────────────────────────────────────
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

// ─── Loading Shimmer ────────────────────────────────────────────
class _MapLoadingShimmer extends StatelessWidget {
  const _MapLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(
                duration: 1200.ms,
                color: AppColors.brand.withValues(alpha: 0.1)),
        const SizedBox(height: 16),
        Text('Loading map...',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }
}
