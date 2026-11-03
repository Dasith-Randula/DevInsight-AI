import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Reusable decorative Ink Bloom background; place it behind page content.
enum AuraBackgroundVariant { splash, landing, internal, auth }

class AnimatedAuraBackground extends StatefulWidget {
  const AnimatedAuraBackground({
    super.key,
    this.variant = AuraBackgroundVariant.landing,
  });

  final AuraBackgroundVariant variant;

  @override
  State<AnimatedAuraBackground> createState() => _AnimatedAuraBackgroundState();
}

class _AnimatedAuraBackgroundState extends State<AnimatedAuraBackground>
    with TickerProviderStateMixin {
  late final AnimationController _blueController;
  late final AnimationController _violetController;

  double get _intensity => switch (widget.variant) {
    AuraBackgroundVariant.splash => 1,
    AuraBackgroundVariant.landing => 0.82,
    AuraBackgroundVariant.internal => 0.52,
    AuraBackgroundVariant.auth => 0.28,
  };

  @override
  void initState() {
    super.initState();
    _blueController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _violetController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blueController.dispose();
    _violetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.sizeOf(context);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenSize.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenSize.height;
        final isMobile = width < 600;
        final isDesktop = width >= 1100;

        final firstWidth = (width * 0.96).clamp(320.0, 1800.0).toDouble();
        final firstHeight = (height * 1.16).clamp(320.0, 1500.0).toDouble();
        final secondWidth = (width * 0.84).clamp(300.0, 1500.0).toDouble();
        final secondHeight = (height * 1.0).clamp(300.0, 1200.0).toDouble();
        final thirdWidth = (width * 0.48).clamp(220.0, 900.0).toDouble();
        final thirdHeight = (height * 0.8).clamp(240.0, 1000.0).toDouble();

        final blurScale = isDesktop
            ? 1.0
            : isMobile
            ? 80 / 115
            : 0.88;
        final authVariant = widget.variant == AuraBackgroundVariant.auth;

        return IgnorePointer(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (authVariant)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF5F9FF),
                            Color(0xFFEAF6FF),
                            Color(0xFFF9FBFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                _positionedGlow(
                  controller: _blueController,
                  left: width * 0.30 - firstWidth / 2,
                  top: height * 0.42 - firstHeight / 2,
                  width: firstWidth,
                  height: firstHeight,
                  colors: authVariant
                      ? const [Color(0xFF0664F2), Color(0xFF7DD3FC)]
                      : const [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  alphas: authVariant
                      ? [0.28, 0.12]
                      : [0.70 * _intensity, 0.16 * _intensity],
                  stops: const [0, 0.50, 0.74],
                  blurSigma: (isDesktop ? 115 : 80) * blurScale,
                  beginOffset: const Offset(-20, 10),
                  endOffset: const Offset(30, -20),
                  endScale: 1.04,
                ),
                _positionedGlow(
                  controller: _violetController,
                  left: width * 0.65 - secondWidth / 2,
                  top: height * 0.55 - secondHeight / 2,
                  width: secondWidth,
                  height: secondHeight,
                  colors: authVariant
                      ? const [Color(0xFF14A8EF), Color(0xFF7DD3FC)]
                      : const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  alphas: authVariant
                      ? [0.24, 0.10]
                      : [0.68 * _intensity, 0.14 * _intensity],
                  stops: const [0, 0.48, 0.72],
                  blurSigma: (isDesktop ? 144 : 100) * blurScale,
                  beginOffset: const Offset(20, -10),
                  endOffset: const Offset(-25, 20),
                  endScale: 1.04,
                ),
                _positionedGlow(
                  controller: _blueController,
                  left: width * 0.50 - thirdWidth / 2,
                  top: height * 0.30 - thirdHeight / 2,
                  width: thirdWidth,
                  height: thirdHeight,
                  colors: authVariant
                      ? const [Color(0xFFFFFFFF)]
                      : const [Color(0xFF60A5FA)],
                  alphas: authVariant ? [0.22] : [0.38 * _intensity],
                  stops: const [0, 0.68],
                  blurSigma: (isDesktop ? 101 : 70) * blurScale,
                  beginOffset: const Offset(10, -6),
                  endOffset: const Offset(-12, 14),
                  endScale: 1.03,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _positionedGlow({
    required AnimationController controller,
    required double left,
    required double top,
    required double width,
    required double height,
    required List<Color> colors,
    required List<double> alphas,
    required List<double> stops,
    required double blurSigma,
    required Offset beginOffset,
    required Offset endOffset,
    required double endScale,
  }) {
    final glow = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _InkBloomGlowPainter(
          colors: colors,
          alphas: alphas,
          stops: stops,
          blurSigma: blurSigma,
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          child: glow,
          builder: (context, child) {
            final progress = Curves.easeInOutSine.transform(controller.value);
            return Transform.translate(
              offset: Offset(
                ui.lerpDouble(beginOffset.dx, endOffset.dx, progress)!,
                ui.lerpDouble(beginOffset.dy, endOffset.dy, progress)!,
              ),
              child: Transform.scale(
                scale: ui.lerpDouble(1, endScale, progress)!,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InkBloomGlowPainter extends CustomPainter {
  const _InkBloomGlowPainter({
    required this.colors,
    required this.alphas,
    required this.stops,
    required this.blurSigma,
  });

  final List<Color> colors;
  final List<double> alphas;
  final List<double> stops;
  final double blurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(
      bounds,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        )
        ..blendMode = BlendMode.multiply,
    );
    final gradientColors = [
      for (var i = 0; i < colors.length; i++)
        colors[i].withValues(alpha: alphas[i]),
      const Color(0x00000000),
    ];
    final gradientStops = [...stops.take(colors.length), stops.last];
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(
      size.width / size.shortestSide,
      size.height / size.shortestSide,
    );
    final radius = size.shortestSide / 2;
    final shader = RadialGradient(
      colors: gradientColors,
      stops: gradientStops,
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, Paint()..shader = shader);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InkBloomGlowPainter oldDelegate) =>
      oldDelegate.blurSigma != blurSigma ||
      oldDelegate.colors != colors ||
      oldDelegate.alphas != alphas ||
      oldDelegate.stops != stops;
}
