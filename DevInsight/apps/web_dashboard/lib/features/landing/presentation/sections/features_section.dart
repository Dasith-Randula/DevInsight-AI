import 'package:flutter/material.dart';

import '../widgets/landing_reveal.dart';
import '../widgets/landing_style.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, required this.scrollController});

  final ScrollController scrollController;

  static const _items = [
    (
      Icons.shield_outlined,
      'Predict Risks',
      'Identify delivery risks before they become major issues.',
    ),
    (
      Icons.low_priority_rounded,
      'Prioritize Work',
      'Focus on the tasks that matter most with AI-assisted insights.',
    ),
    (
      Icons.track_changes_rounded,
      'Track Progress',
      'Monitor project health and team movement in a simple way.',
    ),
    (
      Icons.rocket_launch_outlined,
      'Improve Delivery',
      'Keep software projects organized, measurable, and on track.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LandingSectionFrame(
    child: Column(
      children: [
        LandingReveal(
          scrollController: scrollController,
          child: const LandingSectionHeading(
            eyebrow: 'Clarity for every stage',
            title: 'Everything You Need to Deliver Better Projects',
            description:
                'AI-driven tools that give your team clarity, focus, and control across the software project lifecycle.',
          ),
        ),
        const SizedBox(height: 44),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 940
                ? 4
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final cardWidth =
                (constraints.maxWidth - (columns - 1) * 18) / columns;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                for (var index = 0; index < _items.length; index++)
                  SizedBox(
                    width: cardWidth,
                    child: LandingReveal(
                      scrollController: scrollController,
                      delay: Duration(milliseconds: index * 90),
                      child: LandingIconCard(
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
