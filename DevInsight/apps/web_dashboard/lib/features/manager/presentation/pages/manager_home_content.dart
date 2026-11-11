part of '../widgets/manager_workspace_pages.dart';

class ManagerHomeView extends StatelessWidget {
  const ManagerHomeView({
    super.key,
    required this.data,
    required this.scrollController,
    required this.ambientMotion,
  });

  final ManagerWorkspaceData data;
  final ScrollController scrollController;
  final Animation<double> ambientMotion;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(data.profile);
    final overview = data.overview;
    final health = overview?.repositoryHealth;
    final repository = overview?.connection ?? data.repository;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagerHomeIntroduction(
          data: data,
          scrollController: scrollController,
          animation: ambientMotion,
          name: name,
        ),
        const SizedBox(height: 52),
        KeyedSubtree(
          key: data.currentProjectKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const heading = DashboardSectionHeading(
                label: 'Current project',
                title: 'Start with the connected work.',
                description:
                    'Repository details and signals below come from the connected GitHub snapshot. Missing values are shown as unavailable, not as zero.',
              );
              final Widget? action = data.repositories.length > 1
                  ? TextButton.icon(
                      onPressed: () =>
                          data.onNavigate(ManagerDestination.projects),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Change project'),
                    )
                  : data.repositories.length == 1
                  ? TextButton.icon(
                      onPressed: data.onConnectRepository,
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Connect another repository'),
                    )
                  : null;
              if (action == null) return heading;
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: action,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(child: heading),
                  const SizedBox(width: 16),
                  action,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _RepositorySnapshot(
          data: data,
          repository: repository,
          overview: overview,
        ),
        const SizedBox(height: 50),
        DashboardScrollReveal(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardSectionHeading(
                label: 'Project pulse',
                title: 'What the repository is telling you.',
                description:
                    'A concise readout of available issues, pull requests, and recent activity—not a project completion or health score.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 30,
                runSpacing: 22,
                children: [
                  DashboardMetric(
                    label: 'Open issues',
                    value: _value(health?.openIssues, loading: data.loading),
                    detail: 'GitHub repository summary',
                    color: const Color(0xFF15A578),
                  ),
                  DashboardMetric(
                    label: 'Open pull requests',
                    value: _value(
                      overview?.openPullRequests ?? health?.openPullRequests,
                      loading: data.loading,
                    ),
                    detail: 'GitHub repository summary',
                    color: dashboardAzure,
                  ),
                  DashboardMetric(
                    label: 'Closed · 30 days',
                    value: _value(
                      overview?.resolvedIssues30d ?? health?.closedIssues30d,
                      loading: data.loading,
                    ),
                    detail: 'Recently resolved issues',
                    color: const Color(0xFF8A65D6),
                  ),
                  DashboardMetric(
                    label: 'Recent activity',
                    value: _value(
                      overview?.recentActivity.length,
                      loading: data.loading,
                    ),
                    detail: 'Returned activity sample',
                    color: const Color(0xFFE99C28),
                  ),
                ],
              ),
              if (overview?.qualitySignals?.ci.availability == 'available')
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: _CiSignal(
                    state: overview!.qualitySignals!.ci.state,
                    completedAt: overview.qualitySignals!.ci.lastCompletedAt,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: _UnavailableLine(
                    label: 'CI/CD',
                    value: 'Not available in the current repository snapshot',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 54),
        const DashboardSectionHeading(
          label: 'Project direction',
          title: 'From repository signals to team decisions.',
          description:
              'A management workflow for reviewing evidence and agreeing on next steps. It is a guide, not a measure of completed stages.',
        ),
        const SizedBox(height: 20),
        DashboardAnimatedWorkflow(
          controller: scrollController,
          stages: const [
            'Repository activity',
            'Project visibility',
            'Risk review',
            'Prioritization',
            'Team decisions',
          ],
        ),
        const SizedBox(height: 52),
        _UpcomingBand(
          title: 'Risk prediction is on the research roadmap.',
          description:
              'Trained machine-learning predictions are planned for the second half of the research. No risk probabilities or delivery forecasts are produced in this prototype.',
          badge: 'RESEARCH FEATURE · UPCOMING',
          icon: Icons.insights_rounded,
        ),
        const SizedBox(height: 52),
        _ActivityList(
          title: 'Recent repository activity',
          description:
              'Recent commits, issues, and pull requests returned for the selected repository.',
          activities: overview?.recentActivity ?? const [],
          loading: data.loading,
          repository: repository,
          onOpenLink: data.onOpenLink,
        ),
      ],
    );
  }
}

class _ManagerHomeIntroduction extends StatelessWidget {
  const _ManagerHomeIntroduction({
    required this.data,
    required this.scrollController,
    required this.animation,
    required this.name,
  });

  final ManagerWorkspaceData data;
  final ScrollController scrollController;
  final Animation<double> animation;
  final String name;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final desktopHero =
            constraints.maxWidth >= 900 && viewportHeight >= 640;
        final minHeight = desktopHero
            ? (viewportHeight - 78 + 24).clamp(0.0, double.infinity)
            : 0.0;
        final topPadding = desktopHero
            ? (viewportHeight * .045).clamp(28.0, 48.0)
            : (viewportHeight * .022).clamp(14.0, 24.0);
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: desktopHero
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            children: [
              DevInsightAnimatedWordmark(
                animation: animation,
                topPadding: desktopHero ? 16 : 12,
              ),
              SizedBox(height: desktopHero ? topPadding : 18),
              _ManagerHero(
                title: 'Project clarity starts here.',
                description:
                    'A focused view of repository activity, open work, and collaboration signals to support better project decisions.',
                tag: 'PROJECT MANAGER WORKSPACE',
                animation: animation,
                actions: [
                  FilledButton.icon(
                    onPressed: () =>
                        data.onNavigate(ManagerDestination.projects),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('Explore Projects'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF145CC8),
                      overlayColor: const Color(
                        0xFF145CC8,
                      ).withValues(alpha: .12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 13,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => data.onNavigate(ManagerDestination.issues),
                    icon: const Icon(Icons.low_priority_rounded, size: 17),
                    label: const Text('Review Issues'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .74),
                        width: 1.2,
                      ),
                      overlayColor: Colors.white.withValues(alpha: .15),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 13,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                greeting: 'Welcome, $name',
                role: _roleLabel(data.profile.role),
              ),
              if (!desktopHero) const SizedBox(height: 8),
              DashboardScrollIndicator(
                onPressed: () {
                  final target = data.currentProjectKey.currentContext;
                  if (target == null) return;
                  Scrollable.ensureVisible(
                    target,
                    alignment: .1,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOutCubic,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
