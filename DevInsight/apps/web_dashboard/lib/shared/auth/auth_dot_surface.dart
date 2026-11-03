import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AuthDotSurface extends StatefulWidget {
  const AuthDotSurface({super.key});

  @override
  State<AuthDotSurface> createState() => _AuthDotSurfaceState();
}

class _AuthDotSurfaceState extends State<AuthDotSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 96),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion == _reducedMotion && _controller.isAnimating) return;

    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else {
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
    if (_reducedMotion) {
      return const RepaintBoundary(
        child: CustomPaint(
          painter: _DotSurfacePainter(time: 0),
          child: SizedBox.expand(),
        ),
      );
    }

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final phase = _controller.value * math.pi * 2;
              final widthFactor =
                  0.68 + 0.32 * (0.5 + 0.5 * math.sin(phase * 2 + 0.4));
              final heightFactor =
                  0.68 + 0.32 * (0.5 + 0.5 * math.sin(phase * 2 + 2.1));

              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: constraints.maxWidth * widthFactor,
                  height: constraints.maxHeight * heightFactor,
                  child: CustomPaint(
                    painter: _DotSurfacePainter(time: _controller.value),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DotSurfacePainter extends CustomPainter {
  const _DotSurfacePainter({required this.time});

  final double time;

  static const int _latitudeRows = 30;
  static const int _longitudeColumns = 52;
  static const Color _cyan = Color(0xFF14A8EF);
  static const Color _blue = Color(0xFF0664F2);
  static const Color _violet = Color(0xFF9B63F6);
  static const Color _pink = Color(0xFFD66BFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final phase = time * math.pi * 2;
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.31;
    final widthScale =
        scale * (0.74 + 0.26 * (0.5 + 0.5 * math.sin(phase * 2 + 0.9)));
    final heightScale =
        scale * (0.74 + 0.26 * (0.5 + 0.5 * math.sin(phase * 3 + 1.7)));

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.secondaryBlue.withValues(alpha: 0.10),
          AppColors.primaryBlue.withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0, 0.58, 1],
      ).createShader(Rect.fromCircle(center: center, radius: scale * 1.15));
    canvas.drawCircle(center, scale * 1.15, glow);

    final rotateX =
        0.56 * math.sin(phase * 2) + 0.22 * math.sin(phase * 3 + 0.7);
    final rotateY = phase * 3 + 0.28 * math.sin(phase * 2 + 0.6);
    final rotateZ =
        0.34 * math.sin(phase * 3 + 0.8) + 0.2 * math.sin(phase * 2);
    final cosX = math.cos(rotateX);
    final sinX = math.sin(rotateX);
    final cosY = math.cos(rotateY);
    final sinY = math.sin(rotateY);
    final cosZ = math.cos(rotateZ);
    final sinZ = math.sin(rotateZ);

    for (var row = 0; row < _latitudeRows; row++) {
      final latitude = math.pi * ((row + 0.5) / _latitudeRows) - math.pi / 2;
      final cosLatitude = math.cos(latitude);
      final sinLatitude = math.sin(latitude);

      for (var column = 0; column < _longitudeColumns; column++) {
        final longitude = math.pi * 2 * column / _longitudeColumns;
        final shape =
            1 +
            0.23 *
                math.sin(longitude * 3 + phase * 2) *
                math.cos(latitude * 2 - phase * 3) +
            0.15 * math.cos(longitude * 5 - latitude * 2 + phase * 4) +
            0.09 * math.sin(latitude * 4 + phase * 2) +
            0.06 * math.cos(longitude * 2 + latitude * 3 - phase * 5);

        final x = shape * cosLatitude * math.cos(longitude);
        final y = shape * sinLatitude;
        final z = shape * cosLatitude * math.sin(longitude);

        final xY = x * cosY + z * sinY;
        final zY = -x * sinY + z * cosY;
        final yX = y * cosX - zY * sinX;
        final zX = y * sinX + zY * cosX;
        final xZ = xY * cosZ - yX * sinZ;
        final yZ = xY * sinZ + yX * cosZ;

        if (zX < -0.22) continue;

        final perspective = 5 / (5 - zX);
        final point = Offset(
          center.dx + xZ * widthScale * perspective,
          center.dy - yZ * heightScale * perspective,
        );
        final depth = ((zX + 1.3) / 2.6).clamp(0.0, 1.0);
        final colorWave =
            0.5 +
            0.5 *
                math.sin(
                  longitude * 1.5 +
                      latitude * 2.1 +
                      phase * 2 +
                      math.sin(phase * 2 + longitude * 2) * 0.42,
                );
        final color = colorWave < 0.34
            ? Color.lerp(_cyan, _blue, colorWave / 0.34)!
            : colorWave < 0.68
            ? Color.lerp(_blue, _violet, (colorWave - 0.34) / 0.34)!
            : Color.lerp(_violet, _pink, (colorWave - 0.68) / 0.32)!;
        final dotRadius = 1.0 + depth * 0.9;
        final alpha = 0.64 + depth * 0.34;

        if (depth > 0.25) {
          canvas.drawCircle(
            point,
            dotRadius * 2.1,
            Paint()..color = color.withValues(alpha: alpha * 0.14),
          );
        }
        canvas.drawCircle(
          point,
          dotRadius,
          Paint()..color = color.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotSurfacePainter oldDelegate) =>
      oldDelegate.time != time;
}
