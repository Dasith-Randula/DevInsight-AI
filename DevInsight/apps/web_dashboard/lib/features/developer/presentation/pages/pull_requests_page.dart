import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

enum _PullFilter { all, open, merged, closed }

class PullRequestsPage extends StatefulWidget {
  const PullRequestsPage({
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
  State<PullRequestsPage> createState() => _PullRequestsPageState();
}

class _PullRequestsPageState extends State<PullRequestsPage> {
  final _searchController = TextEditingController();
  _PullFilter _filter = _PullFilter.all;
  GitHubActivity? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPulls =
        widget.overview?.recentActivity
            .where((activity) => activity.type == 'pull_request')
            .toList() ??
        const <GitHubActivity>[];
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allPulls.where((pull) {
      final matchesState = switch (_filter) {
        _PullFilter.all => true,
        _PullFilter.open => pull.state == 'open',
        _PullFilter.merged => pull.state == 'merged',
        _PullFilter.closed => pull.state == 'closed',
      };
      final matchesSearch =
          query.isEmpty ||
          pull.title.toLowerCase().contains(query) ||
          pull.author.toLowerCase().contains(query) ||
          '${pull.number ?? ''}'.contains(query);
      return matchesState && matchesSearch;
    }).toList();
    final selected = filtered.contains(_selected)
        ? _selected
        : filtered.isEmpty
        ? null
        : filtered.first;
    final openCount = widget.overview?.openPullRequests;
    final mergedCount = allPulls.where((pull) => pull.state == 'merged').length;
    final closedCount = allPulls.where((pull) => pull.state == 'closed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: widget.scrollController,
          eyebrow: 'Code collaboration',
          title: 'From code changes to collaboration.',
          description:
              'Follow the pull request lifecycle across the active repository, with each item and state sourced from GitHub.',
        ),
        if (widget.error != null)
          DashboardInlineNotice(
            message: widget.overview == null
                ? 'Pull request data could not be loaded: ${widget.error}'
                : 'Showing the available pull request snapshot after a refresh error: ${widget.error}',
            stale: widget.overview != null,
          ),
        DashboardScrollReveal(
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 26,
                runSpacing: 18,
                children: [
                  DashboardMetric(
                    label: 'Open pull requests',
                    value: widget.loading ? '…' : openCount?.toString() ?? '—',
                    detail: 'Repository-wide GitHub count',
                    color: const Color(0xFF15A578),
                  ),
                  DashboardMetric(
                    label: 'Merged in sample',
                    value: '$mergedCount',
                    detail: 'Recent returned records',
                    color: const Color(0xFF7C3AED),
                  ),
                  DashboardMetric(
                    label: 'Closed in sample',
                    value: '$closedCount',
                    detail: 'Recent returned records',
                    color: const Color(0xFFB7791F),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: dashboardRule),
                    bottom: BorderSide(color: dashboardRule),
                  ),
                ),
                child: DashboardAnimatedWorkflow(
                  controller: widget.scrollController,
                  stages: const ['Branch', 'Open PR', 'Review', 'Merge'],
                  accent: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 38),
              const DashboardSectionHeading(
                label: 'Pull request explorer',
                title: 'Changes in motion',
                description:
                    'Search and filter the recent pull request records available for the selected repository.',
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 680;
                  final search = TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search title, number, or author',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  final filters = Wrap(
                    spacing: 6,
                    children: [
                      for (final (filter, label) in [
                        (_PullFilter.all, 'All'),
                        (_PullFilter.open, 'Open'),
                        (_PullFilter.merged, 'Merged'),
                        (_PullFilter.closed, 'Closed'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [search, const SizedBox(height: 12), filters],
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
              const SizedBox(height: 20),
              if (widget.repository == null || widget.overview == null)
                DashboardEmptyState(
                  icon: Icons.merge_rounded,
                  title: widget.loading
                      ? 'Loading pull requests'
                      : widget.repository == null
                      ? 'Connect a repository to follow changes'
                      : widget.error != null
                      ? 'Pull request data unavailable'
                      : 'Pull request summary is not available',
                  description: widget.error ??
                      'Pull request records are displayed only when provided by GitHub.',
                )
              else if (allPulls.isEmpty)
                DashboardEmptyState(
                  icon: Icons.call_merge_rounded,
                  title: 'No pull requests in the recent sample',
                  description:
                      'The recent GitHub activity response contains no pull request records for ${widget.repository!.fullName}. An empty sample is a valid result.',
                )
              else
                _PullExplorer(
                  controller: widget.scrollController,
                  pulls: filtered,
                  selected: selected,
                  repository: widget.repository!,
                  onSelect: (pull) => setState(() => _selected = pull),
                  onOpen: widget.onOpenLink,
                ),
              const SizedBox(height: 42),
              const DashboardSectionHeading(
                label: 'Review activity',
                title: 'A collaboration signal',
                description:
                    'Review-comment and reviewer-level activity is not part of the current repository overview. The list below reflects only available PR timestamps and states.',
              ),
              const SizedBox(height: 16),
              if (allPulls.isEmpty)
                const DashboardEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'Review history unavailable',
                  description:
                      'GitHub review events are not included in the current bounded summary.',
                )
              else
                for (final (index, pull) in allPulls.take(5).indexed)
                  DashboardScrollReveal(
                    controller: widget.scrollController,
                    delay: Duration(milliseconds: 55 * index),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: dashboardRule),
                        ),
                      ),
                      child: DashboardDataRow(
                        leading: const Icon(Icons.history_rounded),
                        title: '#${pull.number ?? '—'} ${pull.title}',
                        detail:
                            '${pull.author} · Created ${_date(pull.createdAt)} · Updated ${_date(pull.date)}',
                        trailing: DashboardStatusTag(
                          _label(pull.state),
                          color: _statusColor(pull.state),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ],
    );
  }
}

class _PullExplorer extends StatelessWidget {
  const _PullExplorer({
    required this.controller,
    required this.pulls,
    required this.selected,
    required this.repository,
    required this.onSelect,
    required this.onOpen,
  });

  final ScrollController controller;
  final List<GitHubActivity> pulls;
  final GitHubActivity? selected;
  final GitHubRepositoryConnection repository;
  final ValueChanged<GitHubActivity> onSelect;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (pulls.isEmpty) {
      return const DashboardEmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'No pull requests match these filters',
        description: 'Try a different query or lifecycle state.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 850;
        final list = Column(
          children: [
            for (final (index, pull) in pulls.indexed)
              DashboardScrollReveal(
                controller: controller,
                delay: Duration(milliseconds: 45 * index),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected == pull
                        ? dashboardPaleBlue.withValues(alpha: .56)
                        : Colors.transparent,
                    border: const Border(
                      bottom: BorderSide(color: dashboardRule),
                    ),
                  ),
                  child: DashboardDataRow(
                    leading: Icon(
                      Icons.merge_rounded,
                      color: _statusColor(pull.state),
                    ),
                    title: '#${pull.number ?? '—'}  ${pull.title}',
                    detail: '${pull.author} · Updated ${_date(pull.date)}',
                    trailing: DashboardStatusTag(
                      _label(pull.state),
                      color: _statusColor(pull.state),
                    ),
                    onTap: () => onSelect(pull),
                  ),
                ),
              ),
          ],
        );
        final detail = selected == null
            ? const DashboardEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching pull requests',
                description: 'Change the filters to see available records.',
              )
            : _PullDetail(
                repository: repository,
                pull: selected!,
                onOpen: () => onOpen(selected!.url),
              );
        if (narrow) {
          return Column(children: [list, const SizedBox(height: 18), detail]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: list),
            const SizedBox(width: 24),
            Expanded(flex: 4, child: detail),
          ],
        );
      },
    );
  }
}

class _PullDetail extends StatelessWidget {
  const _PullDetail({
    required this.repository,
    required this.pull,
    required this.onOpen,
  });

  final GitHubRepositoryConnection repository;
  final GitHubActivity pull;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F5FF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: dashboardRule),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          repository.fullName,
          style: dashboardTextStyle(
            color: dashboardBlue,
            size: 10,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          pull.title,
          style: dashboardTextStyle(size: 19, weight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        DashboardStatusTag(_label(pull.state), color: _statusColor(pull.state)),
        const SizedBox(height: 18),
        _PullFact('PR number', '#${pull.number ?? '—'}'),
        _PullFact('Author', pull.author),
        _PullFact('Base branch', repository.defaultBranch ?? 'Not available'),
        _PullFact('Head branch', 'Not included in current summary'),
        _PullFact('Created', _date(pull.createdAt)),
        _PullFact('Updated', _date(pull.date)),
        _PullFact('Merged', _date(pull.mergedAt)),
        TextButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new_rounded, size: 15),
          label: const Text('Open pull request on GitHub'),
        ),
      ],
    ),
  );
}

class _PullFact extends StatelessWidget {
  const _PullFact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: dashboardTextStyle(color: dashboardMuted, size: 9),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: dashboardTextStyle(size: 10, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

String _label(String? state) => switch (state) {
  'merged' => 'Merged',
  'closed' => 'Closed',
  'open' => 'Open',
  _ => 'Unknown',
};

Color _statusColor(String? state) => switch (state) {
  'merged' => const Color(0xFF7C3AED),
  'closed' => const Color(0xFFB7791F),
  'open' => const Color(0xFF15A578),
  _ => dashboardMuted,
};

String _date(DateTime? date) {
  if (date == null) return 'Unavailable';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
