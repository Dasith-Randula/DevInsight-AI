import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// The cinematic Logo & Name reveal view for DevInsight Midnight Aurora.
///
/// Choreography:
/// - 0.0–3.0s: Top-to-bottom reveal of the original logo PNG.
/// - 1.2–3.0s: DevInsight wordmark typing character-by-character with white "Dev"
///             and Royal Blue "Insight".
/// - 2.4–3.0s: Subtitle fades in with gentle 8px upward movement.
/// - 0.0–6.0s: Progress bar fills, followed by animated ellipsis loading text.
class LogoRevealView extends StatefulWidget {
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
  State<LogoRevealView> createState() => _LogoRevealViewState();
}

class _LogoRevealViewState extends State<LogoRevealView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoRevealController;
  late final CurvedAnimation _logoRevealAnimation;

  @override
  void initState() {
    super.initState();
    _logoRevealController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _logoRevealAnimation = CurvedAnimation(
      parent: _logoRevealController,
      curve: Curves.easeInOutCubic,
    );
    _logoRevealController.forward();
  }

  @override
  void dispose() {
    _logoRevealAnimation.dispose();
    _logoRevealController.dispose();
    super.dispose();
  }

  static const int _totalChars = 10;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final logoSize = isMobile
        ? 104.0
        : isTablet
        ? 120.0
        : 136.0;

    final titleSize = isMobile
        ? 40.0
        : isTablet
        ? 52.0
        : 64.0;

    final subtitleSize = isMobile ? 13.5 : 17.5;

    return AnimatedBuilder(
      animation: widget.revealController,
      builder: (context, _) {
        final elapsedSeconds = widget.revealController.value * 3.2;

        // 1. Logo glow: 0.0s -> 1.5s
        final glowProgress = (elapsedSeconds / 1.5).clamp(0.0, 1.0);
        final glowOpacity =
            (0.2 + 0.6 * Curves.easeInOutSine.transform(glowProgress)).clamp(
              0.0,
              0.85,
            );

        // 2. Wordmark typing: 1.2s -> 3.0s (1.8s total duration for 10 chars)
        final typingVal = ((elapsedSeconds - 1.2) / 1.8).clamp(0.0, 1.0);
        final currentCharsCount = (typingVal * _totalChars).floor().clamp(
          0,
          _totalChars,
        );
        final isTypingActive = elapsedSeconds >= 1.2 && elapsedSeconds < 3.0;

        // 3. Subtitle reveal: 2.4s -> 3.0s (0.6s duration)
        final subtitleVal = ((elapsedSeconds - 2.4) / 0.6).clamp(0.0, 1.0);
        final subtitleOpacity = Curves.easeOutQuad.transform(subtitleVal);
        final subtitleSlide =
            (1.0 - Curves.easeOutCubic.transform(subtitleVal)) * 8.0;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? 380 : 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ==================== 1. DEVINSIGHT LOGO ====================
              SizedBox(
                width: logoSize * 1.4,
                height: logoSize * 1.4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Atmospheric ambient glow behind logo
                    Opacity(
                      opacity: glowOpacity,
                      child: Container(
                        width: logoSize * 1.05,
                        height: logoSize * 1.05,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 44,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: AppColors.azureBlue.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 65,
                              spreadRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    AnimatedBuilder(
                      animation: _logoRevealAnimation,
                      builder: (context, _) => SizedBox(
                        width: logoSize,
                        height: logoSize,
                        child: ClipRect(
                          clipper: _TopToBottomLogoClipper(
                            progress: _logoRevealAnimation.value,
                          ),
                          child: Image.asset(
                            AppAssets.devInsightBrandingLogo,
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================== 2. DEVINSIGHT WORDMARK ====================
              // Uses a Stack with an invisible full wordmark to lock width and height,
              // preventing horizontal shift during typing.
              Stack(
                alignment: Alignment.center,
                children: [
                  // Invisible reservation layout
                  Opacity(
                    opacity: 0.0,
                    child: _buildWordmarkText(
                      titleSize: titleSize,
                      devChars: 3,
                      insightChars: 7,
                    ),
                  ),

                  // Active typed text with cursor
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildWordmarkText(
                        titleSize: titleSize,
                        devChars: math.min(currentCharsCount, 3),
                        insightChars: math.max(0, currentCharsCount - 3),
                      ),
                      if (isTypingActive)
                        Container(
                          width: 3.0,
                          height: titleSize * 0.85,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.azureBlue.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================== 3. SUBTITLE ====================
              Opacity(
                opacity: subtitleOpacity,
                child: Transform.translate(
                  offset: Offset(0, subtitleSlide),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'AI-Powered Intelligence for Smarter Software Projects',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.softLavender.withValues(alpha: 0.92),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: isMobile ? 36 : 48),

              // ==================== 4. LOADING BAR & TEXT ====================
              widget.loadingArea,
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordmarkText({
    required double titleSize,
    required int devChars,
    required int insightChars,
  }) {
    final devSubstring = 'Dev'.substring(0, devChars);
    final insightSubstring = 'Insight'.substring(0, insightChars);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          // "Dev" in pure White #FFFFFF
          TextSpan(
            text: devSubstring,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1.15,
            ),
          ),
          // "Insight" in solid Royal Blue
          TextSpan(
            text: insightSubstring,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.royalBlue,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopToBottomLogoClipper extends CustomClipper<Rect> {
  final double progress;

  const _TopToBottomLogoClipper({required this.progress});

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * progress.clamp(0.0, 1.0));

  @override
  bool shouldReclip(covariant _TopToBottomLogoClipper oldClipper) =>
      oldClipper.progress != progress;
}
