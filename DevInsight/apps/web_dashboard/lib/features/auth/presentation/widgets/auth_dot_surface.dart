import 'dart:math' as math;

import 'package:flutter/material.dart';

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
      duration: const Duration(seconds: 14),
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _RibbonPainter(time: _controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _RibbonDot {
  const _RibbonDot({
    required this.x,
    required this.y,
    required this.z,
    required this.wave,
    required this.u,
    required this.v,
  });

  final double x;
  final double y;
  final double z;
  final double wave;
  final double u;
  final double v;
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.time});

  final double time;

  static const int _columns = 60;
  static const int _rows = 22;
  static const Color _deepBlue = Color(0xFF03045E);
  static const Color _blue = Color(0xFF0077B6);
  static const Color _cyan = Color(0xFF00B4D8);
  static const Color _sky = Color(0xFF90E0EF);
  static const Color _ice = Color(0xFFCAF0F8);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final phase = time * math.pi * 2;
    final center = Offset(size.width / 2, size.height / 2);
    final widthScale = size.width * 0.43;
    final heightScale = size.height * 0.36;
    final spacingX = 1.02 + 0.08 * math.sin(phase * 0.9);
    final spacingY = 1.01 + 0.04 * math.sin(phase * 0.75 + 1.2);
    final breathing = 0.96 + 0.10 * (0.5 + 0.5 * math.sin(phase * 2.1));
    final tiltX = 0.16 * math.sin(phase * 0.7);
    final rotateY = 0.34 * math.sin(phase * 0.52) + phase * 0.18;
    final rotateZ = 0.08 * math.sin(phase * 0.8 + 0.7);
    final wavePhase = phase * 1.35;

    final cosX = math.cos(tiltX);
    final sinX = math.sin(tiltX);
    final cosY = math.cos(rotateY);
    final sinY = math.sin(rotateY);
    final cosZ = math.cos(rotateZ);
    final sinZ = math.sin(rotateZ);
    final dots = <_RibbonDot>[];

    for (var row = 0; row < _rows; row++) {
      final v = -1 + 2 * row / (_rows - 1);
      for (var column = 0; column < _columns; column++) {
        final u = -1 + 2 * column / (_columns - 1);
        final wave = math.sin(u * 4.2 + v * 2.8 - wavePhase);
        final fold = math.sin(u * math.pi * 1.4 + phase * 0.55);
        final edgeTaper = 0.92 + 0.08 * math.cos(v * math.pi / 2);
        final x =
            (u + 0.13 * math.sin(v * math.pi * 2 + phase * 0.42)) *
            spacingX *
            edgeTaper;
        final y =
            (v +
                0.12 * math.sin(u * math.pi * 1.8 + phase * 0.65) +
                0.08 * math.cos(v * math.pi + phase * 0.35)) *
            spacingY;
        final z =
            0.42 * math.sin(u * math.pi) * math.cos(v * math.pi * 0.8) +
            0.20 * fold +
            0.08 * wave;

        final xY = x * cosY + z * sinY;
        final zY = -x * sinY + z * cosY;
        final yX = y * cosX - zY * sinX;
        final zX = y * sinX + zY * cosX;
        final xZ = xY * cosZ - yX * sinZ;
        final yZ = xY * sinZ + yX * cosZ;

        dots.add(_RibbonDot(x: xZ, y: yZ, z: zX, wave: wave, u: u, v: v));
      }
    }

    dots.sort((a, b) => a.z.compareTo(b.z));

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _cyan.withValues(alpha: 0.13),
              _sky.withValues(alpha: 0.045),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.45),
          );
    canvas.drawCircle(center, size.width * 0.45, glow);

    for (final dot in dots) {
      if (dot.z < -0.62) continue;

      final perspective = 1.0 / (1.72 - dot.z * 0.22);
      final point = Offset(
        center.dx + dot.x * widthScale * breathing * perspective,
        center.dy - dot.y * heightScale * breathing * perspective,
      );
      final depth = ((dot.z + 0.7) / 1.35).clamp(0.0, 1.0);
      final colorWave =
          0.5 +
          0.5 *
              math.sin(
                dot.u * 3.3 + dot.v * 2.2 + phase * 0.8 + dot.wave * 0.7,
              );
      final color = _ribbonColor(colorWave, depth);
      final radius =
          (1.25 + depth * 1.45 + math.max(0, dot.wave) * 0.35) *
          (0.94 + 0.06 * breathing);
      final alpha = (0.48 + depth * 0.45 + math.max(0, dot.wave) * 0.06).clamp(
        0.0,
        1.0,
      );

      if (depth > 0.68 && dot.wave > 0.45) {
        canvas.drawCircle(
          point,
          radius * 2.4,
          Paint()..color = color.withValues(alpha: alpha * 0.12),
        );
      }
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  Color _ribbonColor(double value, double depth) {
    final adjusted = (value + depth * 0.16).clamp(0.0, 1.0);
    if (adjusted < 0.22) {
      return Color.lerp(_deepBlue, _blue, adjusted / 0.22)!;
    }
    if (adjusted < 0.48) {
      return Color.lerp(_blue, _cyan, (adjusted - 0.22) / 0.26)!;
    }
    if (adjusted < 0.75) {
      return Color.lerp(_cyan, _sky, (adjusted - 0.48) / 0.27)!;
    }
    return Color.lerp(_sky, _ice, (adjusted - 0.75) / 0.25)!;
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) =>
      oldDelegate.time != time;
}
