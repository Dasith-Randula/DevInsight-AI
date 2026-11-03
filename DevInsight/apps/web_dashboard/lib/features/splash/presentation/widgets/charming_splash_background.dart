import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A charming, luminous white background with animated living aura orbs
/// and floating micro-sparkles (clean, without any grid or axes).
class CharmingSplashBackground extends StatefulWidget {
  final Widget child;
  final bool isAnimating;

  const CharmingSplashBackground({
    super.key,
    required this.child,
    this.isAnimating = true,
  });

  @override
  State<CharmingSplashBackground> createState() =>
      _CharmingSplashBackgroundState();
}

class _CharmingSplashBackgroundState extends State<CharmingSplashBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (widget.isAnimating) {
      _ambientController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CharmingSplashBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        if (!_ambientController.isAnimating) {
          _ambientController.repeat(reverse: true);
        }
      } else {
        _ambientController.stop();
      }
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Pristine White Foundation Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FBFF),
                Color(0xFFEEF4FB),
                Color(0xFFE8F1FA),
                Color(0xFFDCEAF8),
              ],
              stops: [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        ),

        // 2. Animated Ambient Glowing Blobs & Shimmering Sparkles
        AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            final t = Curves.easeInOutSine.transform(_ambientController.value);
            return CustomPaint(
              painter: _CharmingAuraPainter(progress: t),
              size: Size.infinite,
            );
          },
        ),

        // 3. Foreground Content
        widget.child,
      ],
    );
  }
}

class _CharmingAuraPainter extends CustomPainter {
  final double progress;

  _CharmingAuraPainter({required this.progress});

  // Precomputed sparkle seeds for deterministic beauty
  static final List<_SparkleSpec> _sparkles = [
    const _SparkleSpec(0.12, 0.22, 5.0, 0.4, 0.9),
    const _SparkleSpec(0.24, 0.15, 3.5, 0.2, 0.8),
    const _SparkleSpec(0.82, 0.18, 6.0, 0.6, 1.0),
    const _SparkleSpec(0.88, 0.32, 4.0, 0.1, 0.7),
    const _SparkleSpec(0.15, 0.68, 5.5, 0.7, 0.85),
    const _SparkleSpec(0.08, 0.48, 3.0, 0.3, 0.75),
    const _SparkleSpec(0.85, 0.72, 6.5, 0.5, 0.95),
    const _SparkleSpec(0.76, 0.86, 4.0, 0.8, 0.7),
    const _SparkleSpec(0.35, 0.82, 4.5, 0.2, 0.8),
    const _SparkleSpec(0.68, 0.12, 3.5, 0.9, 0.65),
    const _SparkleSpec(0.48, 0.14, 5.0, 0.45, 0.9),
    const _SparkleSpec(0.92, 0.52, 4.2, 0.35, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Orb 1: Center-Top Electric Azure Halo (behind the logo/title)
    final orb1Center = Offset(
      w * 0.50 + 20 * (progress - 0.5),
      h * 0.38 + 16 * (0.5 - progress),
    );
    _drawGlow(
      canvas,
      center: orb1Center,
      radius: w * 0.28,
      colors: [
        const Color(0xFF3B82F6).withValues(alpha: 0.22),
        const Color(0xFF60A5FA).withValues(alpha: 0.10),
        const Color(0x00000000),
      ],
      blur: 95,
    );

    // Orb 2: Top-Left Cyan & Sky Bloom
    final orb2Center = Offset(
      w * 0.16 + 28 * (0.5 - progress),
      h * 0.22 + 20 * (progress - 0.5),
    );
    _drawGlow(
      canvas,
      center: orb2Center,
      radius: w * 0.26,
      colors: [
        const Color(0xFF38BDF8).withValues(alpha: 0.20),
        const Color(0xFF93C5FD).withValues(alpha: 0.08),
        const Color(0x00000000),
      ],
      blur: 90,
    );

    // Orb 3: Bottom-Right Soft Indigo Halo
    final orb3Center = Offset(
      w * 0.82 + 32 * (progress - 0.5),
      h * 0.68 + 24 * (0.5 - progress),
    );
    _drawGlow(
      canvas,
      center: orb3Center,
      radius: w * 0.32,
      colors: [
        const Color(0xFF818CF8).withValues(alpha: 0.18),
        const Color(0xFFC7D2FE).withValues(alpha: 0.08),
        const Color(0x00000000),
      ],
      blur: 105,
    );

    // Orb 4: Bottom-Left Azure Shimmer
    final orb4Center = Offset(
      w * 0.26 + 18 * (progress - 0.5),
      h * 0.82 + 15 * (progress - 0.5),
    );
    _drawGlow(
      canvas,
      center: orb4Center,
      radius: w * 0.22,
      colors: [
        const Color(0xFF0664F2).withValues(alpha: 0.14),
        const Color(0xFFBAE6FD).withValues(alpha: 0.06),
        const Color(0x00000000),
      ],
      blur: 85,
    );

    // Draw charming floating star sparkles
    for (final s in _sparkles) {
      final sparkleY = (s.relY - (progress * 0.04)) % 1.0;
      final center = Offset(s.relX * w, sparkleY * h);

      // Twinkle calculation
      final twinkle =
          0.5 +
          0.5 * math.sin((progress * 2 * math.pi) + (s.phase * 2 * math.pi));
      final alpha = (s.maxAlpha * (0.3 + 0.7 * twinkle)).clamp(0.0, 1.0);

      final p = Paint()
        ..color = const Color(0xFF0664F2).withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.fill;

      _drawStar(canvas, center, s.size * (0.8 + 0.4 * twinkle), p);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, paint);

    // Soft center glimmer dot
    final centerDotPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: paint.color.a)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.28, centerDotPaint);
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<Color> colors,
    required double blur,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CharmingAuraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SparkleSpec {
  final double relX;
  final double relY;
  final double size;
  final double phase;
  final double maxAlpha;

  const _SparkleSpec(
    this.relX,
    this.relY,
    this.size,
    this.phase,
    this.maxAlpha,
  );
}
