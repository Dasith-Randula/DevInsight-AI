import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FBFF), Color(0xFFEDF5FF), Color(0xFFE6F1FC)],
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _AmbientBackgroundPainter(progress: _controller.value),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AmbientBackgroundPainter extends CustomPainter {
  const _AmbientBackgroundPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;
    final gridPaint = Paint()
      ..color = const Color(0x1414B8A6)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final glows = [
      (
        Offset(
          size.width * 0.18 + math.sin(phase) * 32,
          size.height * 0.18 + math.cos(phase) * 20,
        ),
        size.width * 0.38,
        AppColors.secondaryBlue,
      ),
      (
        Offset(
          size.width * 0.52 + math.sin(phase * 0.72) * 24,
          size.height * 0.30 + math.cos(phase * 0.72) * 18,
        ),
        size.width * 0.30,
        const Color(0xFF7DD3FC),
      ),
      (
        Offset(
          size.width * 0.82 + math.cos(phase * 0.82) * 42,
          size.height * 0.76 + math.sin(phase * 0.82) * 28,
        ),
        size.width * 0.42,
        AppColors.primaryBlue,
      ),
    ];

    for (final glow in glows) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            glow.$3.withValues(alpha: 0.075),
            glow.$3.withValues(alpha: 0.02),
            Colors.transparent,
          ],
          stops: const [0, 0.52, 1],
        ).createShader(Rect.fromCircle(center: glow.$1, radius: glow.$2));
      canvas.drawCircle(glow.$1, glow.$2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
