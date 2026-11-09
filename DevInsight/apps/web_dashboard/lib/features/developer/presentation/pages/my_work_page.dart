import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

class MyWorkPage extends StatelessWidget {
  const MyWorkPage({
    super.key,
    required this.scrollController,
    required this.profile,
    required this.repository,
    required this.overview,
    required this.error,
    required this.onOpenRepository,
  });

  final ScrollController scrollController;
  final CurrentUserProfile profile;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final String? error;
  final ValueChanged<String> onOpenRepository;

  @override
  Widget build(BuildContext context) {
    final commits =
        overview?.recentActivity
            .where((activity) => activity.type == 'commit')
            .toList() ??
        const <GitHubActivity>[];
    final displayName = profile.fullName?.trim().isNotEmpty == true
        ? profile.fullName!.trim()
        : 'Developer';
    final weekly = overview?.weeklyActivity;
    final weeklyValue =
        weekly != null &&
            weekly.availability == 'available' &&
            weekly.isComplete &&
            weekly.totalCommits != null
        ? '${weekly.totalCommits}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: scrollController,
          eyebrow: 'Personal workspace',
          title: 'Stay focused on what matters.',
          description:
              'A grounded view of your work begins with a verified GitHub identity. Until identity linking is available, personal assignments stay separate from repository-wide activity.',
        ),
        if (error != null)
          DashboardInlineNotice(
            message: overview == null
                ? 'Repository data could not be refreshed: $error'
                : 'Showing the available repository snapshot after a refresh error: $error',
            stale: overview != null,
          ),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 18,
                children: [
                  DashboardMetric(
                    label: 'Assigned issues',
                    value: 'Not linked',
                    detail: 'Personal identity unavailable',
                    color: const Color(0xFF7C3AED),
                  ),
                  DashboardMetric(
                    label: 'Your pull requests',
                    value: 'Not linked',
                    detail: 'Ownership not verified',
                    color: dashboardAzure,
                  ),
                  DashboardMetric(
                    label: 'Repository commits',
                    value: weeklyValue,
                    detail: weekly != null && !weekly.isComplete
                        ? 'Weekly reporting incomplete'
                        : 'Repository-wide · 8 weeks',
                    color: dashboardCyan,
                  ),
                ],
              ),
              const SizedBox(height: 46),
              _IdentityPanel(name: displayName),
              const SizedBox(height: 30),
              const DashboardSectionHeading(
                label: 'Assigned GitHub issues',
                title: 'Your issue queue',
                description:
                    'Personal issue assignment requires a verified GitHub identity link.',
              ),
              const SizedBox(height: 12),
              const DashboardEmptyState(
                icon: Icons.assignment_ind_outlined,
                title: 'Assignments unavailable',
                description:
                    'The current account does not expose a linked GitHub identity, so repository issues are not presented as your assignments.',
              ),
              const SizedBox(height: 30),
              const DashboardSectionHeading(
                label: 'Pull requests involving you',
                title: 'Your review and PR activity',
                description:
                    'PR ownership and review participation cannot be verified from repository-wide activity alone.',
              ),
              const SizedBox(height: 12),
              const DashboardEmptyState(
                icon: Icons.merge_rounded,
                title: 'Personal pull requests unavailable',
                description:
                    'Connect a verified GitHub identity when identity linking is supported to see your own pull requests and reviews.',
              ),
              const SizedBox(height: 52),
              const DashboardSectionHeading(
                label: 'Developer workflow',
                title: 'From a clear next step to a thoughtful review',
                description:
                    'This workflow illustration is a guide, not a record of completed personal tasks.',
              ),
              const SizedBox(height: 20),
              DashboardAnimatedWorkflow(
                controller: scrollController,
                stages: const [
                  'Choose focus',
                  'Make progress',
                  'Review changes',
                  'Share work',
                ],
                accent: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 52),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 760;
                  final activity = _RepositoryActivity(
                    controller: scrollController,
                    repository: repository,
                    commits: commits,
                    onOpenRepository: onOpenRepository,
                  );
                  final upcoming = const _UpcomingWork();
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        activity,
                        const SizedBox(height: 42),
                        upcoming,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: activity),
                      const SizedBox(width: 48),
                      Expanded(flex: 2, child: upcoming),
                    ],
                  );
                },
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F0FF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7DFFF)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.person_search_rounded,
          color: Color(0xFF7C3AED),
          size: 25,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal activity is not connected yet',
                style: dashboardTextStyle(weight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                '$name is signed in to DevInsight, but a verified GitHub identity link is not available. Assigned issues and PR ownership are intentionally not inferred from repository-wide activity.',
                style: dashboardTextStyle(
                  color: dashboardMuted,
                  size: 11,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const DashboardStatusTag('IDENTITY UNLINKED', color: Color(0xFF7C3AED)),
      ],
    ),
  );
}

class _RepositoryActivity extends StatelessWidget {
  const _RepositoryActivity({
    required this.controller,
    required this.repository,
    required this.commits,
    required this.onOpenRepository,
  });

  final ScrollController controller;
  final GitHubRepositoryConnection? repository;
  final List<GitHubActivity> commits;
  final ValueChanged<String> onOpenRepository;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DashboardSectionHeading(
        label: 'Separate repository activity',
        title: repository?.fullName ?? 'Recent contributions',
        description:
            'Recent commits are repository-wide, not attributed as your personal work.',
      ),
      const SizedBox(height: 16),
      if (commits.isEmpty)
        const DashboardEmptyState(
          icon: Icons.timeline_rounded,
          title: 'No recent commits in the available summary',
          description:
              'Commit history is bounded by the current GitHub overview response.',
        )
      else
        for (final (index, commit) in commits.indexed)
          DashboardScrollReveal(
            controller: controller,
            delay: Duration(milliseconds: 55 * index),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: dashboardRule)),
              ),
              child: DashboardDataRow(
                leading: const Icon(Icons.commit_rounded),
                title: commit.title,
                detail:
                    '${commit.author} · ${_formatDate(commit.createdAt ?? commit.date)}',
                trailing: IconButton(
                  tooltip: 'Open repository activity on GitHub',
                  onPressed: repository == null
                      ? null
                      : () => onOpenRepository(repository!.url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                ),
              ),
            ),
          ),
    ],
  );
}

class _UpcomingWork extends StatelessWidget {
  const _UpcomingWork();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      DashboardSectionHeading(
        label: 'Looking ahead',
        title: 'Upcoming work',
        description:
            'No personal task schedule is available until GitHub identity and assignment data are linked.',
      ),
      SizedBox(height: 16),
      DashboardEmptyState(
        icon: Icons.event_note_rounded,
        title: 'Nothing scheduled',
        description:
            'This is an unavailable personal schedule, not an indication that the repository has no open work.',
      ),
    ],
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Date unavailable';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
