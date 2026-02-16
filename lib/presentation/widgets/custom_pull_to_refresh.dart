import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom Pull-to-Refresh widget matching the RN implementation.
///
/// Uses raw pointer tracking for symmetric resistance in both directions.
class CustomPullToRefresh extends StatefulWidget {
  const CustomPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
    this.threshold = 60.0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsets? padding;
  final double threshold;

  @override
  State<CustomPullToRefresh> createState() => CustomPullToRefreshState();
}

class CustomPullToRefreshState extends State<CustomPullToRefresh>
    with TickerProviderStateMixin {
  double _displayOffset = 0;
  double _rawDrag = 0;
  bool _isRefreshing = false;

  final ScrollController _scrollController = ScrollController();

  // Dismiss animation (fade-out + slide-up)
  late final AnimationController _dismissController;
  double _dismissStartOffset = 0;

  // Spinner rotation
  late final AnimationController _rotationController;

  // Snap-back (released before threshold)
  late final AnimationController _snapBackController;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_clampScrollDuringPull);

    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _dismissController.addListener(_onDismissTick);
    _dismissController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismissStartOffset = 0;
        _rotationController.stop();
        _rotationController.reset();
        _dismissController.reset();
        setState(() {
          _displayOffset = 0;
          _rawDrag = 0;
          _isRefreshing = false;
        });
      }
    });

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _onDismissTick() {
    final t = Curves.easeOut.transform(_dismissController.value);
    setState(() {
      _displayOffset = _dismissStartOffset * (1 - t);
    });
  }

  void _clampScrollDuringPull() {
    if (_displayOffset > 0 && !_isRefreshing) {
      if (_scrollController.hasClients && _scrollController.offset != 0) {
        _scrollController.position.correctPixels(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_clampScrollDuringPull);
    _dismissController.removeListener(_onDismissTick);
    _dismissController.dispose();
    _rotationController.dispose();
    _snapBackController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _applyResistance(double distance) {
    if (distance <= 0) return 0;
    const resistanceFactor = 0.16;
    final resisted = widget.threshold *
        math.sqrt(distance / (widget.threshold / resistanceFactor));
    return math.min(resisted, widget.threshold);
  }

  double get _progress => (_displayOffset / widget.threshold).clamp(0.0, 1.0);

  double get _indicatorOpacity {
    if (_dismissController.isAnimating) {
      final t = Curves.easeOut.transform(_dismissController.value);
      return 1.0 - t;
    }
    return (_displayOffset / 10.0).clamp(0.0, 1.0);
  }

  void triggerRefresh() {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _displayOffset = widget.threshold;
      _rawDrag = widget.threshold;
    });
    _rotationController.repeat();
    _performRefresh();
  }

  Future<void> _performRefresh() async {
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _dismissStartOffset = _displayOffset;
        _dismissController.forward();
      }
    }
  }

  void _animateSnapBack() {
    final startOffset = _displayOffset;
    _snapBackController.reset();

    final animation = Tween<double>(begin: startOffset, end: 0).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.easeOut),
    );

    void listener() {
      setState(() {
        _displayOffset = animation.value;
      });
    }

    animation.addListener(listener);
    _snapBackController.forward().then((_) {
      animation.removeListener(listener);
      _rawDrag = 0;
    });
  }

  // --- Raw pointer tracking ---

  void _onPointerMove(PointerMoveEvent event) {
    if (_isRefreshing) return;

    final dy = event.delta.dy; // positive = finger moves down

    if (_displayOffset > 0) {
      // Already in pull mode: track finger directly (symmetric)
      setState(() {
        _rawDrag = math.max(0, _rawDrag + dy);
        _displayOffset = _applyResistance(_rawDrag);
      });
      // Scroll clamping is handled by _clampScrollDuringPull listener
      return;
    }

    // Not in pull mode yet:
    // Enter pull mode only if at the very top and dragging down
    if (dy > 0 &&
        _scrollController.hasClients &&
        _scrollController.offset <= 0) {
      setState(() {
        _rawDrag = dy;
        _displayOffset = _applyResistance(_rawDrag);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_displayOffset > 0 && !_isRefreshing) {
      _onDragRelease();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_displayOffset > 0 && !_isRefreshing) {
      _onDragRelease();
    }
  }

  void _onDragRelease() {
    if (_displayOffset >= widget.threshold) {
      setState(() => _isRefreshing = true);
      _rotationController.repeat();
      _performRefresh();
    } else if (_displayOffset > 0) {
      _animateSnapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ClipRect(
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, _displayOffset),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: widget.padding,
                child: widget.child,
              ),
            ),

            if (_displayOffset > 2)
              Positioned(
                left: 0,
                right: 0,
                top: _displayOffset - 36,
                child: Center(
                  child: Opacity(
                    opacity: _indicatorOpacity,
                    child: _CircularProgressWidget(
                      progress: _progress,
                      isRefreshing: _isRefreshing,
                      rotationController: _rotationController,
                      isDark: isDark,
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

class _CircularProgressWidget extends StatelessWidget {
  const _CircularProgressWidget({
    required this.progress,
    required this.isRefreshing,
    required this.rotationController,
    required this.isDark,
  });

  final double progress;
  final bool isRefreshing;
  final AnimationController rotationController;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    const strokeWidth = 2.5;

    return AnimatedBuilder(
      animation: rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: isRefreshing ? rotationController.value * 2 * math.pi : 0,
          child: CustomPaint(
            size: const Size(size, size),
            painter: _CircularProgressPainter(
              progress: progress,
              isRefreshing: isRefreshing,
              strokeWidth: strokeWidth,
              foregroundColor: isDark
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFF4B5563),
              backgroundColor: isDark
                  ? const Color(0xFF525252)
                  : const Color(0xFFD1D5DB),
            ),
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.isRefreshing,
    required this.strokeWidth,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final double progress;
  final bool isRefreshing;
  final double strokeWidth;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    if (isRefreshing) {
      final paint = Paint()
        ..color = foregroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      const dashCount = 8;
      const gapRatio = 0.6;
      final segmentAngle = 2 * math.pi / dashCount;
      final dashAngle = segmentAngle * (1 - gapRatio);

      for (int i = 0; i < dashCount; i++) {
        final startAngle = i * segmentAngle - math.pi / 2;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          dashAngle,
          false,
          paint,
        );
      }
    } else {
      final bgPaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, radius, bgPaint);

      if (progress > 0) {
        final fgPaint = Paint()
          ..color = foregroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          fgPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRefreshing != isRefreshing;
  }
}
