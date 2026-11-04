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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [
                      Color(0xFF080F20),
                      Color(0xFF101C32),
                      Color(0xFF14243F),
                      Color(0xFF172B49),
                    ]
                  : const [
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
              painter: _CharmingAuraPainter(
                progress: t,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
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

  _CharmingAuraPainter({required this.progress, required this.isDark});

  // Precomputed sparkle seeds for deterministic beauty
  final bool isDark;
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
    _drawTileGrid(canvas, size, progress, isDark);

    // Orb 1: Center-Top Electric Azure Halo (behind the logo/title)
    final orb1Center = Offset(
      w * 0.84 + 18 * (progress - 0.5),
      h * 0.84 + 14 * (0.5 - progress),
    );
    _drawGlow(
      canvas,
      center: orb1Center,
      radius: w * 0.40,
      colors: [
        (isDark ? const Color(0xFF0664F2) : const Color(0xFF66BFFF)).withValues(
          alpha: isDark ? 0.16 : 0.12,
        ),
        (isDark ? const Color(0xFF00B4D8) : const Color(0xFFBFE8FF)).withValues(
          alpha: isDark ? 0.06 : 0.045,
        ),
        const Color(0x00000000),
      ],
      blur: 115,
    );

    // Orb 2: Top-Left Cyan & Sky Bloom
    final orb2Center = Offset(
      w * 0.48 + 14 * (0.5 - progress),
      h * 0.42 + 12 * (progress - 0.5),
    );
    _drawGlow(
      canvas,
      center: orb2Center,
      radius: w * 0.24,
      colors: [
        (isDark ? const Color(0xFF3B82F6) : const Color(0xFFB8E5FF)).withValues(
          alpha: isDark ? 0.06 : 0.035,
        ),
        const Color(0x00000000),
      ],
      blur: 110,
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
        (isDark ? const Color(0xFF3B82F6) : const Color(0xFF8FD4FF)).withValues(
          alpha: isDark ? 0.08 : 0.055,
        ),
        (isDark ? const Color(0xFF00B4D8) : const Color(0xFFBFE8FF)).withValues(
          alpha: isDark ? 0.035 : 0.02,
        ),
        const Color(0x00000000),
      ],
      blur: 125,
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
        const Color(0xFF0664F2).withValues(alpha: isDark ? 0.045 : 0.025),
        const Color(0xFFBAE6FD).withValues(alpha: isDark ? 0.02 : 0.012),
        const Color(0x00000000),
      ],
      blur: 105,
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

  void _drawTileGrid(Canvas canvas, Size size, double progress, bool isDark) {
    final tileSize = size.width < 700 ? 66.0 : 82.0;
    const gap = 8.0;
    final stride = tileSize + gap;
    final glowCenter = Offset(
      size.width * (0.78 + progress * 0.12),
      size.height * (0.78 + progress * 0.08),
    );

    for (var row = -1; row * stride < size.height + tileSize; row++) {
      final offset = row.isEven ? 0.0 : stride * 0.5;
      for (var column = -1; column * stride < size.width + tileSize; column++) {
        final left = column * stride + offset;
        final top = row * stride;
        final tileCenter = Offset(left + tileSize / 2, top + tileSize / 2);
        final distance = (tileCenter - glowCenter).distance;
        final intensity = (1 - distance / (size.width * 0.42)).clamp(0.0, 1.0);
        final lowerGlow = ((tileCenter.dy / size.height) * 0.72).clamp(
          0.0,
          1.0,
        );
        final rect = Rect.fromLTWH(left, top, tileSize, tileSize);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

        canvas.drawRRect(
          rrect.shift(const Offset(2, 4)),
          Paint()
            ..color =
                (isDark ? const Color(0xFF000814) : const Color(0xFF2C6FA8))
                    .withValues(
                      alpha: isDark
                          ? 0.025 + lowerGlow * 0.025 + intensity * 0.025
                          : 0.012 + lowerGlow * 0.018 + intensity * 0.014,
                    )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(
                        0xFF29466C,
                      ).withValues(alpha: 0.40 + intensity * 0.08),
                      const Color(0xFF172B49).withValues(alpha: 0.58),
                      const Color(0xFF0D1D35).withValues(
                        alpha: 0.48 + lowerGlow * 0.10 + intensity * 0.08,
                      ),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.27 + intensity * 0.07),
                      const Color(0xFFEAF7FF).withValues(alpha: 0.20),
                      const Color(0xFF66C2FF).withValues(
                        alpha: 0.015 + lowerGlow * 0.055 + intensity * 0.045,
                      ),
                    ],
            ).createShader(rect),
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = (isDark ? const Color(0xFF7DD3FC) : Colors.white)
                .withValues(
                  alpha: isDark
                      ? 0.10 + intensity * 0.10
                      : 0.14 + intensity * 0.10,
                ),
        );
      }
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
