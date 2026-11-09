import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';

class CodeQualityPage extends StatelessWidget {
  const CodeQualityPage({
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
  Widget build(BuildContext context) {
    final quality = overview?.qualitySignals;
    final ci = quality?.ci;
    final available = ci?.availability == 'available';
    final ciColor = switch (ci?.state) {
      'success' => const Color(0xFF15A578),
      'failure' => const Color(0xFFE24B4B),
      'pending' => const Color(0xFFF59E0B),
      'not_configured' => dashboardMuted,
      _ => dashboardMuted,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: scrollController,
          eyebrow: 'Engineering health',
          title: 'Build software with confidence.',
          description:
              'Inspect repository-backed CI and hygiene signals. DevInsight does not turn these checks into an unsupported quality grade or test-coverage score.',
        ),
        if (error != null)
          DashboardInlineNotice(
            message: overview == null
                ? 'Engineering signals could not be loaded: $error'
                : 'Showing available engineering signals after a refresh error: $error',
            stale: overview != null,
          ),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF101B33),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_tree_rounded,
                          color: dashboardCyan,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Code → Build → Test → Review → Deploy',
                            style: dashboardTextStyle(
                              color: Colors.white,
                              size: 15,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const DashboardStatusTag(
                          'SIGNALS ONLY',
                          color: Color(0xFFFFC857),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    DashboardAnimatedWorkflow(
                      controller: scrollController,
                      stages: const [
                        'Code',
                        'Build',
                        'Test',
                        'Review',
                        'Deploy',
                      ],
                      accent: dashboardCyan,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Only GitHub check results and repository file signals are reflected below. Other stages are conceptual until measured.',
                      style: dashboardTextStyle(
                        color: Colors.white60,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              DashboardScrollReveal(
                controller: scrollController,
                child: Wrap(
                  spacing: 25,
                  runSpacing: 20,
                  children: [
                    DashboardMetric(
                      label: 'CI state',
                      value: loading ? '…' : _ciTitle(ci?.state),
                      detail: repository?.fullName ?? 'No repository selected',
                      color: ciColor,
                    ),
                    DashboardMetric(
                      label: 'Passed',
                      value: available ? '${ci?.passed ?? 0}' : '—',
                      detail: 'Latest default-branch checks',
                      color: const Color(0xFF15A578),
                    ),
                    DashboardMetric(
                      label: 'Failed',
                      value: available ? '${ci?.failed ?? 0}' : '—',
                      detail: 'Latest default-branch checks',
                      color: const Color(0xFFE24B4B),
                    ),
                    DashboardMetric(
                      label: 'Pending',
                      value: available ? '${ci?.pending ?? 0}' : '—',
                      detail: 'Latest default-branch checks',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              if (ci == null || !available)
                DashboardEmptyState(
                  icon: Icons.sync_problem_rounded,
                  title: _ciTitle(ci?.state),
                  description: ci?.state == 'not_configured'
                      ? 'GitHub reports no configured checks for the latest default-branch commit.'
                      : error ??
                            'Latest CI check results are not available as a complete GitHub signal.',
                  action: ci?.url == null
                      ? null
                      : TextButton.icon(
                          onPressed: () => onOpenLink(ci!.url!),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open GitHub Actions'),
                        ),
                )
              else
                _CheckSummary(
                  passed: ci.passed ?? 0,
                  failed: ci.failed ?? 0,
                  pending: ci.pending ?? 0,
                  completedAt: ci.lastCompletedAt,
                  onOpen: ci.url == null ? null : () => onOpenLink(ci.url!),
                ),
              const SizedBox(height: 48),
              const DashboardSectionHeading(
                label: 'Repository hygiene',
                title: 'Foundations that help teams ship',
                description:
                    'These are detectable repository facts, not a substitute for review or a maintainability score.',
              ),
              const SizedBox(height: 15),
              for (final (index, signal) in [
                (
                  Icons.description_outlined,
                  'README documentation',
                  _booleanSignal(quality?.readmePresent),
                  quality?.readmePresent == true,
                ),
                (
                  Icons.policy_outlined,
                  'License file',
                  _booleanSignal(quality?.licensePresent),
                  quality?.licensePresent == true,
                ),
                (
                  Icons.science_outlined,
                  'Test files detected',
                  _booleanSignal(quality?.testsDetected),
                  quality?.testsDetected == true,
                ),
              ].indexed)
                DashboardScrollReveal(
                  controller: scrollController,
                  delay: Duration(milliseconds: 70 * index),
                  child: _HygieneSignal(
                    icon: signal.$1,
                    title: signal.$2,
                    result: signal.$3,
                    positive: signal.$4,
                  ),
                ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final commit = _LatestCommit(
                    repository: repository,
                    quality: quality,
                    onOpenLink: onOpenLink,
                  );
                  final branch = _DefaultBranch(
                    repository: repository,
                    quality: quality,
                  );
                  if (constraints.maxWidth < 720) {
                    return Column(
                      children: [commit, const SizedBox(height: 24), branch],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: commit),
                      const SizedBox(width: 40),
                      Expanded(child: branch),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
              const DashboardEmptyState(
                icon: Icons.rule_folder_outlined,
                title: 'No composite quality score',
                description:
                    'Coverage percentages, vulnerability totals, and maintainability grades are not returned by the connected GitHub overview and are not fabricated here.',
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckSummary extends StatelessWidget {
  const _CheckSummary({
    required this.passed,
    required this.failed,
    required this.pending,
    required this.completedAt,
    required this.onOpen,
  });

  final int passed;
  final int failed;
  final int pending;
  final DateTime? completedAt;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: dashboardRule),
        bottom: BorderSide(color: dashboardRule),
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_rounded, color: Color(0xFF15A578), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Check totals reported by GitHub · completed ${_date(completedAt)}',
            style: dashboardTextStyle(size: 11, weight: FontWeight.w700),
          ),
        ),
        if (onOpen != null)
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Checks'),
          ),
      ],
    ),
  );
}

class _HygieneSignal extends StatelessWidget {
  const _HygieneSignal({
    required this.icon,
    required this.title,
    required this.result,
    required this.positive,
  });

  final IconData icon;
  final String title;
  final String result;
  final bool positive;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: dashboardRule)),
    ),
    child: DashboardDataRow(
      leading: Icon(icon),
      title: title,
      detail: 'Repository tree signal from the latest overview',
      trailing: DashboardStatusTag(
        result,
        color: result == 'Not measured'
            ? dashboardMuted
            : positive
            ? const Color(0xFF15A578)
            : const Color(0xFFB7791F),
      ),
    ),
  );
}

class _LatestCommit extends StatelessWidget {
  const _LatestCommit({
    required this.repository,
    required this.quality,
    required this.onOpenLink,
  });

  final GitHubRepositoryConnection? repository;
  final GitHubQualitySignals? quality;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final sha = quality?.latestCommitSha;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeading(
          label: 'Latest default-branch commit',
          title: 'A clear starting point',
          description:
              'The overview includes a commit reference, but not a full commit message.',
        ),
        const SizedBox(height: 14),
        DashboardDataRow(
          leading: const Icon(Icons.commit_rounded),
          title: sha == null
              ? 'Commit unavailable'
              : sha.substring(0, sha.length.clamp(0, 7)),
          detail: repository?.defaultBranch ?? 'Default branch unavailable',
          trailing: quality?.latestCommitUrl == null
              ? null
              : IconButton(
                  tooltip: 'Open latest commit on GitHub',
                  onPressed: () => onOpenLink(quality!.latestCommitUrl!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                ),
        ),
      ],
    );
  }
}

class _DefaultBranch extends StatelessWidget {
  const _DefaultBranch({required this.repository, required this.quality});

  final GitHubRepositoryConnection? repository;
  final GitHubQualitySignals? quality;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const DashboardSectionHeading(
        label: 'Build context',
        title: 'Configured branch',
        description:
            'CI counts refer to the current default-branch commit signal.',
      ),
      const SizedBox(height: 14),
      DashboardDataRow(
        leading: const Icon(Icons.account_tree_outlined),
        title:
            quality?.defaultBranch ??
            repository?.defaultBranch ??
            'Not available',
        detail: repository?.fullName ?? 'No repository selected',
        trailing: const DashboardStatusTag('DEFAULT', color: dashboardBlue),
      ),
    ],
  );
}

String _ciTitle(String? state) => switch (state) {
  'success' => 'Passing',
  'failure' => 'Failing',
  'pending' => 'Pending',
  'not_configured' => 'Not configured',
  'not_measured' || null => 'Not measured',
  _ => 'Unavailable',
};

String _booleanSignal(bool? value) => value == null
    ? 'Not measured'
    : value
    ? 'Detected'
    : 'Not detected';

String _date(DateTime? date) {
  if (date == null) return 'unavailable';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
