import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({
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

  @override
  Widget build(BuildContext context) {
    final quality = overview?.qualitySignals;
    final activity = overview?.recentActivity ?? const <GitHubActivity>[];
    final weekly = overview?.weeklyActivity;
    final weeklyReady =
        weekly != null &&
        weekly.availability == 'available' &&
        weekly.isComplete &&
        weekly.totalCommits != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: scrollController,
          eyebrow: 'Engineering reports',
          title: 'Turn engineering intelligence into clarity.',
          description:
              'Build a shared understanding from verified repository signals. Report previews below use the active repository snapshot; export and generation are not yet available.',
        ),
        if (error != null)
          DashboardInlineNotice(
            message: overview == null
                ? 'Report data could not be loaded: $error'
                : 'Report previews use the available repository snapshot after a refresh error: $error',
            stale: overview != null,
          ),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final preview = _ReportPreview(
                    repository: repository,
                    overview: overview,
                    weeklyReady: weeklyReady,
                    activityCount: activity.length,
                  );
                  final categories = const _ReportCategories();
                  if (constraints.maxWidth < 780) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        preview,
                        const SizedBox(height: 34),
                        categories,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: preview),
                      const SizedBox(width: 42),
                      Expanded(flex: 4, child: categories),
                    ],
                  );
                },
              ),
              const SizedBox(height: 52),
              const DashboardSectionHeading(
                label: 'Report previews',
                title: 'Grounded in the selected project',
                description:
                    'These outlines are previews of available signals, not generated report files.',
              ),
              const SizedBox(height: 18),
              _ReportOutline(
                controller: scrollController,
                number: '01',
                title: 'Development activity',
                subtitle: 'Commit activity · languages · recent timeline',
                value: weeklyReady
                    ? '${weekly.totalCommits} commits across the reported 8-week period'
                    : 'Weekly activity unavailable or incomplete',
                color: dashboardBlue,
                icon: Icons.timeline_rounded,
              ),
              _ReportOutline(
                controller: scrollController,
                number: '02',
                title: 'Issues and pull requests',
                subtitle: 'Open counts · recent GitHub records · timestamps',
                value:
                    '${overview?.repositoryHealth?.openIssues?.toString() ?? 'Unavailable'} open issues · ${overview?.openPullRequests?.toString() ?? 'Unavailable'} open pull requests',
                color: const Color(0xFF7C3AED),
                icon: Icons.merge_type_rounded,
              ),
              _ReportOutline(
                controller: scrollController,
                number: '03',
                title: 'Engineering quality signals',
                subtitle: 'CI · tests detected · README · license',
                value:
                    'CI ${quality?.ci.state ?? 'not measured'} · tests ${_boolean(quality?.testsDetected)} · README ${_boolean(quality?.readmePresent)}',
                color: const Color(0xFF15A578),
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 42),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: context.appTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.appTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: dashboardBlue,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No report-generation or export endpoint is currently connected. There are no fake downloads or generated report records.',
                        style: dashboardTextStyle(
                          color: context.appTheme.primaryText,
                          size: 11,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 42),
              const DashboardSectionHeading(
                label: 'Report history',
                title: 'Generated reports',
                description:
                    'This workspace does not yet expose a persisted report history.',
              ),
              const SizedBox(height: 15),
              const DashboardEmptyState(
                icon: Icons.description_outlined,
                title: 'No generated reports',
                description:
                    'When report generation and storage are implemented, completed exports can appear here.',
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({
    required this.repository,
    required this.overview,
    required this.weeklyReady,
    required this.activityCount,
  });

  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final bool weeklyReady;
  final int activityCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: const Color(0xFF101B33),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.article_outlined, color: dashboardCyan),
            const SizedBox(width: 10),
            Text(
              'REPORT PREVIEW',
              style: dashboardTextStyle(
                color: Colors.white70,
                size: 9,
                weight: FontWeight.w800,
              ).copyWith(letterSpacing: 1.1),
            ),
            const SizedBox(height: 22),
            const DashboardStatusTag('NOT EXPORTED', color: Color(0xFFFFC857)),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          repository?.fullName ?? 'No project selected',
          style: dashboardTextStyle(
            color: Colors.white,
            size: 23,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Repository engineering snapshot',
          style: dashboardTextStyle(color: Colors.white60, size: 11),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            _PreviewStat(
              'Open issues',
              overview?.repositoryHealth?.openIssues?.toString() ?? '—',
            ),
            const SizedBox(width: 28),
            _PreviewStat(
              'Open PRs',
              overview?.openPullRequests?.toString() ?? '—',
            ),
            const SizedBox(width: 28),
            _PreviewStat('Activity rows', '$activityCount'),
          ],
        ),
        const SizedBox(height: 27),
        const Divider(color: Color(0xFF34425D)),
        const SizedBox(height: 14),
        _PreviewLine(
          label: 'Weekly activity',
          value: weeklyReady
              ? '${overview!.weeklyActivity!.totalCommits} commits · complete'
              : 'Unavailable / incomplete',
          color: weeklyReady ? dashboardCyan : const Color(0xFFFFC857),
        ),
        _PreviewLine(
          label: 'CI state',
          value: overview?.qualitySignals?.ci.state ?? 'Not measured',
          color: dashboardAzure,
        ),
        _PreviewLine(
          label: 'Languages',
          value:
              overview?.languages
                  .map((language) => language.name)
                  .take(3)
                  .join(', ') ??
              'Not available',
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 22),
        const SizedBox(height: 22),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white54,
              size: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Preview built from current cached overview',
                style: dashboardTextStyle(color: Colors.white54, size: 9),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: dashboardTextStyle(color: Colors.white54, size: 8)),
        const SizedBox(height: 7),
        Text(
          value,
          style: dashboardTextStyle(
            color: Colors.white,
            size: 20,
            weight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: dashboardTextStyle(color: Colors.white70, size: 10),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: dashboardTextStyle(
              color: Colors.white,
              size: 9,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReportCategories extends StatelessWidget {
  const _ReportCategories();

  static const _categories = [
    (
      'Development activity',
      'Weekly and recent repository signals',
      Icons.timeline_rounded,
    ),
    (
      'Issue & PR summary',
      'Issue and code review activity',
      Icons.merge_rounded,
    ),
    (
      'Engineering quality',
      'CI and repository hygiene signals',
      Icons.verified_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const DashboardSectionHeading(
        label: 'Available categories',
        title: 'Choose a report direction',
        description:
            'Each preview is grounded in fields currently returned by GitHub.',
      ),
      const SizedBox(height: 16),
      for (final item in _categories)
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: dashboardRule)),
          ),
          child: DashboardDataRow(
            leading: Icon(item.$3),
            title: item.$1,
            detail: item.$2,
            trailing: const DashboardStatusTag('PREVIEW', color: dashboardBlue),
          ),
        ),
    ],
  );
}

class _ReportOutline extends StatelessWidget {
  const _ReportOutline({
    required this.controller,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.icon,
  });

  final ScrollController controller;
  final String number;
  final String title;
  final String subtitle;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DashboardScrollReveal(
    controller: controller,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: dashboardRule)),
      ),
      child: Row(
        children: [
          Text(
            number,
            style: dashboardTextStyle(
              color: color,
              size: 12,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 18),
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: dashboardTextStyle(weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: dashboardTextStyle(color: dashboardMuted, size: 10),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: dashboardTextStyle(size: 10, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String _boolean(bool? value) => value == null
    ? 'not measured'
    : value
    ? 'detected'
    : 'not detected';
