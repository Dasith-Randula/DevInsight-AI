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
              colors: [
                AppColors.softBlueBg,
                Color(0xFFF9FCFF),
                Color(0xFFF0F7FF),
              ],
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
