import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

enum _IssueFilter { all, open, closed }

class IssuesPage extends StatefulWidget {
  const IssuesPage({
    super.key,
    required this.scrollController,
    required this.repository,
    required this.overview,
    required this.loading,
    required this.error,
    required this.onOpenLink,
  });

  final ScrollController scrollController;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final bool loading;
  final String? error;
  final ValueChanged<String> onOpenLink;

  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  final _searchController = TextEditingController();
  _IssueFilter _filter = _IssueFilter.all;
  GitHubActivity? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allIssues =
        widget.overview?.recentActivity
            .where((activity) => activity.type == 'issue')
            .toList() ??
        const <GitHubActivity>[];
    final openIssues = allIssues
        .where((issue) => issue.state == 'open')
        .toList();
    final closedIssues = allIssues
        .where((issue) => issue.state == 'closed')
        .toList();
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allIssues.where((issue) {
      final matchesState = switch (_filter) {
        _IssueFilter.all => true,
        _IssueFilter.open => issue.state == 'open',
        _IssueFilter.closed => issue.state == 'closed',
      };
      final matchesSearch =
          query.isEmpty ||
          issue.title.toLowerCase().contains(query) ||
          issue.author.toLowerCase().contains(query) ||
          '${issue.number ?? ''}'.contains(query) ||
          issue.labels.any((label) => label.toLowerCase().contains(query));
      return matchesState && matchesSearch;
    }).toList();
    final selected = filtered.contains(_selected)
        ? _selected
        : filtered.isEmpty
        ? null
        : filtered.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: widget.scrollController,
          eyebrow: 'Issue intelligence',
          title: 'Find the issues that matter.',
          description:
              'Explore the bounded set of recent GitHub issues returned by the connected repository. Pull requests are excluded from issue counts and results.',
        ),
        if (widget.error != null)
          DashboardInlineNotice(
            message: widget.overview == null
                ? 'Issue data could not be loaded: ${widget.error}'
                : 'Showing the available issue snapshot after a refresh error: ${widget.error}',
            stale: widget.overview != null,
          ),
        DashboardScrollReveal(
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 26,
                runSpacing: 20,
                children: [
                  DashboardMetric(
                    label: 'Open issues',
                    value: _count(
                      widget.overview?.repositoryHealth?.openIssues,
                      loading: widget.loading,
                    ),
                    detail: 'GitHub repository summary',
                    color: const Color(0xFF15A578),
                  ),
                  DashboardMetric(
                    label: 'Closed · 30 days',
                    value: _count(
                      widget.overview?.resolvedIssues30d ??
                          widget.overview?.repositoryHealth?.closedIssues30d,
                      loading: widget.loading,
                    ),
                    detail: 'Recently resolved',
                    color: dashboardAzure,
                  ),
                  DashboardMetric(
                    label: 'In recent list',
                    value: '${allIssues.length}',
                    detail: 'Bounded GitHub activity sample',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 38),
              DashboardScrollReveal(
                controller: widget.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardSectionHeading(
                      label: 'Issue lifecycle',
                      title: 'From discovery to resolution',
                      description:
                          'A lightweight guide to issue triage; stage completion is not inferred from issue counts.',
                    ),
                    const SizedBox(height: 14),
                    DashboardAnimatedWorkflow(
                      controller: widget.scrollController,
                      stages: const [
                        'Report',
                        'Triage',
                        'In progress',
                        'Resolved',
                      ],
                      accent: const Color(0xFF15A578),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.appTheme.surfaceElevated.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? .92
                        : .72,
                  ),
                  border: Border.all(color: context.appTheme.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 650;
                        final search = TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search title, number, author, label',
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        final filters = Wrap(
                          spacing: 7,
                          children: [
                            for (final (filter, label) in [
                              (_IssueFilter.all, 'All'),
                              (_IssueFilter.open, 'Open'),
                              (_IssueFilter.closed, 'Closed'),
                            ])
                              ChoiceChip(
                                label: Text(label),
                                selected: _filter == filter,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                              ),
                          ],
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              search,
                              const SizedBox(height: 12),
                              filters,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: search),
                            const SizedBox(width: 14),
                            filters,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Showing ${filtered.length} of ${allIssues.length} issues in the recent activity sample',
                        style: dashboardTextStyle(
                          color: dashboardMuted,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (widget.repository == null || widget.overview == null) {
                    return DashboardEmptyState(
                      icon: Icons.bug_report_outlined,
                      title: widget.loading
                          ? 'Loading issue data'
                          : widget.repository == null
                          ? 'Connect a repository to explore issues'
                          : widget.error != null
                          ? 'Issue data unavailable'
                          : 'Issue summary is not available',
                      description:
                          widget.error ??
                          'Issue rows are drawn from real GitHub repository data. No sample records are inserted.',
                    );
                  }
                  if (allIssues.isEmpty) {
                    return const DashboardEmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No issues in the recent activity sample',
                      description:
                          'The recent GitHub activity list contains no issue records. This does not imply the complete repository has no issues.',
                    );
                  }
                  final explorer = _IssueList(
                    controller: widget.scrollController,
                    issues: filtered,
                    selected: selected,
                    onSelect: (issue) => setState(() => _selected = issue),
                  );
                  final detail = selected == null
                      ? const DashboardEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching issues',
                          description:
                              'Change the search or status filter to see other available records.',
                        )
                      : _IssueDetail(
                          issue: selected,
                          repository: widget.repository!,
                          onOpen: () => widget.onOpenLink(selected.url),
                        );
                  if (constraints.maxWidth < 850) {
                    return Column(
                      children: [explorer, const SizedBox(height: 20), detail],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: explorer),
                      const SizedBox(width: 26),
                      Expanded(flex: 4, child: detail),
                    ],
                  );
                },
              ),
              const SizedBox(height: 42),
              const DashboardSectionHeading(
                label: 'Activity summary',
                title: 'A practical signal, not the whole story',
                description:
                    'Summary counts and the recent issue sample come from the selected repository overview. The detailed list is intentionally bounded by the current API response.',
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 30,
                runSpacing: 14,
                children: [
                  DashboardMetric(
                    label: 'Open in sample',
                    value: '${openIssues.length}',
                    detail: 'Recent returned records',
                  ),
                  DashboardMetric(
                    label: 'Closed in sample',
                    value: '${closedIssues.length}',
                    detail: 'Recent returned records',
                    color: const Color(0xFF15A578),
                  ),
                  DashboardMetric(
                    label: 'Repository',
                    value: widget.repository?.fullName ?? 'Not connected',
                    detail: widget.overview?.isStale == true
                        ? 'Cached summary may be stale'
                        : 'Selected GitHub project',
                    color: dashboardCyan,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({
    required this.controller,
    required this.issues,
    required this.selected,
    required this.onSelect,
  });

  final ScrollController controller;
  final List<GitHubActivity> issues;
  final GitHubActivity? selected;
  final ValueChanged<GitHubActivity> onSelect;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const DashboardEmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'No issues match these filters',
        description: 'Try a different query or issue state.',
      );
    }
    return Column(
      children: [
        for (final (index, issue) in issues.indexed)
          DashboardScrollReveal(
            controller: controller,
            delay: Duration(milliseconds: 45 * index),
            child: Container(
              decoration: BoxDecoration(
                color: selected == issue
                    ? dashboardPaleBlue.withValues(alpha: .58)
                    : Colors.transparent,
                border: const Border(bottom: BorderSide(color: dashboardRule)),
              ),
              child: DashboardDataRow(
                leading: Icon(
                  issue.state == 'closed'
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: '#${issue.number ?? '—'}  ${issue.title}',
                detail:
                    '${issue.author} · Updated ${_date(issue.date)}${issue.labels.isEmpty ? '' : ' · ${issue.labels.join(', ')}'}',
                trailing: DashboardStatusTag(
                  issue.state == 'closed' ? 'Closed' : 'Open',
                  color: issue.state == 'closed'
                      ? const Color(0xFF15A578)
                      : const Color(0xFFB7791F),
                ),
                onTap: () => onSelect(issue),
                color: issue.state == 'closed'
                    ? const Color(0xFF15A578)
                    : const Color(0xFFB7791F),
              ),
            ),
          ),
      ],
    );
  }
}

class _IssueDetail extends StatelessWidget {
  const _IssueDetail({
    required this.issue,
    required this.repository,
    required this.onOpen,
  });

  final GitHubActivity issue;
  final GitHubRepositoryConnection repository;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF101B33),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bug_report_outlined, color: dashboardCyan),
            const SizedBox(width: 9),
            Text(
              '${repository.fullName} · #${issue.number ?? '—'}',
              style: dashboardTextStyle(
                color: Colors.white70,
                size: 10,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          issue.title,
          style: dashboardTextStyle(
            color: Colors.white,
            size: 20,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        DashboardStatusTag(
          issue.state == 'closed' ? 'CLOSED' : 'OPEN',
          color: issue.state == 'closed'
              ? const Color(0xFF59D6A5)
              : const Color(0xFFFFC857),
        ),
        const SizedBox(height: 20),
        _IssueMeta('Author', issue.author),
        _IssueMeta('Created', _date(issue.createdAt)),
        _IssueMeta('Updated', _date(issue.date)),
        _IssueMeta('Closed', _date(issue.closedAt)),
        const SizedBox(height: 8),
        if (issue.labels.isEmpty)
          Text(
            'No labels',
            style: dashboardTextStyle(color: Colors.white60, size: 10),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in issue.labels)
                DashboardStatusTag(label, color: dashboardCyan),
            ],
          ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new_rounded, size: 15),
          label: const Text('Open issue on GitHub'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ],
    ),
  );
}

class _IssueMeta extends StatelessWidget {
  const _IssueMeta(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: dashboardTextStyle(color: Colors.white54, size: 9),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: dashboardTextStyle(
              color: Colors.white,
              size: 10,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

String _count(int? value, {required bool loading}) =>
    loading ? '…' : value?.toString() ?? '—';

String _date(DateTime? date) {
  if (date == null) return 'Unavailable';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
