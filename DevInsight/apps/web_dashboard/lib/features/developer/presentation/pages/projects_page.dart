import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({
    super.key,
    required this.scrollController,
    required this.profile,
    required this.repositories,
    required this.repository,
    required this.overview,
    required this.loading,
    required this.error,
    required this.onConnect,
    required this.onSelect,
    required this.onManage,
    required this.onRefresh,
    required this.onOpenRepository,
  });

  final ScrollController scrollController;
  final CurrentUserProfile profile;
  final List<GitHubRepositoryConnection> repositories;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final bool loading;
  final String? error;
  final VoidCallback onConnect;
  final ValueChanged<GitHubRepositoryConnection> onSelect;
  final VoidCallback onManage;
  final VoidCallback onRefresh;
  final ValueChanged<String> onOpenRepository;

  @override
  Widget build(BuildContext context) {
    final active = overview?.connection ?? repository;
    final name = profile.fullName?.trim();
    final greeting = name == null || name.isEmpty
        ? 'your workspace'
        : '$name’s workspace';
    final languages =
        overview?.languages
            .map(
              (language) =>
                  (name: language.name, percentage: language.percentage),
            )
            .toList() ??
        const <({String name, double percentage})>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: scrollController,
          eyebrow: 'Repository workspace',
          title: 'Your projects. One connected workspace.',
          description:
              'Keep every connected repository within reach. Select a project to make its verified GitHub signals the shared context across DevInsight for $greeting.',
          trailing: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Manage'),
              ),
              FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Connect repository'),
              ),
            ],
          ),
        ),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardScrollReveal(
                controller: scrollController,
                child: _ActiveProjectBanner(
                  repository: active,
                  overview: overview,
                  loading: loading,
                  error: error,
                  onRefresh: onRefresh,
                  onOpen: active == null
                      ? null
                      : () => onOpenRepository(active.url),
                ),
              ),
              const SizedBox(height: 52),
              Row(
                children: [
                  const Expanded(
                    child: DashboardSectionHeading(
                      label: 'Connected ecosystem',
                      title: 'Repositories in your workspace',
                      description:
                          'Choose an existing connection to update the active project context.',
                    ),
                  ),
                  Text(
                    '${repositories.length} connected',
                    style: dashboardTextStyle(
                      color: dashboardMuted,
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (repositories.isEmpty)
                DashboardEmptyState(
                  icon: Icons.account_tree_outlined,
                  title: loading
                      ? 'Loading repositories'
                      : 'Your project list is empty',
                  description:
                      error ??
                      'Connect a public GitHub repository to start this workspace. No sample projects are shown.',
                  action: loading
                      ? const SizedBox(
                          width: 180,
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      : FilledButton.icon(
                          onPressed: onConnect,
                          icon: const Icon(Icons.add_link_rounded),
                          label: const Text('Connect a repository'),
                        ),
                )
              else
                for (final (index, item) in repositories.indexed)
                  _RepositoryRow(
                    controller: scrollController,
                    repository: item,
                    active: item.id == repository?.id,
                    index: index,
                    onSelect: () => onSelect(item),
                    onOpen: () => onOpenRepository(item.url),
                  ),
              const SizedBox(height: 54),
              const DashboardSectionHeading(
                label: 'Project connections',
                title: 'A living map of your codebase',
                description:
                    'Each repository connection brings its language profile, activity, and engineering signals into one workspace.',
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: dashboardRule),
                    bottom: BorderSide(color: dashboardRule),
                  ),
                ),
                child: DashboardAnimatedWorkflow(
                  controller: scrollController,
                  stages: const [
                    'Repositories',
                    'Activity',
                    'Signals',
                    'Workspace',
                  ],
                  accent: dashboardAzure,
                ),
              ),
              if (active != null) ...[
                const SizedBox(height: 38),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 720) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DashboardSectionHeading(
                            title: 'Language footprint',
                            description:
                                'GitHub byte composition for the active repository.',
                          ),
                          const SizedBox(height: 18),
                          DashboardLanguageBars(languages: languages),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: DashboardSectionHeading(
                            title: 'Language footprint',
                            description:
                                'GitHub byte composition for the active repository.',
                          ),
                        ),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: constraints.maxWidth * .42,
                          child: DashboardLanguageBars(languages: languages),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveProjectBanner extends StatelessWidget {
  const _ActiveProjectBanner({
    required this.repository,
    required this.overview,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpen,
  });

  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final repo = repository;
    if (repo == null) {
      return DashboardEmptyState(
        icon: Icons.folder_open_rounded,
        title: loading ? 'Loading active project' : 'Choose your first project',
        description:
            error ??
            'No repository is active yet. Connect a public repository to begin.',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101B33), Color(0xFF18386D), Color(0xFF1655B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final details = Wrap(
            spacing: 22,
            runSpacing: 15,
            children: [
              _ProjectFact('OWNER', repo.owner),
              _ProjectFact('LANGUAGE', repo.primaryLanguage ?? 'Not available'),
              _ProjectFact('DEFAULT BRANCH', repo.defaultBranch ?? 'Unknown'),
              _ProjectFact('STARS', '${repo.stars}'),
              _ProjectFact('FORKS', '${repo.forks}'),
              _ProjectFact('LAST SYNC', _shortDate(repo.lastSyncedAt)),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_copy_rounded, color: dashboardCyan),
                  const SizedBox(width: 10),
                  Text(
                    'ACTIVE REPOSITORY',
                    style: dashboardTextStyle(
                      color: Colors.white70,
                      size: 10,
                      weight: FontWeight.w800,
                    ).copyWith(letterSpacing: 1.1),
                  ),
                  const Spacer(),
                  if (overview?.isStale == true)
                    const DashboardStatusTag(
                      'Cached data · stale',
                      color: Color(0xFFFFC857),
                    )
                  else
                    const DashboardStatusTag(
                      'Connected',
                      color: Color(0xFF59D6A5),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                repo.fullName,
                style: dashboardTextStyle(
                  color: Colors.white,
                  size: compact ? 25 : 32,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                repo.description?.trim().isNotEmpty == true
                    ? repo.description!
                    : 'No repository description provided.',
                style: dashboardTextStyle(
                  color: Colors.white70,
                  size: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              details,
              if (error != null) ...[
                const SizedBox(height: 18),
                Text(
                  '$error · showing the last available repository details',
                  style: dashboardTextStyle(
                    color: const Color(0xFFFFD88A),
                    size: 10,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh repository',
                    onPressed: loading ? null : onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white,
                  ),
                  if (onOpen != null)
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('View on GitHub'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectFact extends StatelessWidget {
  const _ProjectFact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: dashboardTextStyle(
            color: Colors.white54,
            size: 8,
            weight: FontWeight.w800,
          ).copyWith(letterSpacing: .7),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: dashboardTextStyle(
            color: Colors.white,
            size: 11,
            weight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _RepositoryRow extends StatelessWidget {
  const _RepositoryRow({
    required this.controller,
    required this.repository,
    required this.active,
    required this.index,
    required this.onSelect,
    required this.onOpen,
  });

  final ScrollController controller;
  final GitHubRepositoryConnection repository;
  final bool active;
  final int index;
  final VoidCallback onSelect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => DashboardScrollReveal(
    controller: controller,
    delay: Duration(milliseconds: 45 * index),
    child: Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: dashboardRule)),
      ),
      child: DashboardDataRow(
        leading: Icon(
          active ? Icons.check_circle_rounded : Icons.folder_outlined,
        ),
        title: repository.fullName,
        detail:
            '${repository.primaryLanguage ?? 'Language unavailable'}  ·  ${repository.stars} stars  ·  ${repository.forks} forks',
        color: active ? dashboardBlue : dashboardMuted,
        trailing: Wrap(
          spacing: 4,
          children: [
            if (active)
              const DashboardStatusTag('ACTIVE', color: dashboardBlue),
            IconButton(
              tooltip: 'View ${repository.fullName} on GitHub',
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
            ),
          ],
        ),
        onTap: onSelect,
      ),
    ),
  );
}

String _shortDate(DateTime? date) {
  if (date == null) return 'Not synchronized';
  return '${date.toLocal().year}-${date.toLocal().month.toString().padLeft(2, '0')}-${date.toLocal().day.toString().padLeft(2, '0')}';
}
