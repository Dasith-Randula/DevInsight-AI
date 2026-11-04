import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/constants/app_assets.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';


class LoginBranding extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onLogoTap;

  const LoginBranding({super.key, this.isCompact = false, this.onLogoTap});

  @override
  Widget build(BuildContext context) {
    final titleSize = isCompact ? 32.0 : 42.0;
    final logoSize = isCompact ? 50.0 : 62.0;
    final imageWidth = isCompact ? 320.0 : 490.0;

    return Column(
      crossAxisAlignment: isCompact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand Header (Glowing Attractive Logo + Rich Gradient Typography)
        MouseRegion(
          cursor: onLogoTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: onLogoTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Logo Glass Backplate
                Container(
                  width: logoSize + 14,
                  height: logoSize + 14,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.28),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppAssets.devInsightLogo,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.code_rounded,
                      color: AppColors.primaryBlue,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                // DevInsight Title with Gradient on 'Insight'
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Dev',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF0F172A),
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              TextSpan(
                                text: 'Insight',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  foreground: Paint()
                                    ..shader =
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF0664F2),
                                            Color(0xFF0EA5E9),
                                          ],
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 160, 40),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Attractive 'AI' Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0664F2), Color(0xFF38BDF8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'AI PLATFORM',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Charming Single-Line Caption in Glassmorphic Pill
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'AI-Powered Intelligence ',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1E293B),
                            fontSize: isCompact ? 13.5 : 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextSpan(
                          text: 'for Smarter Software Projects',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primaryBlue,
                            fontSize: isCompact ? 13.5 : 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: isCompact ? 24 : 34),

        // Crystal-Clear High-Res 3D Laptop Illustration with Ambient Ground Glow
        Align(
          alignment: isCompact ? Alignment.center : Alignment.centerLeft,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient Light Pool behind illustration
              Positioned(
                bottom: 10,
                child: Container(
                  width: imageWidth * 0.75,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.22),
                        blurRadius: 40,
                        spreadRadius: 12,
                      ),
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Crisp High-Res Image
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: imageWidth),
                child: Image.asset(
                  AppAssets.loginIllustration,
                  width: imageWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    AppAssets.loginIllustration,
                    width: imageWidth,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
