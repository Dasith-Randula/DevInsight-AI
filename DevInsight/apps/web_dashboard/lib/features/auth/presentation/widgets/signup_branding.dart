import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/constants/app_assets.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';


class SignUpBranding extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onLogoTap;

  const SignUpBranding({super.key, this.isCompact = false, this.onLogoTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCompact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand Header (Logo + DevInsight Text)
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
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppAssets.devInsightLogo,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 14),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Dev',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF0F172A),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      TextSpan(
                        text: 'Insight',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryBlue,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Main Headline: "Create Your Account"
        Text(
          'Create Your Account',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0F172A),
            fontSize: isCompact ? 28 : 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle: "Start building smarter software projects with AI-powered insights"
        Text(
          'Start building smarter software projects\nwith AI-powered insights',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryBlue,
            fontSize: isCompact ? 15 : 17,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 20),

        // Feature Benefits List (4 items matching Figma design)
        _buildFeatureItem(
          icon: Icons.trending_up_rounded,
          title: 'Predict Risks',
          description: 'Identify issues before they impact your project.',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.format_list_bulleted_rounded,
          title: 'Prioritize Smartly',
          description: 'Focus on what matters most.',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Explain Clearly',
          description: 'Understand the why behind every insight.',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.rocket_launch_outlined,
          title: 'Recommend Actions',
          description: 'Understand the why behind every insight.',
        ),

        const SizedBox(height: 18),

        // 3D Dashboard & Donut Chart Laptop with Plant (SIGNUP.png)
        Align(
          alignment: isCompact ? Alignment.center : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isCompact ? 260 : 340),
            child: Image.asset(
              AppAssets.signupIllustration,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                AppAssets.signupIllustration,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rounded Square Icon Container
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFDCEBFE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
