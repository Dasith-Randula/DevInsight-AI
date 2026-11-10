import 'package:flutter/material.dart';

class DashboardScrollIndicator extends StatefulWidget {
  const DashboardScrollIndicator({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<DashboardScrollIndicator> createState() =>
      _DashboardScrollIndicatorState();
}

class _DashboardScrollIndicatorState extends State<DashboardScrollIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wheelMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool? _motionDisabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled == motionDisabled) return;
    _motionDisabled = motionDisabled;
    if (motionDisabled) {
      _wheelMotion
        ..stop()
        ..value = 0;
    } else {
      _wheelMotion.repeat();
    }
  }

  @override
  void dispose() {
    _wheelMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Scroll to dashboard content',
        child: Tooltip(
          message: 'Scroll to dashboard content',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('scroll-down-button'),
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(28, 44),
                      painter: _DashboardScrollMousePainter(
                        animation: _wheelMotion,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardScrollMousePainter extends CustomPainter {
  const _DashboardScrollMousePainter({required this.animation})
    : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final mouse = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 2, size.width - 6, size.height - 4),
      const Radius.circular(11),
    );
    final glowPaint = Paint()
      ..color = const Color(0xFF1769E8).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final outlinePaint = Paint()
      ..color = const Color(0xFF1769E8).withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..isAntiAlias = true;
    canvas
      ..drawRRect(mouse, glowPaint)
      ..drawRRect(mouse, outlinePaint);

    final progress = animation.value;
    final wheelTop = 9 + progress * 10;
    final wheelOpacity = (1 - progress).clamp(0.0, 1.0);
    final wheel = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 1.2, wheelTop, 2.4, 5),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      wheel,
      Paint()
        ..color = const Color(0xFF1769E8).withValues(alpha: wheelOpacity)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _DashboardScrollMousePainter oldDelegate) =>
      oldDelegate.animation != animation;
}
