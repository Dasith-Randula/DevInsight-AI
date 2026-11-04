import 'package:flutter/material.dart';

import '../widgets/landing_reveal.dart';
import '../widgets/landing_style.dart';

class ResearchSection extends StatelessWidget {
  const ResearchSection({super.key, required this.scrollController});

  final ScrollController scrollController;

  static const _items = [
    (
      Icons.radar_rounded,
      'Risk Signals',
      'Understand warning signs across software project activity.',
    ),
    (
      Icons.manage_search_rounded,
      'Root Cause Insights',
      'Reveal patterns behind delays, blockers, and performance issues.',
    ),
    (
      Icons.tips_and_updates_outlined,
      'Actionable Recommendations',
      'Turn engineering activity into decision-ready insights.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LandingSectionFrame(
    child: Column(
      children: [
        LandingReveal(
          scrollController: scrollController,
          child: const LandingSectionHeading(
            eyebrow: 'Research-led product',
            title: 'Research-Driven Intelligence',
            description:
                'Built on software engineering insights to support better project decisions.',
          ),
        ),
        const SizedBox(height: 44),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 3 : 1;
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
                      delay: Duration(milliseconds: index * 110),
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
