import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({
    super.key,
    required this.scrollController,
    required this.repository,
    required this.overview,
    required this.loading,
    required this.error,
  });

  final ScrollController scrollController;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final weekly = overview?.weeklyActivity;
    final languages =
        overview?.languages
            .map(
              (language) =>
                  (name: language.name, percentage: language.percentage),
            )
            .toList() ??
        const <({String name, double percentage})>[];
    final activity = overview?.recentActivity ?? const <GitHubActivity>[];
    final commits = activity.where((item) => item.type == 'commit').length;
    final issues = activity.where((item) => item.type == 'issue').length;
    final pulls = activity.where((item) => item.type == 'pull_request').length;
    final health = overview?.repositoryHealth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: scrollController,
          eyebrow: 'Repository analytics',
          title: 'See the bigger picture behind your development.',
          description:
              'Read the engineering signals available from GitHub for ${repository?.fullName ?? 'your selected repository'}. Each chart is bounded by the data and reporting window actually returned.',
        ),
        if (error != null)
          DashboardInlineNotice(
            message: overview == null
                ? 'Repository analytics could not be loaded: $error'
                : 'Showing the available analytics snapshot after a refresh error: $error',
            stale: overview != null,
          ),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 26,
                runSpacing: 20,
                children: [
                  DashboardMetric(
                    label: '8-week commits',
                    value: _weeklyValue(weekly, loading),
                    detail: weekly?.isComplete == true
                        ? 'Complete GitHub reporting window'
                        : 'Unavailable or incomplete',
                    color: dashboardBlue,
                  ),
                  DashboardMetric(
                    label: 'Open issues',
                    value: _value(health?.openIssues, loading),
                    detail: 'Repository summary',
                    color: const Color(0xFF15A578),
                  ),
                  DashboardMetric(
                    label: 'Open pull requests',
                    value: _value(
                      overview?.openPullRequests ?? health?.openPullRequests,
                      loading,
                    ),
                    detail: 'Repository summary',
                    color: const Color(0xFF7C3AED),
                  ),
                  DashboardMetric(
                    label: 'Resolved issues',
                    value: _value(
                      overview?.resolvedIssues30d ?? health?.closedIssues30d,
                      loading,
                    ),
                    detail: 'Last 30 days',
                    color: dashboardCyan,
                  ),
                ],
              ),
              const SizedBox(height: 52),
              DashboardScrollReveal(
                controller: scrollController,
                child: _WeeklyActivity(
                  weekly: weekly,
                  loading: loading,
                  error: error,
                ),
              ),
              const SizedBox(height: 54),
              LayoutBuilder(
                builder: (context, constraints) {
                  final languageSection = DashboardScrollReveal(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DashboardSectionHeading(
                          label: 'Composition',
                          title: 'Languages in the codebase',
                          description:
                              'Percentages are based on GitHub language byte totals.',
                        ),
                        const SizedBox(height: 20),
                        DashboardLanguageBars(languages: languages),
                      ],
                    ),
                  );
                  final activitySection = DashboardScrollReveal(
                    controller: scrollController,
                    child: _ActivityMix(
                      commitCount: commits,
                      issueCount: issues,
                      pullCount: pulls,
                      total: activity.length,
                    ),
                  );
                  if (constraints.maxWidth < 760) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        languageSection,
                        const SizedBox(height: 45),
                        activitySection,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: languageSection),
                      const SizedBox(width: 50),
                      Expanded(flex: 4, child: activitySection),
                    ],
                  );
                },
              ),
              const SizedBox(height: 54),
              const DashboardSectionHeading(
                label: 'Development history',
                title: 'Recent events, in context',
                description:
                    'A bounded sample of the most recently updated GitHub activity items.',
              ),
              const SizedBox(height: 18),
              if (activity.isEmpty)
                DashboardEmptyState(
                  icon: Icons.timeline_rounded,
                  title: loading
                      ? 'Loading repository activity'
                      : error != null
                      ? 'Repository activity unavailable'
                      : 'No activity is available',
                  description:
                      error ??
                      'Connect a repository or refresh its GitHub overview to see returned activity.',
                )
              else
                _RecentTimeline(
                  controller: scrollController,
                  activity: activity,
                ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: dashboardCyan, width: 3),
                  ),
                  color: const Color(0xFFEAF9FD),
                ),
                child: Text(
                  overview?.isStale == true
                      ? 'This overview is marked stale. Refresh the repository to request updated GitHub data; these trends remain a snapshot, not a live stream.'
                      : 'Analytics are limited to the currently available GitHub overview. No extrapolated history or synthetic activity is plotted.',
                  style: dashboardTextStyle(
                    color: dashboardNavy,
                    size: 11,
                    height: 1.65,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyActivity extends StatelessWidget {
  const _WeeklyActivity({
    required this.weekly,
    required this.loading,
    required this.error,
  });

  final GitHubWeeklyActivity? weekly;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final complete =
        weekly != null &&
        weekly!.availability == 'available' &&
        weekly!.isComplete &&
        weekly!.weeks.isNotEmpty &&
        weekly!.weeks.every((week) => week.commits != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeading(
          label: 'Weekly activity',
          title: 'A measured rhythm, week by week',
          description: complete
              ? 'Commits on ${weekly!.branch ?? 'the reported branch'} · ${weekly!.weekBoundary}.'
              : 'The chart is shown only when GitHub reports a complete period.',
        ),
        const SizedBox(height: 20),
        if (complete)
          _WeeklyCommitChart(weekly: weekly!)
        else
          DashboardEmptyState(
            icon: Icons.show_chart_rounded,
            title: loading
                ? 'Loading weekly activity'
                : error != null
                ? 'Weekly activity unavailable'
                : 'Activity not measured',
            description:
                error ??
                (weekly == null
                    ? 'Weekly commit data is not present in the repository overview.'
                    : 'Weekly activity is ${weekly!.availability} and ${weekly!.isComplete ? 'complete flag is set but data is missing' : 'incomplete'}; no partial chart is presented. Reporting period: ${_date(weekly!.periodStart)} to ${_date(weekly!.periodEnd)}.'),
          ),
      ],
    );
  }
}

class _WeeklyCommitChart extends StatelessWidget {
  const _WeeklyCommitChart({required this.weekly});

  final GitHubWeeklyActivity weekly;

  @override
  Widget build(BuildContext context) {
    final maxValue = weekly.weeks
        .map((week) => week.commits ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dashboardRule, width: 1.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (index, week) in weekly.weeks.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${week.commits}',
                            style: dashboardTextStyle(
                              color: dashboardMuted,
                              size: 9,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: maxValue == 0
                                  ? 0
                                  : (week.commits ?? 0) / maxValue,
                            ),
                            duration: Duration(milliseconds: 650 + 55 * index),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Container(
                              height: 120 * value + (week.commits == 0 ? 2 : 0),
                              decoration: BoxDecoration(
                                color: index == weekly.weeks.length - 1
                                    ? dashboardCyan
                                    : dashboardBlue.withValues(alpha: .75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final week in weekly.weeks)
                Expanded(
                  child: Text(
                    _date(week.weekStart),
                    textAlign: TextAlign.center,
                    style: dashboardTextStyle(color: dashboardMuted, size: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${weekly.totalCommits} total commits · ${_date(weekly.periodStart)} – ${_date(weekly.periodEnd)}',
              style: dashboardTextStyle(
                color: dashboardMuted,
                size: 10,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMix extends StatelessWidget {
  const _ActivityMix({
    required this.commitCount,
    required this.issueCount,
    required this.pullCount,
    required this.total,
  });

  final int commitCount;
  final int issueCount;
  final int pullCount;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const DashboardSectionHeading(
        label: 'Recent sample',
        title: 'Activity mix',
        description:
            'Counts in this compact view describe returned records only.',
      ),
      const SizedBox(height: 20),
      _MixLine('Commits', commitCount, total, dashboardBlue),
      _MixLine('Issues', issueCount, total, const Color(0xFF15A578)),
      _MixLine('Pull requests', pullCount, total, const Color(0xFF7C3AED)),
    ],
  );
}

class _MixLine extends StatelessWidget {
  const _MixLine(this.label, this.value, this.total, this.color);

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 19),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: dashboardTextStyle(size: 11, weight: FontWeight.w700),
              ),
            ),
            Text('$value / $total', style: dashboardTextStyle(size: 10)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total == 0 ? 0 : value / total,
          minHeight: 5,
          borderRadius: BorderRadius.circular(4),
          color: color,
          backgroundColor: dashboardPaleBlue,
        ),
      ],
    ),
  );
}

class _RecentTimeline extends StatelessWidget {
  const _RecentTimeline({required this.controller, required this.activity});

  final ScrollController controller;
  final List<GitHubActivity> activity;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (index, item) in activity.indexed)
        DashboardScrollReveal(
          controller: controller,
          delay: Duration(milliseconds: 40 * index),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: dashboardRule)),
            ),
            child: DashboardDataRow(
              leading: Icon(switch (item.type) {
                'commit' => Icons.commit_rounded,
                'issue' => Icons.bug_report_outlined,
                _ => Icons.merge_rounded,
              }),
              title: item.title,
              detail: '${item.type} · ${item.author} · ${_date(item.date)}',
            ),
          ),
        ),
    ],
  );
}

String _weeklyValue(GitHubWeeklyActivity? weekly, bool loading) {
  if (loading) return '…';
  if (weekly == null ||
      weekly.availability != 'available' ||
      !weekly.isComplete ||
      weekly.totalCommits == null) {
    return '—';
  }
  return '${weekly.totalCommits}';
}

String _value(int? value, bool loading) =>
    loading ? '…' : value?.toString() ?? '—';

String _date(DateTime? date) {
  if (date == null) return 'unavailable';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
