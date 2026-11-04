import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'landing_style.dart';

class LandingHero extends StatefulWidget {
  const LandingHero({
    super.key,
    required this.height,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final double height;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  State<LandingHero> createState() => _LandingHeroState();
}

class _LandingHeroState extends State<LandingHero>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _introController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 620;
    final titleSize = width < 480
        ? 39.0
        : width < 900
        ? 52.0
        : 66.0;
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF050916),
                  Color(0xFF08132E),
                  Color(0xFF0D235B),
                  Color(0xFF0056FF),
                  Color(0xFF2277FF),
                  Color(0xFFB8D5FF),
                  Color(0xFFEAF2FF),
                  Color(0xFFF5F8FF),
                ],
                stops: [0.0, 0.18, 0.39, 0.59, 0.72, 0.84, 0.93, 1.0],
              ),
            ),
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) => CustomPaint(
                  painter: _HeroGlowPainter(_glowController.value),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.07),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 22 : 36,
                82,
                mobile ? 22 : 36,
                96,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IntroPart(
                      controller: _introController,
                      interval: const Interval(
                        0,
                        0.55,
                        curve: Curves.easeOutCubic,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.17),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: LandingColors.sky,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI-Powered Project Intelligence',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 27),
                    _IntroPart(
                      controller: _introController,
                      interval: const Interval(
                        0.08,
                        0.72,
                        curve: Curves.easeOutCubic,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Smarter Software Projects,\n',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                                letterSpacing: -2.0,
                              ),
                            ),
                            TextSpan(
                              text: 'Powered by AI.',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF57B7FF),
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                height: 1.12,
                                letterSpacing: -1.8,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _IntroPart(
                      controller: _introController,
                      interval: const Interval(
                        0.18,
                        0.82,
                        curve: Curves.easeOutCubic,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Text(
                          'Predict risks, prioritize issues, and deliver software projects with more confidence.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: mobile ? 16 : 18,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 29),
                    _IntroPart(
                      controller: _introController,
                      interval: const Interval(
                        0.28,
                        0.92,
                        curve: Curves.easeOutCubic,
                      ),
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _HeroButton(
                            label: 'Get Started',
                            primary: true,
                            onPressed: widget.onGetStarted,
                          ),
                          _HeroButton(
                            label: 'Sign In',
                            primary: false,
                            onPressed: widget.onSignIn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    _IntroPart(
                      controller: _introController,
                      interval: const Interval(
                        0.42,
                        1,
                        curve: Curves.easeOutCubic,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: mobile ? 18 : 30,
                        runSpacing: 14,
                        children: const [
                          _ValuePoint(Icons.shield_outlined, 'Risk Prediction'),
                          _ValuePoint(
                            Icons.layers_outlined,
                            'Issue Prioritization',
                          ),
                          _ValuePoint(
                            Icons.lightbulb_outline,
                            'Project Insights',
                          ),
                          _ValuePoint(Icons.bolt_rounded, 'Team Productivity'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPart extends StatelessWidget {
  const _IntroPart({
    required this.controller,
    required this.interval,
    required this.child,
  });

  final AnimationController controller;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: child,
    builder: (context, child) {
      final value = interval.transform(controller.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      );
    },
  );
}

class _HeroButton extends StatefulWidget {
  const _HeroButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
      child: widget.primary
          ? ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hovered
                    ? LandingColors.lavender
                    : Colors.white,
                foregroundColor: LandingColors.royalBlue,
                fixedSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                elevation: _hovered ? 2 : 5,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: widget.onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _hovered
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0x40050916),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: _hovered ? 1 : 0.85),
                  width: 1.5,
                ),
                fixedSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
    ),
  );
}

class _ValuePoint extends StatelessWidget {
  const _ValuePoint(this.icon, this.title);
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: LandingColors.sky),
      const SizedBox(width: 8),
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _HeroGlowPainter extends CustomPainter {
  const _HeroGlowPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    _glow(
      canvas,
      size,
      Offset(size.width * (0.92 + math.sin(t) * 0.018), size.height * 0.12),
      size.width * 0.58,
      const Color(0xFF2277FF),
      0.20,
    );
    _glow(
      canvas,
      size,
      Offset(size.width * (0.06 + math.cos(t) * 0.012), size.height * 0.91),
      size.width * 0.34,
      const Color(0xFF79B8FF),
      0.08,
    );
  }

  void _glow(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.34),
          Colors.transparent,
        ],
        stops: const [0, 0.48, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroGlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
