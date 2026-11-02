import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A charming, glowing orbital loader designed for the white splash background.
class SplashLoader extends StatefulWidget {
  const SplashLoader({
    super.key,
    this.size = 76,
    this.strokeWidth = 5,
  });

  final double size;
  final double strokeWidth;

  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _rotationAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, _) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft background radial glow behind the loader
                Container(
                  width: widget.size * 0.70,
                  height: widget.size * 0.70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Rotating gradient arc
                Transform.rotate(
                  angle: _rotationAnimation.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size.square(widget.size),
                    painter: _CharmingOrbitalLoaderPainter(
                      progress: _rotationAnimation.value,
                      trackColor: AppColors.loaderTrack,
                      activeColor: AppColors.primaryBlue,
                      accentColor: const Color(0xFF38BDF8),
                      strokeWidth: widget.strokeWidth,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CharmingOrbitalLoaderPainter extends CustomPainter {
  const _CharmingOrbitalLoaderPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color activeColor;
  final Color accentColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Subtle, clean track circle
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    // 2. Glowing active sweep arc
    const double arcSweep = 2 * math.pi * 0.32;
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          activeColor.withValues(alpha: 0.1),
          activeColor,
          accentColor,
        ],
        stops: const [0.0, 0.6, 1.0],
        transform: GradientRotation(-math.pi / 2 + progress * 2 * math.pi),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2 + progress * 2 * math.pi,
      arcSweep,
      false,
      arcPaint,
    );

    // 3. Glowing orbital bead at arc tip
    final tipAngle = -math.pi / 2 + progress * 2 * math.pi + arcSweep;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final beadPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.75, beadPaint);
  }

  @override
  bool shouldRepaint(covariant _CharmingOrbitalLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
