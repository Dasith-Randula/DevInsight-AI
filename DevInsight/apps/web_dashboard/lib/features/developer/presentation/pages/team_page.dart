import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({
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
    final activity = overview?.recentActivity ?? const <GitHubActivity>[];
    final people = <String>{
      for (final item in activity)
        if (item.author.trim().isNotEmpty &&
            item.author.toLowerCase() != 'unknown author')
          item.author,
    }.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: scrollController,
          eyebrow: 'Team collaboration',
          title: 'Great software is built together.',
          description:
              'Explore the collaboration signals visible in the selected repository. GitHub activity authors are shown as observed in the recent sample, not as a complete team roster or performance ranking.',
        ),
        if (error != null)
          DashboardInlineNotice(
            message: overview == null
                ? 'Team activity could not be loaded: $error'
                : 'Showing the available team activity snapshot after a refresh error: $error',
            stale: overview != null,
          ),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hub_rounded, color: dashboardBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            repository?.fullName ?? 'Team network',
                            style: dashboardTextStyle(
                              size: 18,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DashboardStatusTag(
                          '${people.length} observed authors',
                          color: dashboardBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DashboardContributorNetwork(
                      controller: scrollController,
                      repositoryName:
                          repository?.fullName ?? 'No repository selected',
                      contributors: people,
                    ),
                    Text(
                      people.isEmpty
                          ? 'No contributor nodes were returned in the current GitHub sample.'
                          : 'Contributor nodes come from observed recent activity authors; this is not a full contributor graph.',
                      style: dashboardTextStyle(color: dashboardMuted, size: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final contributors = _ObservedAuthors(
                    controller: scrollController,
                    authors: people,
                  );
                  final snapshot = _ActivitySnapshot(activity: activity);
                  if (constraints.maxWidth < 760) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        contributors,
                        const SizedBox(height: 44),
                        snapshot,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: contributors),
                      const SizedBox(width: 44),
                      Expanded(flex: 5, child: snapshot),
                    ],
                  );
                },
              ),
              const SizedBox(height: 52),
              const DashboardSectionHeading(
                label: 'Workload intelligence',
                title: 'Designed for sustainable collaboration',
                description:
                    'Personal ownership and workload predictions require identity linking and validated models that are not currently available.',
              ),
              const SizedBox(height: 16),
              const DashboardEmptyState(
                icon: Icons.balance_rounded,
                title: 'Workload insights are not active',
                description:
                    'No individual scores, workload estimates, or predictions are shown. Repository activity alone is not enough to infer a person’s contribution or capacity.',
              ),
              const SizedBox(height: 40),
              const DashboardSectionHeading(
                label: 'Contribution history',
                title: 'Recent shared activity',
                description:
                    'Recent repository events provide context without being treated as an exhaustive history.',
              ),
              const SizedBox(height: 14),
              for (final (index, item) in activity.take(8).indexed)
                DashboardScrollReveal(
                  controller: scrollController,
                  delay: Duration(milliseconds: 45 * index),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: dashboardRule)),
                    ),
                    child: DashboardDataRow(
                      leading: Icon(
                        item.type == 'commit'
                            ? Icons.commit_rounded
                            : item.type == 'issue'
                            ? Icons.bug_report_outlined
                            : Icons.merge_rounded,
                      ),
                      title: item.title,
                      detail:
                          '${item.author} · ${item.type} · ${_date(item.date)}',
                    ),
                  ),
                ),
              if (activity.isEmpty)
                const DashboardEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No contributor activity available',
                  description:
                      'Connect a repository or refresh its GitHub overview to inspect recent activity.',
                ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObservedAuthors extends StatelessWidget {
  const _ObservedAuthors({required this.controller, required this.authors});

  final ScrollController controller;
  final List<String> authors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DashboardSectionHeading(
        label: 'Observed contributors',
        title: authors.isEmpty
            ? 'No names in this sample'
            : 'People in recent activity',
        description:
            'Distinct GitHub author names found in the bounded activity response. This is not a full contributor list.',
      ),
      const SizedBox(height: 14),
      if (authors.isEmpty)
        const DashboardEmptyState(
          icon: Icons.person_outline_rounded,
          title: 'Contributor identities unavailable',
          description:
              'No author names were returned in the current activity sample.',
        )
      else
        for (final (index, author) in authors.indexed)
          DashboardScrollReveal(
            controller: controller,
            delay: Duration(milliseconds: 60 * index),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: dashboardRule)),
              ),
              child: DashboardDataRow(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: index.isEven
                      ? dashboardBlue.withValues(alpha: .1)
                      : const Color(0xFF14C8F5).withValues(alpha: .15),
                  child: Text(
                    author.characters.first.toUpperCase(),
                    style: dashboardTextStyle(
                      color: dashboardBlue,
                      size: 11,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                title: author,
                detail: 'Appears in recent GitHub activity',
              ),
            ),
          ),
    ],
  );
}

class _ActivitySnapshot extends StatelessWidget {
  const _ActivitySnapshot({required this.activity});

  final List<GitHubActivity> activity;

  @override
  Widget build(BuildContext context) {
    final commits = activity.where((item) => item.type == 'commit').length;
    final issues = activity.where((item) => item.type == 'issue').length;
    final pulls = activity.where((item) => item.type == 'pull_request').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeading(
          label: 'Collaboration snapshot',
          title: 'Events in the sample',
          description:
              'Counts below describe returned records, not total team output.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            DashboardMetric(
              label: 'Commits',
              value: '$commits',
              detail: 'recent sample',
              color: dashboardBlue,
            ),
            DashboardMetric(
              label: 'Issues',
              value: '$issues',
              detail: 'recent sample',
              color: const Color(0xFF15A578),
            ),
            DashboardMetric(
              label: 'Pull requests',
              value: '$pulls',
              detail: 'recent sample',
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ],
    );
  }
}

String _date(DateTime? date) {
  if (date == null) return 'date unavailable';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
