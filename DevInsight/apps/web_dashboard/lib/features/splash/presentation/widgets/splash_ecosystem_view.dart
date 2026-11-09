import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';

class SplashEcosystemView extends StatelessWidget {
  const SplashEcosystemView({
    super.key,
    required this.animation,
    required this.reducedMotion,
  });

  final Animation<double> animation;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion) {
      return Center(
        child: Semantics(
          image: true,
          label: 'DevInsight',
          child: Image.asset(
            AppAssets.devInsightLogo,
            width: 88,
            height: 88,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = math
            .min(
              math.min(constraints.maxWidth - 32, constraints.maxHeight - 32),
              560.0,
            )
            .clamp(0.0, 560.0)
            .toDouble();
        final compact = constraints.maxWidth < 600;
        final logoSize = (extent * (compact ? 0.105 : 0.12)).clamp(36.0, 58.0);
        final titleSize = (extent * (compact ? 0.078 : 0.082)).clamp(
          24.0,
          40.0,
        );

        return Center(
          child: Semantics(
            image: true,
            label: 'DevInsight software engineering ecosystem animation',
            child: SizedBox(
              key: const ValueKey('splash-orbit-scene'),
              width: extent,
              height: extent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _SplashOrbitPainter(animation: animation),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: animation,
                    child: _CentralLogoDisc(size: extent * 0.31),
                    builder: (context, child) {
                      final collapse = _interval(
                        animation.value,
                        0.44,
                        0.62,
                        Curves.easeInOutCubic,
                      );
                      final entrance = _interval(
                        animation.value,
                        0,
                        0.08,
                        Curves.easeOutCubic,
                      );
                      final floatOffset =
                          math.sin(animation.value * math.pi * 2) *
                          2 *
                          (1 - collapse);
                      return IgnorePointer(
                        child: Opacity(
                          opacity: entrance * (1 - collapse),
                          child: Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: Transform.scale(
                              scale:
                                  (0.72 + entrance * 0.28) *
                                  (1 - collapse * 0.48),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  _BrandLockupTransition(
                    animation: animation,
                    logoSize: logoSize,
                    titleSize: titleSize,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CentralLogoDisc extends StatelessWidget {
  const _CentralLogoDisc({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.27),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF9FCFF)],
        ),
        border: Border.all(color: const Color(0xFFDCEBFF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160B4C9C),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
          BoxShadow(color: Color(0x66FFFFFF), blurRadius: 1, spreadRadius: 1),
        ],
      ),
      child: Image.asset(
        AppAssets.devInsightLogo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _BrandLockupTransition extends StatelessWidget {
  const _BrandLockupTransition({
    required this.animation,
    required this.logoSize,
    required this.titleSize,
  });

  final Animation<double> animation;
  final double logoSize;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AppAssets.devInsightLogo,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
    final wordmark = _BrandWordmark(titleSize: titleSize);
    return AnimatedBuilder(
      animation: animation,
      child: logo,
      builder: (context, child) {
        final phase = animation.value;
        final logoReveal = _interval(phase, 0.52, 0.70, Curves.easeOutCubic);
        final wordReveal = _interval(phase, 0.58, 0.76, Curves.easeInOutCubic);
        final wordRetraction = _interval(phase, 0.84, 1, Curves.easeInOutCubic);
        final wordmarkProgress = wordReveal * (1 - wordRetraction);
        final logoScale = _finalLogoScale(
          _interval(phase, 1, 1.14, Curves.easeInOutCubic),
        );
        final finalLogoSize = logoSize * logoScale;
        return IgnorePointer(
          child: Opacity(
            opacity: logoReveal,
            child: Transform.scale(
              scale: 0.86 + 0.14 * logoReveal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    key: const ValueKey('splash-final-logo'),
                    width: finalLogoSize,
                    height: finalLogoSize,
                    child: child,
                  ),
                  if (wordmarkProgress > 0.001)
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: wordmarkProgress,
                        child: Opacity(
                          opacity: wordmarkProgress,
                          child: Padding(
                            padding: EdgeInsets.only(left: logoSize * 0.16),
                            child: wordmark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _finalLogoScale(double progress) {
    const settleStart = 0.84;
    if (progress <= settleStart) {
      final expansion = Curves.easeOutCubic.transform(progress / settleStart);
      return 1 + 0.75 * expansion;
    }
    final settle = Curves.easeOut.transform(
      (progress - settleStart) / (1 - settleStart),
    );
    return 1.75 - 0.05 * settle;
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({required this.titleSize});

  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.plusJakartaSans(
      fontSize: titleSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1,
    );
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Dev',
            style: titleStyle.copyWith(color: const Color(0xFF14243D)),
          ),
          TextSpan(
            text: 'Insight',
            style: titleStyle.copyWith(color: const Color(0xFF0056FF)),
          ),
        ],
      ),
    );
  }
}

class _SplashOrbitPainter extends CustomPainter {
  _SplashOrbitPainter({required this.animation})
    : _glyphs = _toolIcons
          .map(
            (tool) => TextPainter(
              text: TextSpan(
                text: String.fromCharCode(tool.icon.codePoint),
                style: TextStyle(
                  color: tool.color,
                  fontFamily: tool.icon.fontFamily ?? 'MaterialIcons',
                  package: tool.icon.fontPackage,
                  fontSize: 20,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout(),
          )
          .toList(growable: false),
      super(repaint: animation);

  final Animation<double> animation;
  final List<TextPainter> _glyphs;

  static const _toolIcons = [
    (icon: Icons.code_rounded, color: Color(0xFF0056FF)),
    (icon: Icons.device_hub_rounded, color: Color(0xFF2277FF)),
    (icon: Icons.bug_report_outlined, color: Color(0xFF315A91)),
    (icon: Icons.analytics_rounded, color: Color(0xFF1686D9)),
    (icon: Icons.merge_type_rounded, color: Color(0xFF1769E8)),
    (icon: Icons.smart_toy_outlined, color: Color(0xFF3389EC)),
    (icon: Icons.source_outlined, color: Color(0xFF1F5FC4)),
    (icon: Icons.fact_check_outlined, color: Color(0xFF2C78CF)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value;
    final shortestSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final entrance = _interval(phase, 0, 0.08, Curves.easeOutCubic);
    final collapse = _interval(phase, 0.44, 0.62, Curves.easeInOutCubic);
    final visibility = entrance * (1 - collapse);
    if (visibility <= 0) return;

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF8BBFFF).withValues(alpha: 0.14 * visibility),
              const Color(0xFFDCEBFF).withValues(alpha: 0.06 * visibility),
              Colors.transparent,
            ],
            stops: const [0, 0.58, 1],
          ).createShader(
            Rect.fromCircle(center: center, radius: shortestSide * 0.48),
          );
    canvas.drawCircle(center, shortestSide * 0.48, glowPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..isAntiAlias = true;
    final ringScale = 1 - collapse * 0.94;
    const ringOpacities = [0.46, 0.32, 0.22];
    const ringFractions = [0.25, 0.39, 0.47];
    for (var index = 0; index < ringFractions.length; index++) {
      final radius = shortestSide * ringFractions[index] * ringScale;
      ringPaint.color = const Color(
        0xFF7FADE0,
      ).withValues(alpha: visibility * ringOpacities[index]);
      canvas.drawCircle(center, radius, ringPaint);
    }

    final tileSize = (shortestSide * 0.115).clamp(32.0, 46.0);
    final tileRadius = tileSize * 0.26;
    final rotation = phase <= 0.44
        ? 0.56 * Curves.easeInOutSine.transform(phase / 0.44)
        : 0.56 *
              (1 -
                  Curves.easeOutCubic.transform(
                    ((phase - 0.44) / 0.18).clamp(0.0, 1.0),
                  ));
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: visibility),
    );
    for (var index = 0; index < _toolIcons.length; index++) {
      final inner = index < 4;
      final localIndex = index % 4;
      final baseAngle = (inner ? 0.0 : math.pi / 4) + localIndex * math.pi / 2;
      final angle = baseAngle + rotation * (inner ? -0.75 : 1);
      final orbitRadius = shortestSide * (inner ? 0.255 : 0.385);
      final distance = orbitRadius * (1 - collapse);
      final tileCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      _paintToolTile(
        canvas,
        center: tileCenter,
        size: tileSize,
        radius: tileRadius,
        glyph: _glyphs[index],
      );
    }
    canvas.restore();
  }

  void _paintToolTile(
    Canvas canvas, {
    required Offset center,
    required double size,
    required double radius,
    required TextPainter glyph,
  }) {
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    final card = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final shadow = card.shift(const Offset(0, 2));
    canvas.drawRRect(shadow, Paint()..color = const Color(0x147F9EBF));
    canvas.drawRRect(card, Paint()..color = Colors.white);
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFD8E8FB),
    );
    glyph.paint(
      canvas,
      Offset(center.dx - glyph.width / 2, center.dy - glyph.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashOrbitPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

double _interval(double value, double start, double end, Curve curve) {
  if (value <= start) return 0;
  if (value >= end) return 1;
  return curve.transform((value - start) / (end - start));
}
