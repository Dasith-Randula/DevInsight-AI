import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

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
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [
                      Color(0xFF080F20),
                      Color(0xFF0D1930),
                      Color(0xFF080F20),
                    ]
                  : const [Colors.white, Color(0xFFF5F8FF), Color(0xFFEAF2FF)],
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _SectionAmbientPainter(
                  progress: _controller.value,
                  dark: dark,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SectionAmbientPainter extends CustomPainter {
  const _SectionAmbientPainter({required this.progress, required this.dark});

  final double progress;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = progress * math.pi * 2;
    final radius = size.shortestSide * 0.85;
    final glows = [
      (
        Offset(
          size.width * (0.03 + math.sin(phase) * 0.015),
          size.height * 0.38,
        ),
        const Color(0xFF2277FF),
      ),
      (
        Offset(
          size.width * (0.96 + math.cos(phase) * 0.012),
          size.height * 0.72,
        ),
        const Color(0xFF79B8FF),
      ),
    ];

    for (final glow in glows) {
      final alpha = dark ? 0.055 : 0.045;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            glow.$2.withValues(alpha: alpha),
            glow.$2.withValues(alpha: alpha * 0.35),
            Colors.transparent,
          ],
          stops: const [0, 0.42, 1],
        ).createShader(Rect.fromCircle(center: glow.$1, radius: radius));
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SectionAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}
