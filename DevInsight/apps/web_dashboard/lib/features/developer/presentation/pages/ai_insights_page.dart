import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

class AiInsightsPage extends StatelessWidget {
  const AiInsightsPage({
    super.key,
    required this.scrollController,
    required this.repository,
    required this.overview,
    required this.error,
  });

  final ScrollController scrollController;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final String? error;

  static const _research = [
    (
      '01',
      'Software Defect Prediction',
      'Research direction: learn from verified change and repository signals to identify code that may merit additional review.',
      Color(0xFFE24B4B),
      Icons.bug_report_outlined,
    ),
    (
      '02',
      'Issue Prioritization',
      'Research direction: organize issue context to help teams focus; no ranking is generated today.',
      Color(0xFF2277FF),
      Icons.low_priority_rounded,
    ),
    (
      '03',
      'Root Cause Analysis',
      'Research direction: connect code changes, failures, and issue history to support investigation.',
      Color(0xFF7C3AED),
      Icons.device_hub_rounded,
    ),
    (
      '04',
      'Developer Workload Intelligence',
      'Research direction: support sustainable planning without individual performance scores.',
      Color(0xFF14AFC9),
      Icons.groups_2_outlined,
    ),
    (
      '05',
      'Project Risk Prediction',
      'Research direction: assess project-level signals with transparent scope and documented limitations.',
      Color(0xFFEA8A18),
      Icons.warning_amber_rounded,
    ),
    (
      '06',
      'Explainable AI Recommendations',
      'Research direction: pair any future recommendation with traceable evidence and human review.',
      Color(0xFF15A578),
      Icons.lightbulb_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activityCount = overview?.recentActivity.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: scrollController,
          eyebrow: 'Research & intelligence',
          title: 'Intelligence beyond the code.',
          description:
              'DevInsight is exploring responsible software-engineering intelligence. The ML workflows below are research directions, not operational models or predictions.',
        ),
        if (error != null)
          DashboardInlineNotice(
            message: overview == null
                ? 'Repository context could not be loaded: $error'
                : 'Showing available repository context after a refresh error: $error',
            stale: overview != null,
          ),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF101B33),
                      Color(0xFF252052),
                      Color(0xFF243F79),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final title = Text(
                          'RESEARCH WORKFLOW',
                          style: dashboardTextStyle(
                            color: Colors.white70,
                            size: 10,
                            weight: FontWeight.w800,
                          ).copyWith(letterSpacing: 1.2),
                        );
                        const status = DashboardStatusTag(
                          'PLANNED · NOT ACTIVE',
                          color: Color(0xFFFFC857),
                        );
                        if (constraints.maxWidth < 470) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: dashboardCyan,
                                  ),
                                  const SizedBox(width: 10),
                                  title,
                                ],
                              ),
                              const SizedBox(height: 12),
                              status,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: dashboardCyan,
                            ),
                            const SizedBox(width: 10),
                            title,
                            const Spacer(),
                            status,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'From repository signals to accountable insight.',
                      style: dashboardTextStyle(
                        color: Colors.white,
                        size: 22,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Future research will require validated data, evaluation, and human oversight before any model can make a claim about a project.',
                      style: dashboardTextStyle(
                        color: Colors.white70,
                        size: 11,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 22),
                    DashboardAnimatedWorkflow(
                      controller: scrollController,
                      stages: const [
                        'GitHub signals',
                        'Feature design',
                        'Model validation',
                        'Human review',
                      ],
                      accent: dashboardCyan,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Active project: ${repository?.fullName ?? 'none selected'} · ${repository == null ? 'No model inputs available' : '$activityCount recent source records available'}',
                      style: dashboardTextStyle(
                        color: Colors.white60,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 52),
              const DashboardSectionHeading(
                label: 'Research portfolio',
                title: 'Six questions worth answering carefully',
                description:
                    'Each line describes an intended capability. No scores, risk estimates, root causes, or personalized workload recommendations are produced.',
              ),
              const SizedBox(height: 22),
              for (final (index, item) in _research.indexed)
                DashboardScrollReveal(
                  controller: scrollController,
                  delay: Duration(milliseconds: 75 * index),
                  child: _ResearchTrack(
                    number: item.$1,
                    title: item.$2,
                    description: item.$3,
                    color: item.$4,
                    icon: item.$5,
                    index: index,
                  ),
                ),
              const SizedBox(height: 44),
              LayoutBuilder(
                builder: (context, constraints) {
                  final content = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        color: dashboardBlue,
                        size: 26,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What is available today',
                              style: dashboardTextStyle(
                                size: 17,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              overview == null
                                  ? 'Connect a repository to review factual GitHub activity and engineering signals. Those signals are not ML predictions.'
                                  : 'The selected repository provides factual GitHub activity and engineering signals. These are descriptive data, not predictions or model explanations.',
                              style: dashboardTextStyle(
                                color: dashboardMuted,
                                size: 11,
                                height: 1.65,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: dashboardRule),
                        bottom: BorderSide(color: dashboardRule),
                      ),
                    ),
                    child: content,
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResearchTrack extends StatelessWidget {
  const _ResearchTrack({
    required this.number,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.index,
  });

  final String number;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final emphasized = index == 0 || index == 2 || index == 4;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: emphasized ? 22 : 0,
        vertical: 22,
      ),
      margin: EdgeInsets.only(left: index.isOdd ? 42 : 0),
      decoration: BoxDecoration(
        color: emphasized ? color.withValues(alpha: .055) : Colors.transparent,
        border: Border(
          left: BorderSide(color: color, width: emphasized ? 3 : 1.5),
          bottom: const BorderSide(color: dashboardRule),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                number,
                style: dashboardTextStyle(
                  color: color,
                  size: 13,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: dashboardTextStyle(
                      size: 16,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: dashboardTextStyle(
                      color: dashboardMuted,
                      size: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            if (constraints.maxWidth > 560) ...[
              const SizedBox(width: 16),
              DashboardStatusTag('PLANNED', color: color),
            ],
          ],
        ),
      ),
    );
  }
}
