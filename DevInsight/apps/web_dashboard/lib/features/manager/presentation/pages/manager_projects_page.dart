part of '../widgets/manager_workspace_pages.dart';

class ManagerProjectsView extends StatelessWidget {
  const ManagerProjectsView({super.key, required this.data});

  final ManagerWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final active = data.overview?.connection ?? data.repository;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: data.scrollController,
          eyebrow: 'Project portfolio',
          title: 'Every connected repository, in view.',
          description:
              'Select a repository to set the active project context across this Manager workspace. Details and comparisons use only returned GitHub data.',
        ),
        _ConnectionError(data: data),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: data.loading ? null : data.onConnectRepository,
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Connect repository'),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: DashboardSectionHeading(
                label: 'Active project',
                title: 'Choose a repository.',
                description:
                    'This selection is saved for your account on this browser and reused by every Manager section.',
              ),
            ),
            if (active != null)
              IconButton(
                onPressed: data.refreshing ? null : data.onRefresh,
                tooltip: 'Refresh repository',
                icon: data.refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (data.repositories.isEmpty)
          DashboardEmptyState(
            icon: Icons.folder_open_rounded,
            title: data.loading
                ? 'Loading connected repositories'
                : 'No repositories connected',
            description:
                data.error ??
                'Connect a public GitHub repository to start a shared project workspace. No sample projects are shown.',
          )
        else
          for (final (index, repository) in data.repositories.indexed)
            _ProjectPortfolioRow(
              repository: repository,
              active: repository.id == active?.id,
              index: index,
              onSelect: () => data.onSelectRepository(repository),
              onOpen: () => data.onOpenLink(repository.url),
            ),
        if (active != null) ...[
          const SizedBox(height: 46),
          const DashboardSectionHeading(
            label: 'Repository overview',
            title: 'A practical project brief.',
            description:
                'Repository metadata is provided by GitHub. Sync freshness is shown separately from repository update time.',
          ),
          const SizedBox(height: 16),
          _RepositorySnapshot(
            data: data,
            repository: active,
            overview: data.overview,
          ),
          const SizedBox(height: 32),
          _LanguageComposition(languages: data.overview?.languages ?? const []),
        ],
      ],
    );
  }
}
