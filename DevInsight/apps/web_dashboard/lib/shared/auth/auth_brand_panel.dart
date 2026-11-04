import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import 'auth_dot_surface.dart';

/// Right brand panel for the auth split-layout.
///
/// Shows:
/// - DevInsight logo + wordmark (Dev black, Insight blue).
/// - Main heading with blue-highlighted words.
/// - Supporting tagline.
/// - [AuthDotSurface] with an animated, depth-based dot surface.
///
/// Background is a very light blue-to-white gradient.
/// Wrapped in [RepaintBoundary] so illustration repaints don't affect parent.
class AuthBrandPanel extends StatelessWidget {
  final bool isCompact;
  const AuthBrandPanel({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF101C32),
                    Color(0xFF172B49),
                    Color(0xFF0B1528),
                  ]
                : const [
                    Color(0xFFEAF4FF),
                    Color(0xFFF4F9FF),
                    Color(0xFFFFFFFF),
                  ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Soft ambient blue glow in the corner
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.10),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: -30,
              right: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryBlue.withValues(alpha: 0.08),
                      blurRadius: 80,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 24 : 36,
                isCompact ? 24 : 40,
                isCompact ? 24 : 32,
                isCompact ? 20 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo + wordmark
                  _buildBranding(context),

                  SizedBox(height: isCompact ? 20 : 32),

                  // Main heading
                  _buildHeading(context, isCompact),

                  SizedBox(height: isCompact ? 10 : 14),

                  // Supporting text
                  Text(
                    'Predict risks, prioritize critical issues, and make\nconfident software project decisions.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.slateText,
                      fontSize: isCompact ? 12 : 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),

                  SizedBox(height: isCompact ? 20 : 28),

                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: SizedBox(
                      height: isCompact ? 180 : 240,
                      width: double.infinity,
                      child: const AuthDotSurface(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo container with blue glow
        Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            AppAssets.devInsightLogo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, _) => const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryBlue,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Wordmark: Dev (black) + Insight (blue)
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Dev',
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              TextSpan(
                text: 'Insight',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeading(BuildContext context, bool compact) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Engineering\n',
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: 'Intelligence',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primaryBlue,
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: ', Made Smarter.',
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
