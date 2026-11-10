part of '../widgets/manager_workspace_pages.dart';

class ManagerReportsView extends StatelessWidget {
  const ManagerReportsView({super.key, required this.data});

  final ManagerWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final repo = data.overview?.connection ?? data.repository;
    final health = data.overview?.repositoryHealth;
    final quality = data.overview?.qualitySignals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: data.scrollController,
          eyebrow: 'Project reporting',
          title: 'A clear snapshot for the conversation.',
          description:
              'This report preview summarizes data already available in the workspace. It does not create or download a PDF or CSV.',
        ),
        _ConnectionError(data: data),
        if (repo == null)
          DashboardEmptyState(
            icon: Icons.description_outlined,
            title: data.loading
                ? 'Loading project snapshot'
                : 'No project to report on',
            description:
                data.error ??
                'Connect a repository to assemble a report preview from actual GitHub signals.',
            action: data.loading
                ? null
                : FilledButton.icon(
                    onPressed: data.onConnectRepository,
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Connect repository'),
                  ),
          )
        else ...[
          _ReportBrief(
            label: 'Engineering snapshot',
            title: repo.fullName,
            body: repo.description?.trim().isNotEmpty == true
                ? repo.description!
                : 'No repository description is available.',
            rows: [
              ('Default branch', repo.defaultBranch ?? 'Unavailable'),
              ('Primary language', repo.primaryLanguage ?? 'Unavailable'),
              (
                'Last GitHub update',
                _dateOrUnavailable(repo.repositoryUpdatedAt),
              ),
              ('Last DevInsight sync', _dateOrUnavailable(repo.lastSyncedAt)),
              (
                'Data freshness',
                data.overview?.isStale == true
                    ? 'Cached / stale'
                    : 'Current snapshot',
              ),
            ],
          ),
          const SizedBox(height: 28),
          _ReportBrief(
            label: 'Issues & pull requests',
            title: 'Repository work signals',
            body:
                'Counts are taken from the repository overview; activity entries below may represent a bounded sample.',
            rows: [
              (
                'Open issues',
                _value(health?.openIssues, loading: data.loading),
              ),
              (
                'Open pull requests',
                _value(
                  data.overview?.openPullRequests ?? health?.openPullRequests,
                  loading: data.loading,
                ),
              ),
              (
                'Resolved issues · 30 days',
                _value(
                  data.overview?.resolvedIssues30d ?? health?.closedIssues30d,
                  loading: data.loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _ReportBrief(
            label: 'Quality & collaboration signals',
            title: 'What is observable today',
            body:
                'A compact summary of available repository signals, not an assessment of project quality or individual performance.',
            rows: [
              (
                'CI/CD',
                quality?.ci.availability == 'available'
                    ? quality!.ci.state
                    : 'Unavailable',
              ),
              (
                'Recent activity entries',
                _value(
                  data.overview?.recentActivity.length,
                  loading: data.loading,
                ),
              ),
              (
                'Languages reported',
                _value(data.overview?.languages.length, loading: data.loading),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _UpcomingBand(
            title: 'Export generation is not connected.',
            description:
                'The workspace can preview available repository data, but has no supported PDF or CSV export endpoint. Report history is not fabricated.',
            badge: 'REPORT GENERATION · ROADMAP',
            icon: Icons.file_download_outlined,
          ),
        ],
        const SizedBox(height: 42),
        const DashboardSectionHeading(
          label: 'Research roadmap',
          title: 'Build on measured evidence.',
          description:
              'Risk prediction, priority recommendations, and delivery forecasts remain planned research features and are not represented as current findings.',
        ),
      ],
    );
  }
}
