import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/landing_reveal.dart';
import '../widgets/landing_style.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.scrollController});

  final ScrollController scrollController;

  static const _items = [
    (
      Icons.flag_outlined,
      'Our Mission',
      'Make software project delivery smarter and more reliable.',
    ),
    (
      Icons.groups_2_outlined,
      'Our Team',
      'Built by developers, designed for project managers and software teams.',
    ),
    (
      Icons.handshake_outlined,
      'Our Commitment',
      'Focused on clarity, trust, usability, and practical decision support.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LandingSectionFrame(
    child: Column(
      children: [
        LandingReveal(
          scrollController: scrollController,
          child: const LandingSectionHeading(
            eyebrow: 'People behind the platform',
            title: 'About Us',
            description:
                'DevInsight helps software teams build safer, smarter, and more predictable projects through AI-powered engineering intelligence.',
          ),
        ),
        const SizedBox(height: 44),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 820 ? 3 : 1;
            final blockWidth =
                (constraints.maxWidth - (columns - 1) * 28) / columns;
            return Wrap(
              spacing: 28,
              runSpacing: 28,
              children: [
                for (var index = 0; index < _items.length; index++)
                  SizedBox(
                    width: blockWidth,
                    child: LandingReveal(
                      scrollController: scrollController,
                      delay: Duration(milliseconds: index * 100),
                      child: _AboutBlock(
                        icon: _items[index].$1,
                        title: _items[index].$2,
                        description: _items[index].$3,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _AboutBlock extends StatelessWidget {
  const _AboutBlock({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: LandingColors.royalBlue.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: LandingColors.royalBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: landingTextColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: landingBodyColor(context),
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
