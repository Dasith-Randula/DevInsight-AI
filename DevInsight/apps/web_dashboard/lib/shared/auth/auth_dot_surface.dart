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
                  0.72 + 0.28 * (0.5 + 0.5 * math.sin(phase * 19.2 + 0.4));
              final heightFactor =
                  0.72 + 0.28 * (0.5 + 0.5 * math.sin(phase * 19.2 + 2.1));

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
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _ice = Color(0xFFEAF6FF);
  static const Color _sky = Color(0xFFA9DDFF);
  static const Color _cyan = Color(0xFF14A8EF);
  static const Color _blue = Color(0xFF0664F2);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final phase = time * math.pi * 2;
    final shapePhase = phase * 19.2;
    final rotationPhase = phase * 4.8;
    final colorPhase = phase * 8;
    final wavePhase = phase * 12;
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.31;
    final widthScale =
        scale * (0.74 + 0.26 * (0.5 + 0.5 * math.sin(shapePhase + 0.9)));
    final heightScale =
        scale * (0.74 + 0.26 * (0.5 + 0.5 * math.sin(shapePhase * 1.08 + 1.7)));
    final spacingScale = 1.01 + 0.11 * math.sin(time * math.pi * 32);

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
        0.56 * math.sin(rotationPhase * 0.7) +
        0.22 * math.sin(rotationPhase * 1.35 + 0.7);
    final rotateY = rotationPhase + 0.28 * math.sin(rotationPhase * 0.8 + 0.6);
    final rotateZ =
        0.34 * math.sin(rotationPhase * 1.2 + 0.8) +
        0.2 * math.sin(rotationPhase * 0.65);
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
                math.sin(longitude * 3 + shapePhase) *
                math.cos(latitude * 2 - shapePhase * 1.15) +
            0.15 * math.cos(longitude * 5 - latitude * 2 + shapePhase * 1.4) +
            0.09 * math.sin(latitude * 4 + shapePhase * 0.8) +
            0.06 * math.cos(longitude * 2 + latitude * 3 - shapePhase * 1.7);

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
          center.dx + xZ * widthScale * perspective * spacingScale,
          center.dy - yZ * heightScale * perspective,
        );
        final depth = ((zX + 1.3) / 2.6).clamp(0.0, 1.0);
        final colorWave =
            0.5 +
            0.5 *
                math.sin(
                  longitude * 1.5 +
                      latitude * 2.1 +
                      colorPhase +
                      math.sin(wavePhase + longitude * 2) * 0.42,
                );
        final color = colorWave < 0.25
            ? Color.lerp(_white, _ice, colorWave / 0.25)!
            : colorWave < 0.5
            ? Color.lerp(_ice, _sky, (colorWave - 0.25) / 0.25)!
            : colorWave < 0.76
            ? Color.lerp(_sky, _cyan, (colorWave - 0.5) / 0.26)!
            : Color.lerp(_cyan, _blue, (colorWave - 0.76) / 0.24)!;
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
