part of '../widgets/manager_workspace_pages.dart';

class ManagerAnalyticsView extends StatelessWidget {
  const ManagerAnalyticsView({super.key, required this.data});

  final ManagerWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final overview = data.overview;
    final health = overview?.repositoryHealth;
    final weekly = overview?.weeklyActivity;
    final quality = overview?.qualitySignals;
    final knownWeeks =
        weekly?.weeks.where((week) => week.commits != null).toList() ??
        const <GitHubWeeklyCommit>[];
    final maxCommits = knownWeeks.isEmpty
        ? 0
        : knownWeeks
              .map((week) => week.commits!)
              .reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: data.scrollController,
          eyebrow: 'Project analytics',
          title: 'Evidence for the next decision.',
          description:
              'A summary of measured GitHub signals from the active repository. No missing history is filled with synthetic values.',
        ),
        _ConnectionError(data: data),
        Wrap(
          spacing: 30,
          runSpacing: 22,
          children: [
            DashboardMetric(
              label: 'Open issues',
              value: _value(health?.openIssues, loading: data.loading),
              detail: 'GitHub repository summary',
              color: const Color(0xFF15A578),
            ),
            DashboardMetric(
              label: 'Open pull requests',
              value: _value(
                overview?.openPullRequests ?? health?.openPullRequests,
                loading: data.loading,
              ),
              detail: 'GitHub repository summary',
              color: dashboardAzure,
            ),
            DashboardMetric(
              label: 'Contributors seen',
              value: _value(
                overview?.recentActivity
                    .map((activity) => activity.author)
                    .where((author) => author.trim().isNotEmpty)
                    .toSet()
                    .length,
                loading: data.loading,
              ),
              detail: 'Unique authors in sample',
              color: const Color(0xFF8A65D6),
            ),
          ],
        ),
        const SizedBox(height: 46),
        const DashboardSectionHeading(
          label: 'Repository activity',
          title: 'Weekly commits, when available.',
          description:
              'Bars use only the weekly activity records returned by the repository overview; the time window and completeness come from the API.',
        ),
        const SizedBox(height: 16),
        if (weekly == null ||
            weekly.availability != 'available' ||
            knownWeeks.isEmpty)
          DashboardEmptyState(
            icon: Icons.show_chart_rounded,
            title: data.loading
                ? 'Loading activity history'
                : 'Weekly activity is not available',
            description: weekly?.availability == 'unavailable'
                ? 'GitHub did not provide weekly activity for this snapshot. No trend line is estimated.'
                : 'Connect a repository or refresh later to check for a measured activity window.',
          )
        else ...[
          _WeeklyActivityChart(
            weeks: knownWeeks,
            maximum: maxCommits,
            complete: weekly.isComplete,
          ),
          const SizedBox(height: 10),
          Text(
            '${weekly.totalCommits == null ? 'Total unavailable' : '${weekly.totalCommits} commits'} · ${weekly.branch?.isNotEmpty == true ? weekly.branch : 'default branch'} · ${weekly.periodStart == null || weekly.periodEnd == null ? 'Time window unavailable' : '${_date(weekly.periodStart)} – ${_date(weekly.periodEnd)}'}',
            style: dashboardTextStyle(
              color: context.appTheme.mutedText,
              size: 10,
            ),
          ),
          if (!weekly.isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'This activity window is incomplete; read the visible weeks as a partial snapshot.',
                style: dashboardTextStyle(
                  color: context.appTheme.mutedText,
                  size: 10,
                ),
              ),
            ),
        ],
        const SizedBox(height: 42),
        const DashboardSectionHeading(
          label: 'Quality configuration',
          title: 'Configuration signals, not a quality score.',
          description:
              'CI/CD state and repository setup indicators are shown only when the GitHub overview reports them.',
        ),
        const SizedBox(height: 16),
        _AnalyticsSignals(
          quality: quality,
          health: health,
          loading: data.loading,
        ),
        const SizedBox(height: 44),
        _ActivityList(
          title: 'Recent engineering events',
          description:
              'Recent commits, issues, and pull requests returned in the current activity window.',
          activities: overview?.recentActivity ?? const [],
          loading: data.loading,
          repository: data.repository,
          onOpenLink: data.onOpenLink,
        ),
        const SizedBox(height: 44),
        _UpcomingBand(
          title: 'Risk trends require the research models.',
          description:
              'Project risk predictions and delivery forecasts are planned research work. This page does not estimate risk or future delivery.',
          badge: 'PLANNED RESEARCH',
          icon: Icons.auto_graph_rounded,
        ),
      ],
    );
  }
}
