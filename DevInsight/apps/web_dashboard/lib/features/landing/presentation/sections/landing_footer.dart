import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../widgets/landing_style.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.onFeatures,
    required this.onHowItWorks,
    required this.onResearch,
    required this.onAbout,
    required this.onSignIn,
  });

  final VoidCallback onFeatures;
  final VoidCallback onHowItWorks;
  final VoidCallback onResearch;
  final VoidCallback onAbout;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : LandingColors.ink;
    final secondary = dark ? const Color(0xFFB7C4DC) : LandingColors.body;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF080F20) : LandingColors.background,
        border: const Border(top: BorderSide(color: LandingColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 28,
            spacing: 36,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      AppAssets.devInsightLogo,
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DevInsight',
                            style: GoogleFonts.plusJakartaSans(
                              color: foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'AI-powered clarity for software project teams.',
                            style: GoogleFonts.plusJakartaSans(
                              color: secondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _FooterLink('Features', onFeatures),
                  _FooterLink('How It Works', onHowItWorks),
                  _FooterLink('Research', onResearch),
                  _FooterLink('About Us', onAbout),
                  _FooterLink('Sign In', onSignIn),
                ],
              ),
              Text(
                '© ${DateTime.now().year} DevInsight',
                style: GoogleFonts.plusJakartaSans(
                  color: secondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(foregroundColor: landingBodyColor(context)),
    child: Text(label),
  );
}
