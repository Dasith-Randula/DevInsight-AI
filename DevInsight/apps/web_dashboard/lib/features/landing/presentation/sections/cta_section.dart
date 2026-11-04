import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/landing_reveal.dart';
import '../widgets/landing_style.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({
    super.key,
    required this.scrollController,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final ScrollController scrollController;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => LandingSectionFrame(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 88),
    child: LandingReveal(
      scrollController: scrollController,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 46),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050916), Color(0xFF0D235B), Color(0xFF0056FF)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: LandingColors.royalBlue.withValues(alpha: 0.2),
              blurRadius: 35,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final content = Column(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to Build Smarter Projects?',
                  textAlign: stacked ? TextAlign.center : TextAlign.left,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start with DevInsight and bring AI-powered intelligence into your software workflow.',
                  textAlign: stacked ? TextAlign.center : TextAlign.left,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 15.5,
                    height: 1.6,
                  ),
                ),
              ],
            );
            final buttons = Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: stacked ? WrapAlignment.center : WrapAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: LandingColors.royalBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
                OutlinedButton(
                  onPressed: onSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            );
            if (stacked) {
              return Column(
                children: [content, const SizedBox(height: 26), buttons],
              );
            }
            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 28),
                buttons,
              ],
            );
          },
        ),
      ),
    ),
  );
}
