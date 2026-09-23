import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Animated line-graph shown inside the landing-page dashboard preview.
///
/// Uses [CustomPainter] driven by two [AnimationController]s:
///   - [_lineController]  draws the line left→right over 1600 ms
///   - [_pulseController] animates the highlight-point halo after the line is done
class AnimatedProjectGraph extends StatefulWidget {
  const AnimatedProjectGraph({super.key});

  @override
  State<AnimatedProjectGraph> createState() => _AnimatedProjectGraphState();
}

class _AnimatedProjectGraphState extends State<AnimatedProjectGraph>
    with TickerProviderStateMixin {
  // --- controllers -----------------------------------------------------------
  late final AnimationController _lineController;
  late final AnimationController _pulseController;

  late final Animation<double> _lineAnimation;
  late final Animation<double> _pulseAnimation;

  // --- demo data  (NOT real research data) ------------------------------------
  static const List<double> _values = <double>[
    0.16,
    0.29,
    0.25,
    0.38,
    0.31,
    0.52,
    0.69,
    0.65,
    0.83,
    0.68,
    0.89,
  ];

  @override
  void initState() {
    super.initState();

    // Line-draw animation (left → right, 1600 ms)
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _lineAnimation = CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeOutCubic,
    );

    // Halo-pulse animation (repeating, 1800 ms), starts when line finishes
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _lineController.forward().then((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _lineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds on every animation tick → CustomPainter repaints.
    return AnimatedBuilder(
      animation: Listenable.merge([_lineAnimation, _pulseAnimation]),
      builder: (context, _) {
        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ProjectGraphPainter(
              values: _values,
              progress: _lineAnimation.value,
              pulse: _pulseAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _ProjectGraphPainter extends CustomPainter {
  const _ProjectGraphPainter({
    required this.values,
    required this.progress,
    required this.pulse,
  });

  final List<double> values;
  final double progress;   // 0.0 → 1.0 (line draw)
  final double pulse;      // 1.0 → 1.15 (halo scale)

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const padding = EdgeInsets.only(left: 8, top: 10, right: 8, bottom: 8);
    final chart = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // --- grid ---------------------------------------------------------------
    final gridPaint = Paint()
      ..color = const Color(0xFFE9F0FB)
      ..strokeWidth = 1;
    for (var row = 0; row <= 4; row++) {
      final y = chart.top + chart.height * row / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    // --- build full path ----------------------------------------------------
    final fullPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = chart.left + chart.width * i / (values.length - 1);
      final y = chart.bottom - chart.height * values[i];
      if (i == 0) {
        fullPath.moveTo(x, y);
      } else {
        final px = chart.left + chart.width * (i - 1) / (values.length - 1);
        final py = chart.bottom - chart.height * values[i - 1];
        final mx = (px + x) / 2;
        fullPath.cubicTo(mx, py, mx, y, x, y);
      }
    }

    // --- area fill (drawn from full path, opacity indicates progress) --------
    if (progress > 0) {
      final areaPath = Path.from(fullPath)
        ..lineTo(chart.right, chart.bottom)
        ..lineTo(chart.left, chart.bottom)
        ..close();
      canvas.drawPath(
        areaPath,
        Paint()
          ..color = AppColors.primaryBlue.withValues(alpha: 0.06 * progress)
          ..style = PaintingStyle.fill,
      );
    }

    // --- trimmed line (left → right) ----------------------------------------
    if (progress > 0) {
      final trimmed = _pathUntil(fullPath, progress);
      canvas.drawPath(
        trimmed,
        Paint()
          ..color = AppColors.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // --- highlight point & guide (only after line has started) --------------
    if (progress >= 0.05) {
      // Fixed highlight at ~70% of the x-axis (index 7 of 10)
      const highlightIndexFraction = 0.7;
      final highlightIndex =
          (highlightIndexFraction * (values.length - 1)).round();
      final highlightX =
          chart.left + chart.width * highlightIndex / (values.length - 1);
      final highlightY =
          chart.bottom - chart.height * values[highlightIndex];

      // Fade the guide in as the line progresses past that point
      final guideOpacity = ((progress - highlightIndexFraction) /
              (1.0 - highlightIndexFraction))
          .clamp(0.0, 1.0);

      if (guideOpacity > 0) {
        // Dashed vertical guide
        _drawDashed(
          canvas,
          from: Offset(highlightX, chart.top),
          to: Offset(highlightX, chart.bottom),
          paint: Paint()
            ..color =
                AppColors.primaryBlue.withValues(alpha: 0.25 * guideOpacity)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
          dashLength: 4,
          gapLength: 3,
        );

        // Halo
        canvas.drawCircle(
          Offset(highlightX, highlightY),
          13.0 * pulse * guideOpacity,
          Paint()
            ..color =
                AppColors.primaryBlue.withValues(alpha: 0.18 * guideOpacity),
        );

        // Solid center dot
        canvas.drawCircle(
          Offset(highlightX, highlightY),
          5.5,
          Paint()
            ..color = AppColors.primaryBlue
                .withValues(alpha: guideOpacity),
        );
      }
    }
  }

  // Trims [source] path to [progress] fraction of its total length.
  Path _pathUntil(Path source, double progress) {
    final metrics = source.computeMetrics().toList();
    if (metrics.isEmpty) return Path();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var remaining = total * progress.clamp(0.0, 1.0);
    final result = Path();
    for (final m in metrics) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0.0, m.length);
      result.addPath(m.extractPath(0, take), Offset.zero);
      remaining -= m.length;
    }
    return result;
  }

  void _drawDashed(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    final total = (to - from).distance;
    final dir = (to - from) / total;
    var traveled = 0.0;
    var drawing = true;
    while (traveled < total) {
      final segLen = drawing ? dashLength : gapLength;
      final end = math.min(traveled + segLen, total);
      if (drawing) {
        canvas.drawLine(
          from + dir * traveled,
          from + dir * end,
          paint,
        );
      }
      traveled = end;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectGraphPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}
