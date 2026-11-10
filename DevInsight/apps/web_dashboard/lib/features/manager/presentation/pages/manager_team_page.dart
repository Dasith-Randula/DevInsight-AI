part of '../widgets/manager_workspace_pages.dart';

class ManagerTeamView extends StatelessWidget {
  const ManagerTeamView({super.key, required this.data});

  final ManagerWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final activities =
        data.overview?.recentActivity ?? const <GitHubActivity>[];
    final contributors = activities
        .map((activity) => activity.author.trim())
        .where(
          (author) =>
              author.isNotEmpty && author.toLowerCase() != 'unknown author',
        )
        .toSet()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: data.scrollController,
          eyebrow: 'Team & collaboration',
          title: 'See the collaboration, not a score.',
          description:
              'This view reflects names observed in the available GitHub activity sample. It is not a verified organization roster or an assessment of individual performance.',
        ),
        _ConnectionError(data: data),
        if (contributors.isEmpty)
          DashboardEmptyState(
            icon: Icons.people_outline_rounded,
            title: data.repository == null
                ? 'Select a repository to see activity'
                : 'No contributor names in this sample',
            description:
                'Contributor names appear only when supplied in repository activity records. No team members or contribution scores are fabricated.',
            action: data.repository == null
                ? FilledButton.icon(
                    onPressed: data.onConnectRepository,
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Connect repository'),
                  )
                : null,
          )
        else ...[
          const DashboardSectionHeading(
            label: 'Observed contributors',
            title: 'People present in recent activity.',
            description:
                'Unique author names found in the returned issue and pull-request events for this repository.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: contributors
                .map((name) => _ContributorPill(name: name))
                .toList(),
          ),
          const SizedBox(height: 34),
          _ActivityList(
            title: 'Shared repository activity',
            description:
                'Recent activity signals are listed as returned, without interpreting them as workload or capacity.',
            activities: activities,
            loading: data.loading,
            repository: data.repository,
            onOpenLink: data.onOpenLink,
          ),
        ],
        const SizedBox(height: 50),
        _UpcomingBand(
          title: 'Workload intelligence needs better evidence.',
          description:
              'A future collaboration view will require validated data and careful interpretation. Commit counts alone are not a measure of productivity, performance, or capacity.',
          badge: 'WORKLOAD INTELLIGENCE · UPCOMING',
          icon: Icons.groups_2_outlined,
        ),
      ],
    );
  }
}
