import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Count-up number animation widget
class CountUpText extends StatefulWidget {
  final int end;
  final Duration duration;
  final TextStyle style;
  final String prefix;
  final String suffix;

  const CountUpText({
    super.key,
    required this.end,
    this.duration = const Duration(milliseconds: 1000),
    required this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = (_animation.value * widget.end).round();
        return Text(
          '${widget.prefix}$val${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Scale down to 0.95 on tap down, and return on release/cancel
class BounceOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BounceOnTap({super.key, required this.child, this.onTap});

  @override
  State<BounceOnTap> createState() => _BounceOnTapState();
}

class _BounceOnTapState extends State<BounceOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.animateTo(0.95),
      onTapUp: (_) {
        _controller.animateTo(1.0);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => _controller.animateTo(1.0),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// translateY shift up by -4px on hover (primarily for web/mouse regions)
class HoverShift extends StatefulWidget {
  final Widget child;
  const HoverShift({super.key, required this.child});

  @override
  State<HoverShift> createState() => _HoverShiftState();
}

class _HoverShiftState extends State<HoverShift> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: widget.child,
      ),
    );
  }
}

/// Wobbling rotation widget (perfect for fire emojis)
class WobbleWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const WobbleWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<WobbleWidget> createState() => _WobbleWidgetState();
}

class _WobbleWidgetState extends State<WobbleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _rotation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: widget.child,
    );
  }
}

/// Slide + fade in transition for page content
class SlideFadeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const SlideFadeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
  });

  @override
  State<SlideFadeTransition> createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<SlideFadeTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
