import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/landing_reveal.dart';
import '../widgets/landing_style.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key, required this.scrollController});

  final ScrollController scrollController;

  static const _steps = [
    (
      Icons.link_rounded,
      'Connect Your Project',
      'Link your repository or project data sources.',
    ),
    (
      Icons.auto_awesome_rounded,
      'Analyze with AI',
      'Detect risks, patterns, bottlenecks, and priorities.',
    ),
    (
      Icons.task_alt_rounded,
      'Take Action',
      'Use the insights to plan smarter and deliver better.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LandingSectionFrame(
    child: Column(
      children: [
        LandingReveal(
          scrollController: scrollController,
          child: const LandingSectionHeading(
            eyebrow: 'A clear path forward',
            title: 'How It Works',
            description:
                'From project data to actionable insights in three simple steps.',
          ),
        ),
        const SizedBox(height: 48),
        LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 760;
            return Flex(
              direction: horizontal ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var index = 0; index < _steps.length; index++) ...[
                  ExpandedIf(
                    expanded: horizontal,
                    child: LandingReveal(
                      scrollController: scrollController,
                      delay: Duration(milliseconds: index * 130),
                      child: _StepCard(
                        number: index + 1,
                        icon: _steps[index].$1,
                        title: _steps[index].$2,
                        description: _steps[index].$3,
                      ),
                    ),
                  ),
                  if (index < _steps.length - 1)
                    horizontal
                        ? const _StepConnector()
                        : const SizedBox(height: 18),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}

class ExpandedIf extends StatelessWidget {
  const ExpandedIf({super.key, required this.expanded, required this.child});
  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      expanded ? Expanded(child: child) : child;
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF121D35) : Colors.white,
        border: Border.all(color: LandingColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LandingColors.royalBlue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: LandingColors.royalBlue, size: 25),
              ),
              const Spacer(),
              Text(
                '0$number',
                style: GoogleFonts.plusJakartaSans(
                  color: LandingColors.royalBlue.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: landingTextColor(context),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
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
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    child: Center(
      child: Container(
        height: 2,
        color: LandingColors.royalBlue.withValues(alpha: 0.18),
      ),
    ),
  );
}
