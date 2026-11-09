import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';

class DeveloperHomeSections extends StatelessWidget {
  const DeveloperHomeSections({
    super.key,
    required this.scrollController,
    required this.overviewSectionKey,
    required this.overview,
    required this.hasRepository,
    required this.loading,
    required this.onAction,
    required this.onOpenRepository,
  });

  final ScrollController scrollController;
  final GlobalKey overviewSectionKey;
  final GitHubRepositoryOverview? overview;
  final bool hasRepository;
  final bool loading;
  final ValueChanged<String> onAction;
  final ValueChanged<String> onOpenRepository;

  @override
  Widget build(BuildContext context) {
    Widget reveal(Widget child) =>
        _ScrollReveal(controller: scrollController, child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        reveal(
          _OverviewSection(
            key: overviewSectionKey,
            overview: overview,
            hasRepository: hasRepository,
            loading: loading,
          ),
        ),
        const SizedBox(height: 112),
        reveal(
          _WeeklyActivitySection(
            scrollController: scrollController,
            overview: overview,
            hasRepository: hasRepository,
          ),
        ),
        const SizedBox(height: 112),
        reveal(
          _RepositoryIntelligenceSection(
            scrollController: scrollController,
            overview: overview,
            hasRepository: hasRepository,
            loading: loading,
            onOpenRepository: onOpenRepository,
          ),
        ),
        const SizedBox(height: 112),
        reveal(_AiInsightsSection(onAction: onAction)),
        const SizedBox(height: 112),
        reveal(
          _EngineeringHealthSection(
            overview: overview,
            hasRepository: hasRepository,
            loading: loading,
            onOpenRepository: onOpenRepository,
          ),
        ),
        const SizedBox(height: 112),
        reveal(
          _ActivityTimelineSection(
            overview: overview,
            hasRepository: hasRepository,
            onOpenRepository: onOpenRepository,
          ),
        ),
        const SizedBox(height: 72),
        reveal(_WorkspaceNotesSection(onAction: onAction)),
        const SizedBox(height: 36),
        reveal(_WorkspaceActionsSection(onAction: onAction)),
        const SizedBox(height: 24),
      ],
    );
  }
}

const _blue = Color(0xFF0056FF);
const _muted = Color(0xFF71809A);
const _line = Color(0xFFDCE7F5);

TextStyle _textStyle({
  Color? color,
  double size = 14,
  FontWeight weight = FontWeight.w500,
  double height = 1.4,
}) => GoogleFonts.plusJakartaSans(
  color: color,
  fontSize: size,
  fontWeight: weight,
  height: height,
);

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    super.key,
    required this.overview,
    required this.hasRepository,
    required this.loading,
  });

  final GitHubRepositoryOverview? overview;
  final bool hasRepository;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final health = overview?.repositoryHealth;
    final weekly = overview?.weeklyActivity;
    final ciState = overview?.qualitySignals?.ci.state;
    final metrics = [
      (
        'Assigned Issues',
        'Not linked',
        'Personal GitHub identity',
        Icons.person_search_outlined,
      ),
      (
        'Resolved Issues',
        _repositoryValue(
          overview?.resolvedIssues30d,
          hasRepository: hasRepository,
          loading: loading,
        ),
        'Closed in the last 30 days',
        Icons.check_circle_outline_rounded,
      ),
      (
        'Open Pull Requests',
        _repositoryValue(
          overview?.openPullRequests,
          hasRepository: hasRepository,
          loading: loading,
        ),
        'Across the connected repository',
        Icons.merge_rounded,
      ),
      (
        'Development activity',
        _weeklyActivityValue(weekly, hasRepository, loading),
        'Measured commits · 8 weeks',
        Icons.timeline_rounded,
      ),
      (
        'Code quality / CI',
        _ciLabel(ciState),
        'CI status only · not a score',
        Icons.verified_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorialHeading(
          eyebrow: 'DEVELOPMENT OVERVIEW',
          title: 'Your code tells a story.',
          description:
              'Explore the activity, progress, and engineering signals shaping your project.',
        ),
        const SizedBox(height: 38),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1200
                ? 5
                : constraints.maxWidth >= 760
                ? 3
                : 2;
            const gap = 22.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: 30,
              children: [
                for (var index = 0; index < metrics.length; index++)
                  SizedBox(
                    width: width,
                    child: _OverviewMetric(
                      label: metrics[index].$1,
                      value: metrics[index].$2,
                      detail: metrics[index].$3,
                      icon: metrics[index].$4,
                      emphasized: index == 2,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 34),
        const _FlowingCodeLine(),
        const SizedBox(height: 16),
        Text(
          health == null
              ? 'Repository signals will appear once a project is connected.'
              : 'Repository signals are provided by GitHub; no synthetic scores are shown.',
          style: _textStyle(color: _muted, size: 12),
        ),
      ],
    );
  }
}

String _repositoryValue(
  int? value, {
  required bool hasRepository,
  required bool loading,
}) {
  if (!hasRepository) return 'Not linked';
  if (loading) return 'Loading';
  return value?.toString() ?? 'Unavailable';
}

String _weeklyActivityValue(
  GitHubWeeklyActivity? activity,
  bool hasRepository,
  bool loading,
) {
  if (!hasRepository) return 'Not linked';
  if (loading) return 'Loading';
  if (activity == null ||
      activity.availability != 'available' ||
      !activity.isComplete ||
      activity.totalCommits == null) {
    return 'Unavailable';
  }
  return '${activity.totalCommits}';
}

String _ciLabel(String? state) => switch (state) {
  'success' => 'Passing',
  'failure' => 'Failing',
  'pending' => 'Pending',
  'not_configured' => 'Not configured',
  null => 'Not measured',
  _ => 'Unavailable',
};

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.emphasized,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _line, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: emphasized ? _blue : colors.mutedText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    color: colors.mutedText,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              color: emphasized ? _blue : colors.primaryText,
              size: value.length > 12 ? 22 : 32,
              weight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(color: colors.mutedText, size: 11),
          ),
        ],
      ),
    );
  }
}

class _FlowingCodeLine extends StatelessWidget {
  const _FlowingCodeLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.code_rounded, size: 15, color: _blue),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9CC4FF),
                  Color(0xFFDCE7F5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(
          Icons.account_tree_outlined,
          size: 15,
          color: Color(0xFF8DA8CD),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFDCE7F5),
                  Color(0xFF9CC4FF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.commit_rounded, size: 15, color: _blue),
      ],
    );
  }
}

class _WeeklyActivitySection extends StatelessWidget {
  const _WeeklyActivitySection({
    required this.scrollController,
    required this.overview,
    required this.hasRepository,
  });

  final ScrollController scrollController;
  final GitHubRepositoryOverview? overview;
  final bool hasRepository;

  @override
  Widget build(BuildContext context) {
    final activity = overview?.weeklyActivity;
    final validData =
        activity != null &&
        activity.availability == 'available' &&
        activity.isComplete &&
        activity.weeks.isNotEmpty &&
        activity.weeks.every((week) => week.commits != null);
    final weeks = validData ? activity.weeks : const <GitHubWeeklyCommit>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorialHeading(
          eyebrow: 'WEEKLY DEVELOPMENT ACTIVITY',
          title: 'Every commit moves the project forward.',
          description:
              'See how development evolves through commits, contributions, and activity on the default branch.',
        ),
        const SizedBox(height: 34),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 860;
            final chart = _ActivityChart(
              weeks: weeks,
              branch: activity?.branch,
              totalCommits: validData ? activity.totalCommits : null,
              unavailableMessage: !hasRepository
                  ? 'Connect a repository to measure weekly activity.'
                  : 'Weekly activity is unavailable or incomplete.',
            );
            final illustration = SizedBox(
              height: narrow ? 230 : 300,
              child: _AnimatedBranchArtwork(scrollController: scrollController),
            );
            if (narrow) {
              return Column(
                children: [chart, const SizedBox(height: 18), illustration],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 7, child: chart),
                const SizedBox(width: 28),
                Expanded(flex: 3, child: illustration),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({
    required this.weeks,
    required this.branch,
    required this.totalCommits,
    required this.unavailableMessage,
  });

  final List<GitHubWeeklyCommit> weeks;
  final String? branch;
  final int? totalCommits;
  final String unavailableMessage;

  @override
  Widget build(BuildContext context) {
    final hasData = weeks.isNotEmpty && totalCommits != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                hasData
                    ? '$totalCommits commits measured'
                    : 'Activity not measured',
                style: _textStyle(size: 21, weight: FontWeight.w800),
              ),
            ),
            if (branch != null)
              Text(
                branch!,
                style: _textStyle(
                  color: _muted,
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hasData
              ? 'Weekly commits · Sunday boundary · reported by GitHub'
              : unavailableMessage,
          style: _textStyle(color: _muted, size: 12),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 220,
          width: double.infinity,
          child: hasData ? _WeeklyBars(weeks: weeks) : const _EmptyChart(),
        ),
        if (hasData) ...[
          const SizedBox(height: 11),
          const Row(
            children: [
              Icon(Icons.circle, size: 7, color: _blue),
              SizedBox(width: 7),
              Text('Commits per week'),
            ],
          ),
        ],
      ],
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.weeks});

  final List<GitHubWeeklyCommit> weeks;

  @override
  Widget build(BuildContext context) {
    final maxValue = weeks.map((week) => week.commits!).fold<int>(0, math.max);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ChartGridPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final week in weeks)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${_dateLabel(week.weekStart)} · ${week.commits} commits',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${week.commits}',
                                style: _textStyle(
                                  color: _muted,
                                  size: 10,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: maxValue == 0
                                        ? 0
                                        : (week.commits! / maxValue).clamp(
                                            0.06,
                                            1,
                                          ),
                                    child: Container(
                                      width: math.min(
                                        36,
                                        constraints.maxWidth / weeks.length - 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF74B2FF), _blue],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                _dateLabel(week.weekStart),
                                maxLines: 1,
                                style: _textStyle(color: _muted, size: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartGridPainter(),
      child: Center(
        child: Text(
          'No validated weekly commit series to display',
          textAlign: TextAlign.center,
          style: _textStyle(color: _muted, size: 13),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

class _RepositoryIntelligenceSection extends StatelessWidget {
  const _RepositoryIntelligenceSection({
    required this.scrollController,
    required this.overview,
    required this.hasRepository,
    required this.loading,
    required this.onOpenRepository,
  });

  final ScrollController scrollController;
  final GitHubRepositoryOverview? overview;
  final bool hasRepository;
  final bool loading;
  final ValueChanged<String> onOpenRepository;

  @override
  Widget build(BuildContext context) {
    final health = overview?.repositoryHealth;
    final repo = overview?.connection;
    final signals = [
      (
        'Recent development activity',
        health == null
            ? 'Not measured'
            : _activityLabel(health.recentActivityStatus),
        Icons.bolt_rounded,
      ),
      (
        'Open issues',
        _repositoryValue(
          health?.openIssues,
          hasRepository: hasRepository,
          loading: loading,
        ),
        Icons.bug_report_outlined,
      ),
      (
        'Closed issues · 30 days',
        _repositoryValue(
          health?.closedIssues30d,
          hasRepository: hasRepository,
          loading: loading,
        ),
        Icons.check_circle_outline_rounded,
      ),
      (
        'Open pull requests',
        _repositoryValue(
          health?.openPullRequests,
          hasRepository: hasRepository,
          loading: loading,
        ),
        Icons.merge_rounded,
      ),
      (
        'Last push',
        _relativeDate(health?.lastPushAt ?? health?.latestCommitAt),
        Icons.history_rounded,
      ),
      (
        'CI configuration',
        _ciLabel(health?.ciState),
        Icons.account_tree_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorialHeading(
          eyebrow: 'REPOSITORY INTELLIGENCE',
          title: "Understand what's happening beneath the code.",
          description:
              'A grounded view of repository health from GitHub operational signals.',
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 840;
            final data = Column(
              children: [
                for (final signal in signals)
                  _DataLine(
                    label: signal.$1,
                    value: signal.$2,
                    icon: signal.$3,
                  ),
                _DataLine(
                  label: 'Oldest open PR',
                  value: health?.oldestOpenPullRequestAgeDays == null
                      ? health?.oldestOpenPullRequestAvailability ==
                                    'available' &&
                                health?.oldestOpenPullRequestPresent == false
                            ? 'No open pull requests'
                            : 'Not measured'
                      : 'Oldest open PR: ${health!.oldestOpenPullRequestAgeDays} days${health.oldestOpenPullRequestAgeDays! > 14 ? ' · aging' : ''}',
                  icon: Icons.schedule_rounded,
                  onTap: health?.oldestOpenPullRequestUrl == null
                      ? null
                      : () =>
                            onOpenRepository(health!.oldestOpenPullRequestUrl!),
                ),
              ],
            );
            final artwork = SizedBox(
              height: narrow ? 220 : 330,
              child: _AnimatedRepositoryNetwork(
                scrollController: scrollController,
                repositoryName: repo?.fullName,
              ),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [data, const SizedBox(height: 22), artwork],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: data),
                const SizedBox(width: 36),
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: Theme.of(context).brightness == Brightness.dark
                          ? null
                          : const RadialGradient(
                              colors: [Color(0xFFDCEBFF), Color(0x00EAF3FF)],
                            ),
                    ),
                    child: artwork,
                  ),
                ),
              ],
            );
          },
        ),
        if (repo != null) ...[
          const SizedBox(height: 12),
          Text(
            '${repo.owner}  ·  ${repo.defaultBranch ?? 'Default branch not set'}  ·  ${repo.primaryLanguage ?? 'Language not detected'}',
            style: _textStyle(color: _muted, size: 12),
          ),
        ],
        if (!hasRepository)
          Text(
            'Connect a repository to load its GitHub signals.',
            style: _textStyle(color: _muted, size: 12),
          ),
      ],
    );
  }
}

String _activityLabel(String value) => switch (value) {
  'recently_active' => 'Recently active',
  'no_recent_push' => 'No push in 14 days',
  _ => 'Not measured',
};

String _relativeDate(DateTime? date) {
  if (date == null) return 'Not measured';
  final elapsed = DateTime.now().toUtc().difference(date.toUtc());
  if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours}h ago';
  if (elapsed.inDays < 30) return '${elapsed.inDays}d ago';
  return _dateLabel(date.toLocal());
}

class _DataLine extends StatelessWidget {
  const _DataLine({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _blue, size: 17),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: _textStyle(color: _muted, size: 13)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(size: 14, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInsightsSection extends StatelessWidget {
  const _AiInsightsSection({required this.onAction});

  final ValueChanged<String> onAction;

  static const _features = [
    (
      'Risk prediction',
      'Research feature · no risk score is currently generated.',
      Icons.warning_amber_rounded,
      Color(0xFFEF4444),
    ),
    (
      'Issue prioritization',
      'Research feature · AI recommendations are not available yet.',
      Icons.lightbulb_outline_rounded,
      Color(0xFF0056FF),
    ),
    (
      'Root cause analysis',
      'Research feature · no automated analysis is currently generated.',
      Icons.account_tree_outlined,
      Color(0xFF7C3AED),
    ),
    (
      'Workload intelligence',
      'Research feature · no workload recommendations are generated.',
      Icons.groups_2_outlined,
      Color(0xFF06B6D4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorialHeading(
          eyebrow: 'INTELLIGENCE IN DEVELOPMENT',
          title: 'From development data to intelligent decisions.',
          description:
              'Discover the signals that matter, understand potential risks, and support confident engineering decisions.',
        ),
        const SizedBox(height: 34),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 34) / columns;
            return Wrap(
              spacing: 34,
              runSpacing: 28,
              children: [
                for (var i = 0; i < _features.length; i++)
                  SizedBox(
                    width: width,
                    child: _AiFeature(
                      title: _features[i].$1,
                      detail: _features[i].$2,
                      icon: _features[i].$3,
                      accent: _features[i].$4,
                      alignment: i.isEven
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      onTap: () => onAction(
                        '${_features[i].$1} is an upcoming research feature.',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AiFeature extends StatelessWidget {
  const _AiFeature({
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.alignment,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final CrossAxisAlignment alignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Row(
              mainAxisAlignment: alignment == CrossAxisAlignment.end
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Icon(icon, color: accent, size: 30),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    style: _textStyle(size: 19, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              detail,
              textAlign: alignment == CrossAxisAlignment.end
                  ? TextAlign.right
                  : TextAlign.left,
              style: _textStyle(color: _muted, size: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              width: 120,
              color: accent.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'UPCOMING',
              style: _textStyle(
                color: accent,
                size: 10,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineeringHealthSection extends StatelessWidget {
  const _EngineeringHealthSection({
    required this.overview,
    required this.hasRepository,
    required this.loading,
    required this.onOpenRepository,
  });

  final GitHubRepositoryOverview? overview;
  final bool hasRepository;
  final bool loading;
  final ValueChanged<String> onOpenRepository;

  @override
  Widget build(BuildContext context) {
    final signals = overview?.qualitySignals;
    final ci = signals?.ci;
    final languages = overview?.languages ?? const <GitHubLanguage>[];
    final latestCommit = signals?.latestCommitSha;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorialHeading(
          eyebrow: 'ENGINEERING HEALTH',
          title: 'Build with confidence.',
          description:
              'A practical read on CI, repository hygiene, and the tools detected in your project.',
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 780;
            final pipeline = _PipelineSummary(
              state: ci?.state,
              passed: ci?.passed,
              failed: ci?.failed,
              pending: ci?.pending,
              loading: loading,
              hasRepository: hasRepository,
            );
            final hygiene = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QualityLine(
                  label: 'Tests detected',
                  value: _booleanLabel(signals?.testsDetected),
                ),
                _QualityLine(
                  label: 'README',
                  value: _booleanLabel(signals?.readmePresent),
                ),
                _QualityLine(
                  label: 'License',
                  value: _booleanLabel(signals?.licensePresent),
                ),
                _QualityLine(
                  label: 'Latest commit',
                  value: latestCommit == null
                      ? 'Not measured'
                      : latestCommit.substring(
                          0,
                          math.min(7, latestCommit.length),
                        ),
                  onTap: signals?.latestCommitUrl == null
                      ? null
                      : () => onOpenRepository(signals!.latestCommitUrl!),
                ),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pipeline,
                  const SizedBox(height: 26),
                  hygiene,
                  const SizedBox(height: 30),
                  _LanguageComposition(
                    languages: languages,
                    hasRepository: hasRepository,
                  ),
                ],
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: pipeline),
                    const SizedBox(width: 40),
                    Expanded(flex: 4, child: hygiene),
                  ],
                ),
                const SizedBox(height: 38),
                _LanguageComposition(
                  languages: languages,
                  hasRepository: hasRepository,
                ),
              ],
            );
          },
        ),
        if (!hasRepository)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              'Connect a repository to load engineering quality signals.',
              style: _textStyle(color: _muted, size: 12),
            ),
          ),
      ],
    );
  }
}

String _booleanLabel(bool? value) => switch (value) {
  true => 'Detected',
  false => 'Not detected',
  null => 'Not measured',
};

class _PipelineSummary extends StatelessWidget {
  const _PipelineSummary({
    required this.state,
    required this.passed,
    required this.failed,
    required this.pending,
    required this.loading,
    required this.hasRepository,
  });

  final String? state;
  final int? passed;
  final int? failed;
  final int? pending;
  final bool loading;
  final bool hasRepository;

  @override
  Widget build(BuildContext context) {
    final label = !hasRepository
        ? 'Not linked'
        : loading
        ? 'Loading'
        : _ciLabel(state);
    final items = [
      ('Passed checks', passed),
      ('Failed checks', failed),
      ('Pending checks', pending),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_tree_rounded, color: _blue, size: 20),
                const SizedBox(width: 10),
                Text(
                  'CI pipeline',
                  style: _textStyle(size: 17, weight: FontWeight.w800),
                ),
              ],
            );
            final status = _StatusLabel(
              label: label,
              color: _statusColor(state),
            );
            if (constraints.maxWidth < 430) {
              return Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [title, status],
              );
            }
            return Row(children: [title, const Spacer(), status]);
          },
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0)
                Expanded(child: Container(height: 1, color: _line)),
              Expanded(
                child: _PipelineNode(
                  label: items[index].$1,
                  value: items[index].$2?.toString() ?? 'Not measured',
                  color: index == 0
                      ? const Color(0xFF169B62)
                      : index == 1
                      ? const Color(0xFFD84848)
                      : const Color(0xFFD58A13),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

Color _statusColor(String? state) => switch (state) {
  'success' => const Color(0xFF169B62),
  'failure' => const Color(0xFFD84848),
  'pending' => const Color(0xFFD58A13),
  _ => _muted,
};

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: _textStyle(color: color, size: 12, weight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PipelineNode extends StatelessWidget {
  const _PipelineNode({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final measured = value != 'Not measured';
    final icon = switch (label) {
      'Failed checks' => Icons.error_outline_rounded,
      'Pending checks' => Icons.hourglass_bottom_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: measured ? color.withValues(alpha: 0.9) : _muted,
        ),
        const SizedBox(height: 8),
        Text(value, style: _textStyle(size: 14, weight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: _textStyle(color: _muted, size: 10),
        ),
      ],
    );
  }
}

class _QualityLine extends StatelessWidget {
  const _QualityLine({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: _textStyle(color: _muted, size: 13)),
            ),
            Text(value, style: _textStyle(size: 13, weight: FontWeight.w700)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new_rounded, size: 13, color: _muted),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageComposition extends StatelessWidget {
  const _LanguageComposition({
    required this.languages,
    required this.hasRepository,
  });

  final List<GitHubLanguage> languages;
  final bool hasRepository;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repository Languages',
          style: _textStyle(size: 16, weight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (languages.isEmpty)
          Text(
            hasRepository
                ? 'Language composition is not available.'
                : 'Not linked',
            style: _textStyle(color: _muted, size: 12),
          )
        else
          for (final language in languages.take(6)) ...[
            Row(
              children: [
                Expanded(
                  child: Text(language.name, style: _textStyle(size: 12)),
                ),
                Text(
                  '${language.percentage.toStringAsFixed(1)}%',
                  style: _textStyle(color: _muted, size: 11),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (language.percentage / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFE7EEF8),
                color: _blue,
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ScrollReveal extends StatefulWidget {
  const _ScrollReveal({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal> {
  final _key = GlobalKey();
  bool _visible = false;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionDisabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled && !_visible) {
      setState(() => _visible = true);
    }
  }

  @override
  void didUpdateWidget(covariant _ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_checkVisibility);
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (_visible || !mounted || !widget.controller.hasClients) return;
    final renderObject = _key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    if (top < viewportHeight - 72 && bottom > 0) {
      setState(() => _visible = true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: _key,
      opacity: _visible ? 1 : 0,
      duration: _motionDisabled
          ? Duration.zero
          : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.035),
        duration: _motionDisabled
            ? Duration.zero
            : const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _ActivityTimelineSection extends StatelessWidget {
  const _ActivityTimelineSection({
    required this.overview,
    required this.hasRepository,
    required this.onOpenRepository,
  });

  final GitHubRepositoryOverview? overview;
  final bool hasRepository;
  final ValueChanged<String> onOpenRepository;

  @override
  Widget build(BuildContext context) {
    final activity = [...?overview?.recentActivity]
      ..sort((a, b) => _activityTime(b).compareTo(_activityTime(a)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorialHeading(
          eyebrow: 'RECENT REPOSITORY ACTIVITY',
          title: 'The work behind every milestone.',
          description:
              'A chronological view of recent commits, issues, and pull requests.',
        ),
        const SizedBox(height: 32),
        if (activity.isEmpty)
          Text(
            hasRepository
                ? 'No recent activity'
                : 'Connect a repository to load actual GitHub activity.',
            style: _textStyle(color: _muted, size: 14),
          )
        else
          for (var index = 0; index < activity.take(8).length; index++)
            _TimelineEntry(
              item: activity[index],
              isLast: index == math.min(activity.length, 8) - 1,
              onOpen: () => onOpenRepository(activity[index].url),
            ),
      ],
    );
  }
}

DateTime _activityTime(GitHubActivity activity) =>
    activity.date ??
    activity.createdAt ??
    DateTime.fromMillisecondsSinceEpoch(0);

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.item,
    required this.isLast,
    required this.onOpen,
  });

  final GitHubActivity item;
  final bool isLast;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final icon = switch (item.type) {
      'commit' => Icons.commit_rounded,
      'issue' => Icons.bug_report_outlined,
      'pull_request' => Icons.merge_rounded,
      _ => Icons.history_rounded,
    };
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 88,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 38,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(icon, color: _blue, size: 16),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 1, color: colors.border)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.type.replaceAll('_', ' ')}${item.state == null ? '' : ' · ${item.state}'}  ·  ${item.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(color: colors.mutedText, size: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _timelineDate(item.date ?? item.createdAt),
                style: _textStyle(color: colors.mutedText, size: 11),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: colors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timelineDate(DateTime? date) {
  if (date == null) return 'Date unavailable';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class _WorkspaceActionsSection extends StatelessWidget {
  const _WorkspaceActionsSection({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D55E8), Color(0xFF2C83FF), Color(0xFF69B8FF)],
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.13),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            ('Explore Projects', Icons.folder_open_outlined),
            ('View Analytics', Icons.analytics_outlined),
            ('Generate Report', Icons.description_outlined),
          ];
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Make every engineering decision count.',
                style: _textStyle(
                  color: Colors.white,
                  size: 28,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Turn repository activity into clearer, more confident engineering decisions.',
                style: _textStyle(
                  color: Colors.white.withValues(alpha: 0.83),
                  size: 14,
                ),
              ),
            ],
          );
          final buttons = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                OutlinedButton.icon(
                  onPressed: () => onAction('${action.$1} is coming soon.'),
                  icon: Icon(action.$2, size: 15),
                  label: Text(action.$1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
            ],
          );
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 22), buttons],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 28),
              Flexible(child: buttons),
            ],
          );
        },
      ),
    );
  }
}

class _WorkspaceNotesSection extends StatelessWidget {
  const _WorkspaceNotesSection({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 28,
      runSpacing: 12,
      children: [
        _WorkspaceNote(
          title: 'My Tasks',
          value: 'Not linked',
          onTap: () =>
              onAction('Tasks will be available when a project is connected.'),
        ),
        _WorkspaceNote(
          title: 'Upcoming & Reminders',
          value: 'Nothing scheduled',
          onTap: () => onAction('Project calendar is not available yet.'),
        ),
      ],
    );
  }
}

class _WorkspaceNote extends StatelessWidget {
  const _WorkspaceNote({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_forward_rounded, size: 15),
      label: Row(
        children: [
          Flexible(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      style: TextButton.styleFrom(foregroundColor: _muted),
    );
  }
}

class _EditorialHeading extends StatelessWidget {
  const _EditorialHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: _textStyle(
            color: _blue,
            size: 10,
            weight: FontWeight.w800,
          ).copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Text(
            title,
            style: _textStyle(
              color: colors.primaryText,
              size: 36,
              weight: FontWeight.w800,
              height: 1.18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 670),
          child: Text(
            description,
            style: _textStyle(
              color: colors.secondaryText,
              size: 15,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCE7F5)
      ..strokeWidth = 1;
    for (var index = 0; index < 5; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedBranchArtwork extends StatefulWidget {
  const _AnimatedBranchArtwork({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_AnimatedBranchArtwork> createState() => _AnimatedBranchArtworkState();
}

class _AnimatedBranchArtworkState extends State<_AnimatedBranchArtwork>
    with TickerProviderStateMixin {
  final _paintKey = GlobalKey();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  bool _motionDisabled = false;
  bool _isVisible = false;
  int? _hoveredNode;

  @override
  void initState() {
    super.initState();
    _reveal.addStatusListener(_onRevealStatus);
    widget.scrollController.addListener(_updateVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isVisible && !_motionDisabled) {
      _flow.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionDisabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled) {
      _flow.stop();
      _reveal
        ..stop()
        ..value = 1;
    } else {
      _updateVisibility();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedBranchArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController == widget.scrollController) return;
    oldWidget.scrollController.removeListener(_updateVisibility);
    widget.scrollController.addListener(_updateVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  void _updateVisibility() {
    if (!mounted || !widget.scrollController.hasClients) return;
    final renderObject = _paintKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final height = MediaQuery.sizeOf(context).height;
    final visible = top < height && bottom > 0;
    _isVisible = visible;
    if (_motionDisabled) {
      if (_reveal.value != 1) setState(() => _reveal.value = 1);
      return;
    }
    if (visible) {
      if (!_reveal.isAnimating && _reveal.value < 1) _reveal.forward();
      if (!_flow.isAnimating && _reveal.value >= 1) _flow.repeat();
    } else {
      _reveal.stop();
      _flow.stop();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateVisibility);
    _reveal.dispose();
    _flow.dispose();
    super.dispose();
  }

  void _setHovered(int? index) {
    if (_hoveredNode == index) return;
    setState(() => _hoveredNode = index);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = [
      (Alignment(-0.68, 0.56), 'Commit', Icons.commit_rounded),
      (Alignment(0.04, -0.56), 'Branch', Icons.account_tree_rounded),
      (Alignment(0.76, 0.46), 'Merge', Icons.merge_rounded),
      (Alignment(-0.40, -0.04), 'Branch', Icons.call_split_rounded),
      (Alignment(0.52, 0.66), 'Commit', Icons.commit_rounded),
    ];
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_reveal, _flow]),
        builder: (context, _) => Stack(
          key: _paintKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _AnimatedBranchPainter(
                  reveal: _reveal.value,
                  flow: _flow.value,
                  hoveredNode: _hoveredNode,
                ),
              ),
            ),
            for (var index = 0; index < nodes.length; index++)
              Align(
                alignment: nodes[index].$1,
                child: Tooltip(
                  message: nodes[index].$2,
                  child: MouseRegion(
                    onEnter: (_) => _setHovered(index),
                    onExit: (_) => _setHovered(null),
                    child: GestureDetector(
                      onTap: () =>
                          _setHovered(_hoveredNode == index ? null : index),
                      child: SizedBox(width: 42, height: 42),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBranchPainter extends CustomPainter {
  const _AnimatedBranchPainter({
    required this.reveal,
    required this.flow,
    required this.hoveredNode,
  });

  final double reveal;
  final double flow;
  final int? hoveredNode;

  @override
  void paint(Canvas canvas, Size size) {
    final paths = _branchPaths(size);
    final blue = paths.first;
    final purple = paths.last;
    _drawAnimatedPath(
      canvas,
      blue,
      const Color(0xFF75AEFF),
      reveal: reveal,
      flow: flow,
      highlighted: hoveredNode == 0 || hoveredNode == 2,
      particleOffset: 0,
    );
    _drawAnimatedPath(
      canvas,
      purple,
      const Color(0xFFAC91FF),
      reveal: reveal,
      flow: flow,
      highlighted: hoveredNode == 3 || hoveredNode == 4,
      particleOffset: 0.42,
    );

    final nodes = [
      (Offset(size.width * 0.16, size.height * 0.78), const Color(0xFF0056FF)),
      (Offset(size.width * 0.52, size.height * 0.22), const Color(0xFF14C8F5)),
      (Offset(size.width * 0.88, size.height * 0.73), const Color(0xFF0056FF)),
      (Offset(size.width * 0.30, size.height * 0.48), const Color(0xFF7C3AED)),
      (Offset(size.width * 0.76, size.height * 0.83), const Color(0xFF14C8F5)),
    ];
    var mergePulse = 0.0;
    for (var index = 0; index < 3; index++) {
      final progress = (flow + index / 3) % 1;
      mergePulse = math.max(
        mergePulse,
        ((progress - 0.94) / 0.06).clamp(0.0, 1.0),
      );
    }
    for (var index = 0; index < nodes.length; index++) {
      final appearing = (reveal * 5 - index * 0.32).clamp(0.0, 1.0);
      if (appearing <= 0) continue;
      final pulse = 0.5 + 0.5 * math.sin((flow * 2 * math.pi) + index);
      _drawGlowNode(
        canvas,
        nodes[index].$1,
        nodes[index].$2,
        7 * appearing,
        opacity: _motionlessReveal
            ? 0.5
            : 0.25 + pulse * 0.3 + (index == 2 ? mergePulse * 0.35 : 0),
        scale: hoveredNode == index
            ? 1.35
            : 1 + pulse * 0.05 + (index == 2 ? mergePulse * 0.22 : 0),
      );
    }
    _drawLabel(canvas, 'commit', Offset(size.width * 0.08, size.height * 0.88));
    _drawLabel(canvas, 'merge', Offset(size.width * 0.72, size.height * 0.59));
  }

  bool get _motionlessReveal => flow == 0;

  @override
  bool shouldRepaint(covariant _AnimatedBranchPainter oldDelegate) =>
      reveal != oldDelegate.reveal ||
      flow != oldDelegate.flow ||
      hoveredNode != oldDelegate.hoveredNode;
}

List<Path> _branchPaths(Size size) {
  final branch = Path()
    ..moveTo(size.width * 0.16, size.height * 0.78)
    ..cubicTo(
      size.width * 0.35,
      size.height * 0.75,
      size.width * 0.3,
      size.height * 0.22,
      size.width * 0.52,
      size.height * 0.22,
    )
    ..cubicTo(
      size.width * 0.76,
      size.height * 0.22,
      size.width * 0.64,
      size.height * 0.73,
      size.width * 0.88,
      size.height * 0.73,
    );
  final secondary = Path()
    ..moveTo(size.width * 0.30, size.height * 0.48)
    ..cubicTo(
      size.width * 0.54,
      size.height * 0.46,
      size.width * 0.56,
      size.height * 0.83,
      size.width * 0.76,
      size.height * 0.83,
    );
  return [branch, secondary];
}

void _drawAnimatedPath(
  Canvas canvas,
  Path path,
  Color color, {
  required double reveal,
  required double flow,
  required bool highlighted,
  required double particleOffset,
  bool reverseParticles = false,
}) {
  final metrics = path.computeMetrics().toList();
  if (metrics.isEmpty) return;
  final metric = metrics.first;
  final visibleLength = metric.length * reveal.clamp(0.0, 1.0);
  final visiblePath = metric.extractPath(0, visibleLength);
  canvas.drawPath(
    visiblePath,
    Paint()
      ..color = color.withValues(alpha: highlighted ? 0.34 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 10 : 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawPath(
    visiblePath,
    Paint()
      ..color = color.withValues(alpha: highlighted ? 1 : 0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 3.2 : 2.4
      ..strokeCap = StrokeCap.round,
  );
  if (reveal < 1 || flow == 0) return;
  for (var index = 0; index < 3; index++) {
    final position = (flow + particleOffset + index / 3) % 1;
    final distance =
        metric.length * (reverseParticles ? 1 - position : position);
    final trailDirection = reverseParticles ? 1 : -1;
    final trail = <Tangent?>[
      metric.getTangentForOffset(
        (distance + trailDirection * metric.length * 0.035).clamp(
          0.0,
          metric.length,
        ),
      ),
      metric.getTangentForOffset(
        (distance + trailDirection * metric.length * 0.018).clamp(
          0.0,
          metric.length,
        ),
      ),
      metric.getTangentForOffset(distance),
    ];
    for (var trailIndex = 0; trailIndex < trail.length; trailIndex++) {
      final tangent = trail[trailIndex];
      if (tangent == null) continue;
      final opacity = (trailIndex + 1) / trail.length;
      final radius = trailIndex == trail.length - 1 ? 3.3 : 2.2;
      canvas.drawCircle(
        tangent.position,
        radius + 3,
        Paint()..color = color.withValues(alpha: 0.12 * opacity),
      );
      canvas.drawCircle(
        tangent.position,
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
      canvas.drawCircle(
        tangent.position,
        radius - 1,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }
}

void _drawGlowNode(
  Canvas canvas,
  Offset center,
  Color color,
  double radius, {
  required double opacity,
  required double scale,
}) {
  canvas.drawCircle(
    center,
    (radius + 7) * scale,
    Paint()..color = color.withValues(alpha: opacity * 0.20),
  );
  canvas.drawCircle(
    center,
    radius * scale,
    Paint()
      ..color = color.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawCircle(
    center,
    (radius - 2) * scale,
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(center, (radius - 4) * scale, Paint()..color = color);
}

class _AnimatedRepositoryNetwork extends StatefulWidget {
  const _AnimatedRepositoryNetwork({
    required this.scrollController,
    required this.repositoryName,
  });

  final ScrollController scrollController;
  final String? repositoryName;

  @override
  State<_AnimatedRepositoryNetwork> createState() =>
      _AnimatedRepositoryNetworkState();
}

class _AnimatedRepositoryNetworkState extends State<_AnimatedRepositoryNetwork>
    with TickerProviderStateMixin {
  final _networkKey = GlobalKey();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _motionDisabled = false;
  bool _isVisible = false;
  int? _hoveredNode;

  @override
  void initState() {
    super.initState();
    _reveal.addStatusListener(_onRevealStatus);
    widget.scrollController.addListener(_updateVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isVisible && !_motionDisabled) {
      _flow.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionDisabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled) {
      _flow.stop();
      _reveal
        ..stop()
        ..value = 1;
    } else {
      _updateVisibility();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedRepositoryNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController == widget.scrollController) return;
    oldWidget.scrollController.removeListener(_updateVisibility);
    widget.scrollController.addListener(_updateVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  void _updateVisibility() {
    if (!mounted || !widget.scrollController.hasClients) return;
    final renderObject = _networkKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final visible =
        top < MediaQuery.sizeOf(context).height &&
        top + renderObject.size.height > 0;
    _isVisible = visible;
    if (_motionDisabled) {
      if (_reveal.value != 1) setState(() => _reveal.value = 1);
      return;
    }
    if (visible) {
      if (!_reveal.isAnimating && _reveal.value < 1) _reveal.forward();
      if (!_flow.isAnimating && _reveal.value >= 1) _flow.repeat();
    } else {
      _reveal.stop();
      _flow.stop();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateVisibility);
    _reveal.dispose();
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = const [
      _EngineeringNode('Commits', Icons.commit_rounded, Color(0xFF0056FF)),
      _EngineeringNode('Issues', Icons.bug_report_outlined, Color(0xFF14C8F5)),
      _EngineeringNode('Pull requests', Icons.merge_rounded, Color(0xFF7C3AED)),
      _EngineeringNode(
        'CI / CD',
        Icons.account_tree_rounded,
        Color(0xFF14C8F5),
      ),
      _EngineeringNode('Code files', Icons.code_rounded, Color(0xFF0056FF)),
      _EngineeringNode(
        'Contributors',
        Icons.groups_2_outlined,
        Color(0xFF12A878),
      ),
    ];
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final nodeWidth = constraints.maxWidth < 360 ? 72.0 : 88.0;
          final nodeHeight = 54.0;
          return AnimatedBuilder(
            animation: Listenable.merge([_reveal, _flow]),
            builder: (context, _) {
              return Stack(
                key: _networkKey,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RepositoryNetworkPainter(
                        reveal: ((_reveal.value - 0.2) / 0.8).clamp(0.0, 1.0),
                        flow: _flow.value,
                        hoveredNode: _hoveredNode,
                      ),
                    ),
                  ),
                  for (var index = 0; index < nodes.length; index++)
                    Align(
                      alignment: _nodeAlignments[index],
                      child: _EngineeringNodeSurface(
                        node: nodes[index],
                        width: nodeWidth,
                        height: nodeHeight,
                        visible: _reveal.value >= 0.34 + index * 0.09,
                        floatOffset: _motionDisabled
                            ? 0
                            : math.sin((_flow.value * 2 * math.pi) + index) *
                                  3.5,
                        highlighted: _hoveredNode == index,
                        onHover: (hovered) => setState(
                          () => _hoveredNode = hovered ? index : null,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.center,
                    child: _RepositoryCore(
                      repositoryName:
                          widget.repositoryName ?? 'No repository connected',
                      scale: _motionDisabled
                          ? 1
                          : 0.985 + 0.015 * math.sin(_flow.value * 2 * math.pi),
                      verticalOffset: _motionDisabled
                          ? 0
                          : math.sin(_flow.value * 2 * math.pi) * 2.5,
                      visible: _reveal.value > 0,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

const _nodeAlignments = [
  Alignment(-0.76, -0.72),
  Alignment(0.76, -0.72),
  Alignment(0.76, 0.02),
  Alignment(0.76, 0.72),
  Alignment(-0.76, 0.72),
  Alignment(-0.76, 0.02),
];

class _EngineeringNode {
  const _EngineeringNode(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _EngineeringNodeSurface extends StatelessWidget {
  const _EngineeringNodeSurface({
    required this.node,
    required this.width,
    required this.height,
    required this.visible,
    required this.floatOffset,
    required this.highlighted,
    required this.onHover,
  });

  final _EngineeringNode node;
  final double width;
  final double height;
  final bool visible;
  final double floatOffset;
  final bool highlighted;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Transform.translate(
          offset: Offset(0, floatOffset),
          child: MouseRegion(
            onEnter: (_) => onHover(true),
            onExit: (_) => onHover(false),
            child: Tooltip(
              message: node.label,
              child: AnimatedScale(
                scale: highlighted ? 1.08 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: width,
                  height: height,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.92
                          : 0.96,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: node.color.withValues(
                        alpha: highlighted ? 0.72 : 0.30,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: node.color.withValues(
                          alpha: highlighted ? 0.20 : 0.09,
                        ),
                        blurRadius: highlighted ? 20 : 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(node.icon, size: 18, color: node.color),
                      const SizedBox(height: 4),
                      Text(
                        node.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          color: colors.primaryText,
                          size: width < 80 ? 8 : 9,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryCore extends StatelessWidget {
  const _RepositoryCore({
    required this.repositoryName,
    required this.scale,
    required this.verticalOffset,
    required this.visible,
  });

  final String repositoryName;
  final double scale;
  final double verticalOffset;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      child: Transform.translate(
        offset: Offset(0, verticalOffset),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 184,
            height: 122,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [colors.surfaceElevated, colors.surfaceSecondary]
                    : const [Colors.white, Color(0xFFF0F6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? colors.border
                    : const Color(0xFF9DC4FF),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colors.surfaceSecondary.withValues(alpha: 0.35)
                      : Colors.white,
                  blurRadius: 1,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colors.surfaceSecondary
                        : const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.folder_copy_rounded,
                        color: _blue,
                        size: 22,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.code_rounded,
                            color: Color(0xFF7C3AED),
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  repositoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: _textStyle(size: 10, weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'SOURCE REPOSITORY',
                  style: _textStyle(
                    color: colors.mutedText,
                    size: 8,
                    weight: FontWeight.w700,
                  ).copyWith(letterSpacing: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryNetworkPainter extends CustomPainter {
  const _RepositoryNetworkPainter({
    required this.reveal,
    required this.flow,
    required this.hoveredNode,
  });

  final double reveal;
  final double flow;
  final int? hoveredNode;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final anchors = _nodeAlignments
        .map(
          (alignment) => Offset(
            (alignment.x + 1) * size.width / 2,
            (alignment.y + 1) * size.height / 2,
          ),
        )
        .toList();
    for (var index = 0; index < anchors.length; index++) {
      final target = anchors[index];
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..cubicTo(
          center.dx + (target.dx - center.dx) * 0.22,
          center.dy + (target.dy - center.dy) * 0.05,
          center.dx + (target.dx - center.dx) * 0.78,
          target.dy,
          target.dx,
          target.dy,
        );
      final color = index == 2
          ? const Color(0xFF9B82ED)
          : index.isEven
          ? const Color(0xFF2277FF)
          : const Color(0xFF14C8F5);
      _drawAnimatedPath(
        canvas,
        path,
        color,
        reveal: reveal,
        flow: flow,
        highlighted: hoveredNode == index,
        particleOffset: index / anchors.length,
        reverseParticles: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RepositoryNetworkPainter oldDelegate) =>
      reveal != oldDelegate.reveal ||
      flow != oldDelegate.flow ||
      hoveredNode != oldDelegate.hoveredNode;
}

void _drawLabel(Canvas canvas, String label, Offset position) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Color(0xFF71809A),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, position);
}
