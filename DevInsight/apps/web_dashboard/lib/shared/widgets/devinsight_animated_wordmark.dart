import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';

class DevInsightAnimatedWordmark extends StatelessWidget {
  const DevInsightAnimatedWordmark({
    super.key,
    required this.animation,
    required this.topPadding,
  });

  final Animation<double> animation;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = (constraints.maxWidth * 0.168).clamp(67.2, 140.8);
        final baseStyle = GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 3.52,
        );
        final insightStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
        final outlineWidth = ((fontSize / 1.6) / 26).clamp(2.0, 3.2) * 0.62;
        return Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  key: const ValueKey('devinsight-wordmark'),
                  fit: BoxFit.scaleDown,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final phase = animation.value;
                      const fillEnd = 0.60;
                      const holdEnd = 0.68;
                      const drainEnd = 0.96;
                      final fillDuration = fillEnd / 'INSIGHT'.length;
                      final drainDuration =
                          (drainEnd - holdEnd) / 'INSIGHT'.length;
                      return Semantics(
                        label: 'DevInsight',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'DEV',
                              style: baseStyle.copyWith(
                                color: isDark
                                    ? colors.primaryText
                                    : const Color(0xFF111C31),
                                letterSpacing: fontSize * 0.05,
                              ),
                            ),
                            SizedBox(width: fontSize * 0.05),
                            for (
                              var index = 0;
                              index < 'INSIGHT'.length;
                              index++
                            )
                              _WaterFillLetter(
                                letter: 'INSIGHT'[index],
                                style: insightStyle,
                                outlineWidth: outlineWidth,
                                progress: letterFillProgress(
                                  phase: phase,
                                  index: index,
                                  fillDuration: fillDuration,
                                  fillEnd: fillEnd,
                                  holdEnd: holdEnd,
                                  drainEnd: drainEnd,
                                  drainDuration: drainDuration,
                                ),
                                wavePhase: phase * math.pi * 2 + index * 0.9,
                                rightPadding: index == 'INSIGHT'.length - 1
                                    ? 0
                                    : fontSize * 0.025,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Powered Software Engineering Intelligence',
                  textAlign: TextAlign.center,
                  style: _wordmarkTextStyle(
                    color: isDark
                        ? colors.primaryText
                        : const Color(0xFF273C61),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Smarter development. Clearer insights. Better decisions.',
                  textAlign: TextAlign.center,
                  style: _wordmarkTextStyle(
                    color: isDark
                        ? colors.secondaryText
                        : const Color(0xFF71819C),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

double letterFillProgress({
  required double phase,
  required int index,
  required double fillDuration,
  required double fillEnd,
  required double holdEnd,
  required double drainEnd,
  required double drainDuration,
}) {
  if (phase < fillEnd) {
    final local = ((phase - index * fillDuration) / fillDuration).clamp(
      0.0,
      1.0,
    );
    return Curves.easeInOutCubic.transform(local);
  }
  if (phase < holdEnd) return 1;
  if (phase < drainEnd) {
    final reverseIndex = 'INSIGHT'.length - 1 - index;
    final local =
        ((phase - holdEnd - reverseIndex * drainDuration) / drainDuration)
            .clamp(0.0, 1.0);
    return 1 - Curves.easeInOutCubic.transform(local);
  }
  return 0;
}

class _WaterFillLetter extends StatelessWidget {
  const _WaterFillLetter({
    required this.letter,
    required this.style,
    required this.outlineWidth,
    required this.progress,
    required this.wavePhase,
    required this.rightPadding,
  });

  final String letter;
  final TextStyle style;
  final double outlineWidth;
  final double progress;
  final double wavePhase;
  final double rightPadding;

  @override
  Widget build(BuildContext context) {
    final painter = _WaterFillPainter(
      letter: letter,
      style: style,
      outlineWidth: outlineWidth,
      progress: progress,
      wavePhase: wavePhase,
    );
    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: Stack(
        key: ValueKey('wordmark-letter-$letter'),
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.all(painter.padding),
            child: Text(
              letter,
              style: style.copyWith(color: Colors.transparent),
              textScaler: TextScaler.noScaling,
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: painter)),
        ],
      ),
    );
  }
}

class _WaterFillPainter extends CustomPainter {
  _WaterFillPainter({
    required this.letter,
    required this.style,
    required this.outlineWidth,
    required this.progress,
    required this.wavePhase,
  }) : _outline = _createPainter(
         letter,
         style.copyWith(
           foreground: Paint()
             ..style = PaintingStyle.stroke
             ..strokeWidth = outlineWidth
             ..strokeJoin = StrokeJoin.bevel
             ..isAntiAlias = true
             ..color = const Color(0xFF1769E8),
         ),
       ),
       _fill = _createPainter(letter, _fillStyle(letter, style, outlineWidth)),
       padding = style.fontSize! * 0.10 + outlineWidth {
    size = Size(_fill.width + padding * 2, _fill.height + padding * 2);
  }

  final String letter;
  final TextStyle style;
  final double outlineWidth;
  final double progress;
  final double wavePhase;
  final TextPainter _outline;
  final TextPainter _fill;
  final double padding;
  late final Size size;

  static TextPainter _createPainter(String letter, TextStyle style) =>
      TextPainter(
        text: TextSpan(text: letter, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();

  static TextStyle _fillStyle(
    String letter,
    TextStyle style,
    double outlineWidth,
  ) {
    final painter = _createPainter(letter, style);
    final textPadding = style.fontSize! * 0.10 + outlineWidth;
    return style.copyWith(
      foreground: Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF0756D8), Color(0xFF168DF1)],
            ).createShader(
              Rect.fromLTWH(
                textPadding,
                textPadding,
                painter.width,
                painter.height,
              ),
            ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final textOrigin = Offset(padding, padding);
    if (progress < 1) {
      _outline.paint(canvas, textOrigin);
    }
    if (progress <= 0) return;

    canvas.save();
    if (progress < 1) {
      canvas.clipPath(_waterSurface(size), doAntiAlias: true);
    }
    _fill.paint(canvas, textOrigin);
    canvas.restore();
  }

  Path _waterSurface(Size paintSize) {
    final level = paintSize.height * (1 - progress);
    final amplitude = math.min(2.8, paintSize.height * 0.025);
    final path = Path()..moveTo(0, level + math.sin(wavePhase) * amplitude);
    for (double x = 2; x < paintSize.width; x += 2) {
      final y = level + math.sin(wavePhase + x * 0.045) * amplitude;
      path.lineTo(x, y);
    }
    return path
      ..lineTo(paintSize.width, paintSize.height)
      ..lineTo(0, paintSize.height)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _WaterFillPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.wavePhase != wavePhase ||
      oldDelegate.style != style ||
      oldDelegate.outlineWidth != outlineWidth;
}

TextStyle _wordmarkTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
}) => GoogleFonts.plusJakartaSans(
  color: color,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  letterSpacing: letterSpacing,
);
