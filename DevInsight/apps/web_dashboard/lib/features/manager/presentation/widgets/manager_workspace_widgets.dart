part of 'manager_workspace_pages.dart';

class _ManagerHero extends StatelessWidget {
  const _ManagerHero({
    required this.title,
    required this.description,
    required this.tag,
    required this.animation,
    required this.actions,
    required this.greeting,
    required this.role,
  });

  final String title;
  final String description;
  final String tag;
  final Animation<double> animation;
  final List<Widget> actions;
  final String greeting;
  final String role;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 38),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF135CE5), Color(0xFF197DE5), Color(0xFF13A9D0)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1769E8).withValues(alpha: .18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: .2)),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 31 : 43,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Wrap(spacing: 10, runSpacing: 9, children: actions),
              const SizedBox(height: 25),
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white.withValues(alpha: .18),
                    child: Text(
                      greeting
                          .replaceFirst('Welcome, ', '')
                          .characters
                          .first
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '$greeting  ·  $role',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .92),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
          if (narrow) return content;
          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 30),
              _HeroOrbit(animation: animation),
            ],
          );
        },
      ),
    );
  }
}

class _HeroOrbit extends StatelessWidget {
  const _HeroOrbit({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: const Icon(
        Icons.account_tree_rounded,
        color: Colors.white,
        size: 28,
      ),
      builder: (context, icon) {
        final progress = animation.value;
        final phase = progress * 2 * math.pi;
        final pulse = (math.sin(phase) + 1) / 2;
        final ringSizes = [196.0, 145.0, 92.0];
        final ringSpeeds = [1.0, -0.72, 0.48];

        return Transform.translate(
          offset: Offset(0, math.sin(phase) * 2),
          child: SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final (index, size) in ringSizes.indexed)
                  Transform.rotate(
                    angle: phase * ringSpeeds[index],
                    child: Transform.scale(
                      scaleY: .97,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .24),
                          ),
                        ),
                      ),
                    ),
                  ),
                for (final (index, orbit) in [
                  (phase, 80.0),
                  (-phase + 1.4, 58.0),
                ].indexed)
                  Transform.translate(
                    offset: Offset(
                      math.cos(orbit.$1) * orbit.$2,
                      math.sin(orbit.$1) * orbit.$2,
                    ),
                    child: Container(
                      width: index == 0 ? 10 : 8,
                      height: index == 0 ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == 0
                            ? const Color(0xFF9FF4FF)
                            : const Color(0xFFB4D6FF),
                        boxShadow: [
                          BoxShadow(
                            color: (index == 0
                                    ? const Color(0xFF9FF4FF)
                                    : const Color(0xFFB4D6FF))
                                .withValues(alpha: .72),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: .1 + pulse * .08,
                        ),
                        blurRadius: 18 + pulse * 8,
                      ),
                    ],
                  ),
                  child: icon,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RepositorySnapshot extends StatelessWidget {
  const _RepositorySnapshot({
    required this.data,
    required this.repository,
    required this.overview,
  });

  final ManagerWorkspaceData data;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    if (repository == null) {
      return DashboardEmptyState(
        icon: Icons.account_tree_outlined,
        title: data.loading
            ? 'Loading project context'
            : 'No active repository',
        description:
            data.error ??
            'Connect a public GitHub repository to bring actual project signals into this workspace.',
        action: data.loading
            ? const SizedBox(
                width: 160,
                child: LinearProgressIndicator(minHeight: 2),
              )
            : Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (data.error != null)
                    OutlinedButton.icon(
                      onPressed: data.onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  FilledButton.icon(
                    onPressed: data.onConnectRepository,
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Connect repository'),
                  ),
                ],
              ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .94 : .84,
        ),
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.code_rounded,
                    color: dashboardBlue,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      repository!.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dashboardTextStyle(
                        color: colors.primaryText,
                        size: 17,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (overview?.isStale == true)
                    const _StatusTag(label: 'CACHED / STALE'),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                repository!.description?.trim().isNotEmpty == true
                    ? repository!.description!
                    : 'No repository description is available.',
                style: dashboardTextStyle(
                  color: colors.mutedText,
                  size: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 22,
                runSpacing: 12,
                children: [
                  _InlineDatum(
                    label: 'Default branch',
                    value: repository!.defaultBranch ?? 'Unavailable',
                  ),
                  _InlineDatum(
                    label: 'Primary language',
                    value: repository!.primaryLanguage ?? 'Unavailable',
                  ),
                  _InlineDatum(
                    label: 'Last sync',
                    value: _dateOrUnavailable(repository!.lastSyncedAt),
                  ),
                  _InlineDatum(
                    label: 'Connection',
                    value: repository!.isPrivate ? 'Private' : 'Public',
                  ),
                ],
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            children: [
              if (data.repositories.length > 1)
                PopupMenuButton<String>(
                  tooltip: 'Select active repository',
                  onSelected: (id) {
                    final selected = data.repositories.firstWhere(
                      (item) => item.id == id,
                    );
                    data.onSelectRepository(selected);
                  },
                  itemBuilder: (context) => data.repositories
                      .map(
                        (item) => PopupMenuItem(
                          value: item.id,
                          child: Text(
                            item.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              IconButton(
                onPressed: data.refreshing ? null : data.onRefresh,
                tooltip: 'Refresh repository overview',
                icon: data.refreshing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                onPressed: () => data.onOpenLink(repository!.url),
                tooltip: 'Open repository on GitHub',
                icon: const Icon(Icons.open_in_new_rounded),
              ),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ProjectPortfolioRow extends StatelessWidget {
  const _ProjectPortfolioRow({
    required this.repository,
    required this.active,
    required this.index,
    required this.onSelect,
    required this.onOpen,
  });

  final GitHubRepositoryConnection repository;
  final bool active;
  final int index;
  final VoidCallback onSelect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: active ? colors.surfaceSecondary : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: active
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .5)
                    : colors.border,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    (index + 1).toString().padLeft(2, '0'),
                    style: dashboardTextStyle(
                      color: dashboardBlue,
                      size: 11,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.folder_copy_outlined, size: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repository.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dashboardTextStyle(
                          color: colors.primaryText,
                          size: 13,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        repository.description?.trim().isNotEmpty == true
                            ? repository.description!
                            : 'No description available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dashboardTextStyle(
                          color: colors.mutedText,
                          size: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (active)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: _StatusTag(label: 'ACTIVE'),
                  ),
                IconButton(
                  onPressed: onOpen,
                  tooltip: 'Open on GitHub',
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageComposition extends StatelessWidget {
  const _LanguageComposition({required this.languages});

  final List<GitHubLanguage> languages;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeading(
          label: 'Language composition',
          title: 'What the repository is written in.',
          description:
              'Percentages are supplied by the existing repository overview; no language shares are inferred.',
        ),
        const SizedBox(height: 14),
        if (languages.isEmpty)
          const DashboardEmptyState(
            icon: Icons.data_object_rounded,
            title: 'Language data unavailable',
            description:
                'No language composition was returned for this overview.',
          )
        else
          for (final language in languages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 115,
                    child: Text(
                      language.name,
                      overflow: TextOverflow.ellipsis,
                      style: dashboardTextStyle(
                        color: colors.primaryText,
                        size: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (language.percentage / 100).clamp(0, 1),
                        minHeight: 7,
                        backgroundColor: colors.border,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${language.percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: dashboardTextStyle(
                        color: colors.mutedText,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _IssueControls extends StatelessWidget {
  const _IssueControls({
    required this.controller,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final String filter;
  final VoidCallback onQueryChanged;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    final search = TextField(
      controller: controller,
      onChanged: (_) => onQueryChanged(),
      decoration: const InputDecoration(
        hintText: 'Search title, number, author, label',
        prefixIcon: Icon(Icons.search_rounded),
        isDense: true,
      ),
    );
    final filters = Wrap(
      spacing: 7,
      children: [
        for (final option in ['All', 'Open', 'Closed'])
          ChoiceChip(
            label: Text(option),
            selected: filter == option,
            onSelected: (_) => onFilterChanged(option),
          ),
      ],
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [search, const SizedBox(height: 10), filters],
      );
    }
    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 12),
        filters,
      ],
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.onOpen});

  final GitHubActivity issue;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final open = issue.state?.toLowerCase() == 'open';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            open
                ? Icons.radio_button_unchecked_rounded
                : Icons.check_circle_outline_rounded,
            size: 19,
            color: open ? const Color(0xFF15A578) : colors.mutedText,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${issue.number == null ? '' : '#${issue.number}  '}${issue.title}',
                  style: dashboardTextStyle(
                    color: colors.primaryText,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    Text(
                      '${issue.state ?? 'State unavailable'} · ${issue.author.isEmpty ? 'Author unavailable' : issue.author}',
                      style: dashboardTextStyle(
                        color: colors.mutedText,
                        size: 10,
                      ),
                    ),
                    if (issue.createdAt != null || issue.date != null)
                      Text(
                        'Created ${_date(issue.createdAt ?? issue.date)}',
                        style: dashboardTextStyle(
                          color: colors.mutedText,
                          size: 10,
                        ),
                      ),
                    for (final label in issue.labels) _StatusTag(label: label),
                  ],
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              onPressed: onOpen,
              tooltip: 'Open issue on GitHub',
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
            ),
        ],
      ),
    );
  }
}

class _ContributorPill extends StatelessWidget {
  const _ContributorPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: dashboardBlue.withValues(alpha: .12),
            child: Text(
              name.characters.first.toUpperCase(),
              style: dashboardTextStyle(
                color: dashboardBlue,
                size: 10,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 9),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dashboardTextStyle(
                color: colors.primaryText,
                size: 11,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({
    required this.weeks,
    required this.maximum,
    required this.complete,
  });

  final List<GitHubWeeklyCommit> weeks;
  final int maximum;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 5,
            children: [
              Text(
                'Weekly commits',
                style: dashboardTextStyle(
                  color: colors.primaryText,
                  size: 13,
                  weight: FontWeight.w800,
                ),
              ),
              _StatusTag(
                label: complete ? 'COMPLETE WINDOW' : 'PARTIAL WINDOW',
              ),
            ],
          ),
          const SizedBox(height: 19),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (index, week) in weeks.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (week.commits != null)
                            Text(
                              '${week.commits}',
                              style: dashboardTextStyle(
                                color: colors.mutedText,
                                size: 8,
                              ),
                            ),
                          const SizedBox(height: 5),
                          Tooltip(
                            message:
                                '${_date(week.weekStart)}: ${week.commits == null ? 'not measured' : '${week.commits} commits'}',
                            child: Container(
                              height:
                                  84 *
                                  (week.commits == null || maximum == 0
                                      ? .04
                                      : week.commits! / maximum),
                              decoration: BoxDecoration(
                                color: week.commits == null
                                    ? colors.border
                                    : Color.lerp(
                                        dashboardCyan,
                                        dashboardBlue,
                                        week.commits! /
                                            (maximum == 0 ? 1 : maximum),
                                      ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _shortDate(week.weekStart, index, weeks.length),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: dashboardTextStyle(
                              color: colors.mutedText,
                              size: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSignals extends StatelessWidget {
  const _AnalyticsSignals({
    required this.quality,
    required this.health,
    required this.loading,
  });

  final GitHubQualitySignals? quality;
  final GitHubRepositoryHealth? health;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ci = quality?.ci;
    final rows = <(String, String)>[
      ('CI/CD', ci?.availability == 'available' ? ci!.state : 'Unavailable'),
      ('Default branch', quality?.defaultBranch ?? 'Unavailable'),
      ('README detected', _boolValue(quality?.readmePresent)),
      ('License detected', _boolValue(quality?.licensePresent)),
      ('Tests detected', _boolValue(quality?.testsDetected)),
      ('Latest push', _dateOrUnavailable(health?.lastPushAt)),
    ];
    return _SettingsPanel(
      children: [
        for (final row in rows)
          _SettingsLine(label: row.$1, value: loading ? 'Loading' : row.$2),
      ],
    );
  }
}

class _ReportBrief extends StatelessWidget {
  const _ReportBrief({
    required this.label,
    required this.title,
    required this.body,
    required this.rows,
  });

  final String label;
  final String title;
  final String body;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: dashboardTextStyle(
              color: dashboardBlue,
              size: 9,
              weight: FontWeight.w800,
            ).copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: dashboardTextStyle(
              color: colors.primaryText,
              size: 18,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: dashboardTextStyle(
              color: colors.mutedText,
              size: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          for (final row in rows) _SettingsLine(label: row.$1, value: row.$2),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.title,
    required this.description,
    required this.activities,
    required this.loading,
    required this.repository,
    required this.onOpenLink,
  });

  final String title;
  final String description;
  final List<GitHubActivity> activities;
  final bool loading;
  final GitHubRepositoryConnection? repository;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeading(
          label: 'Activity timeline',
          title: title,
          description: description,
        ),
        const SizedBox(height: 14),
        if (loading && activities.isEmpty)
          const LinearProgressIndicator(minHeight: 2)
        else if (activities.isEmpty)
          DashboardEmptyState(
            icon: Icons.history_rounded,
            title: repository == null
                ? 'Connect a repository to see activity'
                : 'No recent activity in this snapshot',
            description:
                'No sample events are created when the API returns none.',
          )
        else
          for (final activity in activities.take(8))
            _ActivityRow(
              activity: activity,
              onOpen: activity.url.isEmpty
                  ? null
                  : () => onOpenLink(activity.url),
            ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.onOpen});

  final GitHubActivity activity;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final (icon, label, iconColor) = switch (activity.type) {
      'issue' => (Icons.adjust_rounded, 'Issue', const Color(0xFF15A578)),
      'pull_request' => (
        Icons.merge_type_rounded,
        'Pull request',
        dashboardBlue,
      ),
      'commit' => (Icons.commit_rounded, 'Commit', const Color(0xFF8A65D6)),
      _ => (Icons.circle_outlined, activity.type, colors.mutedText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: dashboardTextStyle(
                    color: colors.primaryText,
                    size: 11,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$label${activity.number == null ? '' : ' #${activity.number}'} · ${_author(activity.author)}${activity.state == null ? '' : ' · ${activity.state}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dashboardTextStyle(color: colors.mutedText, size: 9),
                ),
              ],
            ),
          ),
          if (activity.date != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _date(activity.date),
                style: dashboardTextStyle(color: colors.mutedText, size: 9),
              ),
            ),
          if (onOpen != null)
            IconButton(
              onPressed: onOpen,
              tooltip: 'Open on GitHub',
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
            ),
        ],
      ),
    );
  }
}

class _UpcomingBand extends StatelessWidget {
  const _UpcomingBand({
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String description;
  final String badge;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusTag(label: badge),
              const SizedBox(height: 12),
              Text(
                title,
                style: dashboardTextStyle(
                  color: colors.primaryText,
                  size: 20,
                  weight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                description,
                style: dashboardTextStyle(
                  color: colors.mutedText,
                  size: 11,
                  height: 1.65,
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: dashboardBlue),
                const SizedBox(height: 14),
                text,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dashboardBlue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: dashboardBlue),
              ),
              const SizedBox(width: 18),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  const _SettingsLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dashboardTextStyle(color: colors.mutedText, size: 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: dashboardTextStyle(
                color: colors.primaryText,
                size: 11,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineDatum extends StatelessWidget {
  const _InlineDatum({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: dashboardTextStyle(
              color: colors.mutedText,
              size: 8,
              weight: FontWeight.w700,
            ).copyWith(letterSpacing: .5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: dashboardTextStyle(
              color: colors.primaryText,
              size: 10,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CiSignal extends StatelessWidget {
  const _CiSignal({required this.state, required this.completedAt});

  final String state;
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Row(
      children: [
        const Icon(Icons.sync_alt_rounded, color: dashboardBlue, size: 19),
        const SizedBox(width: 9),
        Text(
          'CI/CD',
          style: dashboardTextStyle(
            color: colors.primaryText,
            size: 11,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        _StatusTag(label: state.toUpperCase()),
        if (completedAt != null) ...[
          const SizedBox(width: 10),
          Text(
            'Last completed ${_date(completedAt)}',
            style: dashboardTextStyle(color: colors.mutedText, size: 9),
          ),
        ],
      ],
    );
  }
}

class _UnavailableLine extends StatelessWidget {
  const _UnavailableLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      _SettingsLine(label: label, value: value);
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: dashboardBlue.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: dashboardTextStyle(
          color: dashboardBlue,
          size: 8,
          weight: FontWeight.w800,
        ).copyWith(letterSpacing: .35),
      ),
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.data});

  final ManagerWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final error = data.error;
    if (error == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardInlineNotice(
          message: data.overview == null
              ? 'Repository data could not be loaded: $error'
              : 'Showing the available repository snapshot after a refresh error: $error',
          stale: data.overview != null,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: data.onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Retry repository request'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

String _displayName(CurrentUserProfile profile) {
  final name = profile.fullName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final email = profile.email?.trim();
  if (email != null && email.contains('@')) return email.split('@').first;
  return 'Project Manager';
}

String _roleLabel(String? role) {
  final normalized = role?.trim().toLowerCase().replaceAll('_', ' ');
  if (normalized == null || normalized.isEmpty || normalized == 'manager') {
    return 'Project Manager';
  }
  if (normalized == 'project manager') return 'Project Manager';
  return role!.trim();
}

String _author(String author) =>
    author.trim().isEmpty || author.toLowerCase() == 'unknown author'
    ? 'Author unavailable'
    : author;

String _value(int? value, {required bool loading}) =>
    value?.toString() ?? (loading ? '…' : '—');

String _dateOrUnavailable(DateTime? date) =>
    date == null ? 'Unavailable' : _date(date);

String _date(DateTime? date) {
  if (date == null) return 'Unavailable';
  final local = date.toLocal();
  return '${_month(local.month)} ${local.day}, ${local.year}';
}

String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

String _shortDate(DateTime date, int index, int total) {
  if (total > 8 && index != 0 && index != total - 1 && index % 2 != 0) {
    return '';
  }
  final local = date.toLocal();
  return '${local.month}/${local.day}';
}

String _boolValue(bool? value) => switch (value) {
  true => 'Yes',
  false => 'No',
  null => 'Unavailable',
};
