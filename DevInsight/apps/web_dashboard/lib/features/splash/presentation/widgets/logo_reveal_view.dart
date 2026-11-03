import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// The cinematic Logo & Name reveal view for the splash screen.
/// Choreographs a video-like reveal:
/// 1. Radiant concentric ripple waves
/// 2. Logo spring/scale entrance with soft glowing aura
/// 3. Specular light sweep sheen across the logo
/// 4. Staggered brand typography ("DevInsight") reveal with letter-spacing settle
/// 5. Tagline & AI intelligence chip reveal
/// 6. Smooth presentation of status / loader
class LogoRevealView extends StatelessWidget {
  final AnimationController revealController;
  final bool isCompact;
  final Widget loadingArea;

  const LogoRevealView({
    super.key,
    required this.revealController,
    required this.isCompact,
    required this.loadingArea,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = isCompact ? 96.0 : 124.0;
    final titleSize = isCompact ? 48.0 : 66.0;
    final subtitleSize = isCompact ? 16.0 : 20.0;

    return AnimatedBuilder(
      animation: revealController,
      builder: (context, _) {
        final val = revealController.value;

        // 1. Ripple Animation: 0.0 -> 0.48
        final rippleProgress = (val / 0.48).clamp(0.0, 1.0);

        // 2. Logo Scale & Opacity: 0.08 -> 0.56
        final logoEnterVal = ((val - 0.08) / 0.48).clamp(0.0, 1.0);
        final logoScale =
            0.35 + 0.65 * Curves.easeOutBack.transform(logoEnterVal);
        final logoOpacity = Curves.easeOutCubic.transform(logoEnterVal);

        // 3. Logo Glow Intensity: 0.15 -> 0.70
        final glowVal = ((val - 0.15) / 0.55).clamp(0.0, 1.0);
        final glowOpacity = Curves.easeInOutSine.transform(glowVal);

        // 4. Specular Shimmer Sheen on Logo: 0.42 -> 0.85
        final shimmerVal = ((val - 0.42) / 0.43).clamp(0.0, 1.0);
        final shimmerProgress =
            -1.0 + 3.0 * Curves.easeInOutCubic.transform(shimmerVal);

        // 5. Text Reveal: 0.36 -> 0.78
        final textEnterVal = ((val - 0.36) / 0.42).clamp(0.0, 1.0);
        final textOpacity = Curves.easeOutQuad.transform(textEnterVal);
        final textSlide =
            (1.0 - Curves.easeOutCubic.transform(textEnterVal)) * 26.0;
        final letterSpacing =
            2.4 - (3.8 * Curves.easeOutCubic.transform(textEnterVal));

        // 6. Text Shimmer: 0.62 -> 0.95
        final textShimmerVal = ((val - 0.62) / 0.33).clamp(0.0, 1.0);
        final textShimmerProgress =
            -0.5 + 2.0 * Curves.easeInOut.transform(textShimmerVal);

        // 7. Tagline & AI Chip: 0.58 -> 0.90
        final tagVal = ((val - 0.58) / 0.32).clamp(0.0, 1.0);
        final tagOpacity = Curves.easeOutQuad.transform(tagVal);
        final tagSlide = (1.0 - Curves.easeOutCubic.transform(tagVal)) * 18.0;

        // 8. Loader / Action area: 0.75 -> 1.0
        final loaderVal = ((val - 0.75) / 0.25).clamp(0.0, 1.0);
        final loaderOpacity = Curves.easeOutQuad.transform(loaderVal);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isCompact ? 420 : 780),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ==================== LOGO STAGE WITH RIPPLES & GLOW ====================
              SizedBox(
                width: logoSize * 1.8,
                height: logoSize * 1.8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Concentric expanding shockwave ripples
                    if (rippleProgress > 0.0 && rippleProgress < 1.0)
                      CustomPaint(
                        size: Size.square(logoSize * 1.8),
                        painter: _RippleWavePainter(progress: rippleProgress),
                      ),

                    // Ambient blooming halo behind logo
                    Opacity(
                      opacity: glowOpacity,
                      child: Container(
                        width: logoSize * 1.15,
                        height: logoSize * 1.15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0664F2,
                              ).withValues(alpha: 0.28),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFF38BDF8,
                              ).withValues(alpha: 0.32),
                              blurRadius: 60,
                              spreadRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Logo Icon with Spring scale, Opacity, and Specular Light Sweep
                    Opacity(
                      opacity: logoOpacity,
                      child: Transform.scale(
                        scale: logoScale,
                        child: Semantics(
                          label: 'DevInsight logo',
                          image: true,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pure logo image
                              Image.asset(
                                AppAssets.devInsightLogo,
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                semanticLabel: 'DevInsight logo',
                              ),

                              // Specular light sweep sheen overlay
                              if (shimmerVal > 0.0 && shimmerVal < 1.0)
                                SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      logoSize / 2,
                                    ),
                                    child: CustomPaint(
                                      painter: _LightSweepPainter(
                                        progress: shimmerProgress,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==================== BRAND TYPOGRAPHY REVEAL ====================
              Opacity(
                opacity: textOpacity,
                child: Transform.translate(
                  offset: Offset(0, textSlide),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Dev',
                              style: GoogleFonts.plusJakartaSans(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: letterSpacing,
                                height: 1.15,
                              ),
                            ),
                            TextSpan(
                              text: 'Insight',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primaryBlue,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: letterSpacing,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Specular light shimmer across the typography
                      if (textShimmerVal > 0.0 && textShimmerVal < 1.0)
                        IgnorePointer(
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              final sweepWidth = bounds.width * 0.35;
                              final startX =
                                  (bounds.width + sweepWidth * 2) *
                                      textShimmerProgress -
                                  sweepWidth;
                              return LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.8),
                                  const Color(
                                    0xFF38BDF8,
                                  ).withValues(alpha: 0.9),
                                  Colors.white.withValues(alpha: 0.8),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
                              ).createShader(
                                Rect.fromLTWH(
                                  startX,
                                  0,
                                  sweepWidth,
                                  bounds.height,
                                ),
                              );
                            },
                            blendMode: BlendMode.srcATop,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Dev',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: letterSpacing,
                                      height: 1.15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Insight',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: letterSpacing,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================== TAGLINE & AI CHIP REVEAL ====================
              Opacity(
                opacity: tagOpacity,
                child: Transform.translate(
                  offset: Offset(0, tagSlide),
                  child: Column(
                    children: [
                      // Modern Frosted AI Intelligence Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(
                              0xFF38BDF8,
                            ).withValues(alpha: 0.40),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0664F2,
                              ).withValues(alpha: 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NEXT-GEN SOFTWARE INTELLIGENCE',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'AI-Powered intelligence for Smarter Software Projects',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.70),
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ==================== LOADER & ACTION AREA ====================
              Opacity(opacity: loaderOpacity, child: loadingArea),
            ],
          ),
        );
      },
    );
  }
}

/// Paints radiant concentric shockwave ripples expanding from behind the logo.
class _RippleWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  const _RippleWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;
    final center = size.center(Offset.zero);
    final maxRadius = size.width * 0.50;

    // First primary ripple
    final r1 = maxRadius * (0.25 + 0.75 * progress);
    final alpha1 = (1.0 - progress) * 0.42;
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * (1.0 - progress * 0.45)
      ..color = const Color(0xFF38BDF8).withValues(alpha: alpha1);
    canvas.drawCircle(center, r1, paint1);

    // Second echo ripple
    if (progress > 0.18) {
      final p2 = ((progress - 0.18) / 0.82).clamp(0.0, 1.0);
      final r2 = maxRadius * (0.20 + 0.80 * p2);
      final alpha2 = (1.0 - p2) * 0.30;
      final paint2 = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * (1.0 - p2 * 0.4)
        ..color = const Color(0xFF0664F2).withValues(alpha: alpha2);
      canvas.drawCircle(center, r2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant _RippleWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Paints a cinematic diagonal specular light sweep across the logo.
class _LightSweepPainter extends CustomPainter {
  final double progress;

  const _LightSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweepWidth = size.width * 0.40;
    final startX = (size.width + sweepWidth * 2) * progress - sweepWidth;

    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.65),
          const Color(0xFF93C5FD).withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(startX, 0, sweepWidth, size.height));

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _LightSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
