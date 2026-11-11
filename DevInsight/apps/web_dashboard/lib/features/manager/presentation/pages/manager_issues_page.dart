part of '../widgets/manager_workspace_pages.dart';

class ManagerIssuesView extends StatefulWidget {
  const ManagerIssuesView({super.key, required this.data});

  final ManagerWorkspaceData data;

  @override
  State<ManagerIssuesView> createState() => _ManagerIssuesViewState();
}

class _ManagerIssuesViewState extends State<ManagerIssuesView> {
  final _search = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allIssues =
        widget.data.overview?.recentActivity
            .where((activity) => activity.type == 'issue')
            .toList() ??
        const <GitHubActivity>[];
    final query = _search.text.trim().toLowerCase();
    final issues = allIssues.where((issue) {
      final matchesState =
          _filter == 'All' ||
          issue.state?.toLowerCase() == _filter.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          issue.title.toLowerCase().contains(query) ||
          issue.author.toLowerCase().contains(query) ||
          '${issue.number ?? ''}'.contains(query) ||
          issue.labels.any((label) => label.toLowerCase().contains(query));
      return matchesState && matchesQuery;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeading(
          label: 'Issues & priorities',
          title: 'Make the next review count.',
          description:
              'Explore the recent issue sample from the selected repository. Issue prioritization is a future research capability; no AI score is generated here.',
        ),
        const SizedBox(height: 34),
        const DashboardSectionHeading(
          label: 'Issue review workflow',
          title: 'Reported. Triaged. Discussed.',
          description:
              'A conceptual team workflow only; stages are not inferred from GitHub issue state.',
        ),
        const SizedBox(height: 18),
        DashboardAnimatedWorkflow(
          controller: widget.data.scrollController,
          stages: const [
            'Reported',
            'Triage',
            'Review',
            'Decision',
            'Resolution',
          ],
          accent: const Color(0xFF15A578),
        ),
        const SizedBox(height: 42),
        const DashboardSectionHeading(
          label: 'GitHub issue sample',
          title: 'Find the open question.',
          description:
              'Returned issue records include their GitHub state and metadata. The visible list may be a bounded sample, not the complete issue history.',
        ),
        const SizedBox(height: 14),
        _ConnectionError(data: widget.data),
        _IssueControls(
          controller: _search,
          filter: _filter,
          onQueryChanged: () => setState(() {}),
          onFilterChanged: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: 14),
        if (widget.data.loading && widget.data.overview == null)
          const LinearProgressIndicator(minHeight: 2)
        else if (issues.isEmpty)
          DashboardEmptyState(
            icon: Icons.inbox_outlined,
            title: widget.data.repository == null
                ? 'Connect a repository to review issues'
                : allIssues.isEmpty
                ? 'No issues in the returned activity sample'
                : 'No issues match this search',
            description: widget.data.repository == null
                ? 'Connect or select a repository to load actual GitHub issue records.'
                : 'This does not necessarily mean the repository has no other issues; the current overview returns a bounded recent sample.',
            action: widget.data.repository == null
                ? FilledButton.icon(
                    onPressed: widget.data.onConnectRepository,
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Connect repository'),
                  )
                : null,
          )
        else
          for (final issue in issues)
            _IssueRow(
              issue: issue,
              onOpen: issue.url.isEmpty
                  ? null
                  : () => widget.data.onOpenLink(issue.url),
            ),
        const SizedBox(height: 50),
        _UpcomingBand(
          title: 'Issue prioritization is planned, not active.',
          description:
              'The future engine is intended to combine researched defect risk, issue severity, project context, business impact, deadlines, and available development information. No score or recommendation is produced by this prototype.',
          badge: 'RESEARCH ROADMAP · UPCOMING',
          icon: Icons.tune_rounded,
        ),
      ],
    );
  }
}
