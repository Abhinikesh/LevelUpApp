import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_themes.dart';

class AnimatedMapBackground extends ConsumerStatefulWidget {
  final String themeId; // 'nebula', 'ocean', 'forest', 'midnight'
  final Widget? child;

  const AnimatedMapBackground({
    super.key,
    required this.themeId,
    this.child,
  });

  @override
  ConsumerState<AnimatedMapBackground> createState() => _AnimatedMapBackgroundState();
}

class _AnimatedMapBackgroundState extends ConsumerState<AnimatedMapBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_MapParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _generateParticles();
  }

  @override
  void didUpdateWidget(covariant AnimatedMapBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeId != widget.themeId) {
      _generateParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateParticles() {
    _particles.clear();
    final count = widget.themeId == 'ocean' ? 22 : 18;

    for (int i = 0; i < count; i++) {
      // Base coordinates (normalized 0.0 to 1.0)
      final x = _random.nextDouble();
      final y = _random.nextDouble();
      final speed = 0.15 + _random.nextDouble() * 0.25;
      final scale = 1.0 + _random.nextDouble() * 2.5; // multiplier for size

      // Drift physics
      final driftAmp = 0.04 + _random.nextDouble() * 0.06;
      final driftFreq = 1.0 + _random.nextDouble() * 2.0;
      final phase = _random.nextDouble() * math.pi * 2;

      // Color selection based on theme
      Color color;
      if (widget.themeId == 'nebula') {
        color = _random.nextBool() ? const Color(0xFF7B6EF6) : const Color(0xFFFF5E7D);
      } else if (widget.themeId == 'ocean') {
        color = _random.nextBool() ? const Color(0xFF00E5FF) : const Color(0xFF2E86FF);
      } else if (widget.themeId == 'forest') {
        color = _random.nextBool() ? const Color(0xFF2ECC71) : const Color(0xFFA8E063);
      } else {
        color = Colors.transparent;
      }

      _particles.add(_MapParticle(
        xRatio: x,
        yRatio: y,
        speed: speed,
        scale: scale,
        driftAmplitude: driftAmp,
        driftFrequency: driftFreq,
        phaseOffset: phase,
        color: color,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine gradient based on themeId
    RadialGradient backgroundGradient;
    Color? baseColor;

    switch (widget.themeId) {
      case 'nebula':
        backgroundGradient = const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF2D1B69), Color(0xFF080810)],
        );
        break;
      case 'ocean':
        backgroundGradient = const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF0A1A3E), Color(0xFF080810)],
        );
        break;
      case 'forest':
        backgroundGradient = const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF0A2010), Color(0xFF080810)],
        );
        break;
      case 'midnight':
      default:
        baseColor = const Color(0xFF050508);
        backgroundGradient = const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
        );
        break;
    }

    final activeTheme = ref.watch(themeProvider);

    return RepaintBoundary(
      child: Container(
        color: baseColor,
        decoration: baseColor == null ? BoxDecoration(gradient: backgroundGradient) : null,
        child: Stack(
          children: [
            // Animated overlay layer
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (widget.themeId == 'midnight') {
                  return CustomPaint(
                    painter: _MidnightGridPainter(animationValue: _controller.value),
                    size: Size.infinite,
                  );
                } else {
                  // Override nebula particle colors using user's custom theme to feel premium
                  List<_MapParticle> particlesToPaint = _particles;
                  if (widget.themeId == 'nebula') {
                    particlesToPaint = _particles.map((p) {
                      return p.copyWith(
                        color: p.color.toARGB32() == const Color(0xFF7B6EF6).toARGB32()
                            ? activeTheme.primary
                            : activeTheme.secondary,
                      );
                    }).toList();
                  }

                  return CustomPaint(
                    painter: _ParticlePainter(
                      particles: particlesToPaint,
                      animationValue: _controller.value,
                      themeId: widget.themeId,
                    ),
                    size: Size.infinite,
                  );
                }
              },
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

// ─── Particle Data Structure ────────────────────────────────────
class _MapParticle {
  final double xRatio;
  final double yRatio;
  final double speed;
  final double scale;
  final double driftAmplitude;
  final double driftFrequency;
  final double phaseOffset;
  final Color color;

  const _MapParticle({
    required this.xRatio,
    required this.yRatio,
    required this.speed,
    required this.scale,
    required this.driftAmplitude,
    required this.driftFrequency,
    required this.phaseOffset,
    required this.color,
  });

  _MapParticle copyWith({Color? color}) {
    return _MapParticle(
      xRatio: xRatio,
      yRatio: yRatio,
      speed: speed,
      scale: scale,
      driftAmplitude: driftAmplitude,
      driftFrequency: driftFrequency,
      phaseOffset: phaseOffset,
      color: color ?? this.color,
    );
  }
}

// ─── Particle Painter ───────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_MapParticle> particles;
  final double animationValue;
  final String themeId;

  const _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.themeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Compute Y movement (drifts upward, loops using modulus)
      double y = (p.yRatio - (animationValue * p.speed)) % 1.0;
      if (y < 0) y += 1.0;

      // Compute X movement (sine/cosine wave drift)
      double x;
      if (themeId == 'forest') {
        // Horizontal swaying leaf-like motion
        x = (p.xRatio + math.cos(animationValue * p.driftFrequency * math.pi * 2 + p.phaseOffset) * p.driftAmplitude) % 1.0;
      } else if (themeId == 'ocean') {
        // Vertical bubble-like jitter
        x = (p.xRatio + math.sin(animationValue * p.driftFrequency * math.pi * 2 + p.phaseOffset) * (p.driftAmplitude * 0.3)) % 1.0;
      } else {
        // Nebula nebula space drift
        x = (p.xRatio + math.sin(animationValue * p.driftFrequency * math.pi * 2 + p.phaseOffset) * p.driftAmplitude) % 1.0;
      }
      if (x < 0) x += 1.0;

      // Pulse opacity
      double opacity;
      if (themeId == 'forest') {
        // Fast flicker like fireflies
        final flicker = math.sin(animationValue * math.pi * 2 * 15 + p.phaseOffset);
        opacity = 0.15 + (flicker > 0.6 ? 0.35 : flicker < -0.6 ? 0.05 : 0.2);
      } else if (themeId == 'ocean') {
        // Smooth bubble pulse
        opacity = 0.1 + 0.25 * (0.5 + 0.5 * math.sin(animationValue * math.pi * 2 * 2 + p.phaseOffset));
      } else {
        // Space nebula pulse
        opacity = 0.08 + 0.28 * (0.5 + 0.5 * math.sin(animationValue * math.pi * 2 * 1.5 + p.phaseOffset));
      }

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Base sizes (nebula/forest: 2-6px, ocean: 3-8px)
      final double baseRadius = themeId == 'ocean' ? 3.5 : 2.5;
      final double radius = baseRadius * p.scale;

      final position = Offset(x * size.width, y * size.height);
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ─── Midnight Grid Painter ──────────────────────────────────────
class _MidnightGridPainter extends CustomPainter {
  final double animationValue;

  const _MidnightGridPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Save state, translate to center and rotate, translate back
    canvas.save();
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.03) // faint theme purple color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Use screen diagonal to cover corners during rotation
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    const spacing = 45.0;

    final startX = center.dx - diagonal / 2;
    final endX = center.dx + diagonal / 2;
    final startY = center.dy - diagonal / 2;
    final endY = center.dy + diagonal / 2;

    // Draw vertical lines
    for (double x = startX; x <= endX; x += spacing) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
    }

    // Draw horizontal lines
    for (double y = startY; y <= endY; y += spacing) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MidnightGridPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
