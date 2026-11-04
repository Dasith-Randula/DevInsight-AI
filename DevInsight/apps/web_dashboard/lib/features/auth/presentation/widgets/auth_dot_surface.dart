import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:web_dashboard/core/constants/app_colors.dart';

class AuthDotSurface extends StatefulWidget {
  const AuthDotSurface({super.key});

  @override
  State<AuthDotSurface> createState() => _AuthDotSurfaceState();
}

class _AuthDotSurfaceState extends State<AuthDotSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
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
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _AuthWavePainter(progress: _controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AuthWavePainter extends CustomPainter {
  const _AuthWavePainter({required this.progress});

  final double progress;

  static const int _columns = 51;
  static const int _rows = 15;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final phase = progress * math.pi * 2;
    final center = Offset(size.width / 2, size.height / 2);

    _paintGlow(canvas, size, center, phase);
    final points = _buildWave(size, center, phase);
    _paintWaveThreads(canvas, points);
    _paintDots(canvas, points, size);
    _paintFocusNodes(canvas, size, center, phase);
  }

  void _paintGlow(Canvas canvas, Size size, Offset center, double phase) {
    final pulse = 0.5 + 0.5 * math.sin(phase);
    final radius = size.width * (0.32 + pulse * 0.025);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.authCyan.withValues(alpha: 0.16 + pulse * 0.04),
          AppColors.authAzureBlue.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  List<_WaveDot> _buildWave(Size size, Offset center, double phase) {
    final points = <_WaveDot>[];
    for (var row = 0; row < _rows; row++) {
      final v = row / (_rows - 1) * 2 - 1;
      final depth = math.cos(v * math.pi / 2);
      for (var column = 0; column < _columns; column++) {
        final u = column / (_columns - 1) * 2 - 1;
        final travel = u * math.pi * 2.7 - phase;
        final primaryWave = math.sin(travel + v * 1.15);
        final fineWave = math.sin(travel * 1.65 + v * 2.3 + phase * 0.35);
        final fold = math.cos(travel * 0.6 - v * 2.0);
        final edgeFade = (1 - math.pow(u.abs(), 5)).toDouble();
        final x = center.dx + u * size.width * 0.47;
        final y =
            center.dy +
            v * size.height * 0.27 +
            primaryWave * size.height * 0.19 * (0.55 + depth * 0.45) +
            fineWave * size.height * 0.035 +
            fold * size.height * 0.025;
        final pulse = math.exp(-math.pow((u - _pulsePosition(phase)) * 3.2, 2));
        points.add(
          _WaveDot(
            position: Offset(x, y),
            depth: depth,
            edgeFade: edgeFade,
            highlight: pulse,
            shimmer: 0.5 + 0.5 * math.sin(travel * 0.75 + v * 2 + phase),
          ),
        );
      }
    }
    return points;
  }

  double _pulsePosition(double phase) {
    return math.sin(phase);
  }

  void _paintWaveThreads(Canvas canvas, List<_WaveDot> points) {
    for (var row = 1; row < _rows - 1; row += 2) {
      final path = Path();
      for (var column = 0; column < _columns; column++) {
        final point = points[row * _columns + column].position;
        if (column == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.075),
      );
    }
  }

  void _paintDots(Canvas canvas, List<_WaveDot> points, Size size) {
    for (final dot in points) {
      if (dot.position.dy < -4 || dot.position.dy > size.height + 4) continue;

      final brightness =
          (0.22 + dot.depth * 0.34 + dot.shimmer * 0.16 + dot.highlight * 0.3)
              .clamp(0.0, 1.0);
      final color = Color.lerp(AppColors.authCyan, Colors.white, brightness)!;
      final radius =
          1.0 + dot.depth * 0.48 + dot.shimmer * 0.15 + dot.highlight * 0.8;
      final alpha =
          (0.58 + dot.depth * 0.2 + dot.highlight * 0.22) * dot.edgeFade;

      if (dot.highlight > 0.28) {
        canvas.drawCircle(
          dot.position,
          radius * (2.6 + dot.highlight),
          Paint()..color = color.withValues(alpha: dot.highlight * 0.14),
        );
      }
      canvas.drawCircle(
        dot.position,
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  void _paintFocusNodes(Canvas canvas, Size size, Offset center, double phase) {
    for (var index = 0; index < 3; index++) {
      final u = -0.62 + index * 0.62;
      final travel = u * math.pi * 2.7 - phase;
      final y =
          center.dy +
          math.sin(travel) * size.height * 0.19 +
          math.sin(travel * 1.65 + phase * 0.35) * size.height * 0.035;
      final point = Offset(center.dx + u * size.width * 0.47, y);
      final pulse = 0.5 + 0.5 * math.sin(phase * 2 + index * 1.9);
      final color = index == 1 ? Colors.white : AppColors.authCyan;
      final radius = 2.1 + pulse * 0.6;

      canvas.drawCircle(
        point,
        radius * 3.2,
        Paint()..color = color.withValues(alpha: 0.12 + pulse * 0.06),
      );
      canvas.drawCircle(point, radius, Paint()..color = color);
      canvas.drawCircle(
        point,
        radius + 3.5 + pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75
          ..color = color.withValues(alpha: 0.22 + pulse * 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuthWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WaveDot {
  const _WaveDot({
    required this.position,
    required this.depth,
    required this.edgeFade,
    required this.highlight,
    required this.shimmer,
  });

  final Offset position;
  final double depth;
  final double edgeFade;
  final double highlight;
  final double shimmer;
}
