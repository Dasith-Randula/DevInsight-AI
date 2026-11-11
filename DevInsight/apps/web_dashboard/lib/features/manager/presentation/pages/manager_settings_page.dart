part of '../widgets/manager_workspace_pages.dart';

class ManagerSettingsView extends StatelessWidget {
  const ManagerSettingsView({super.key, required this.data});

  final ManagerWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final themeController = ThemeControllerScope.maybeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardPageHeading(
          controller: data.scrollController,
          eyebrow: 'Workspace settings',
          title: 'Your account, your workspace.',
          description:
              'Profile and repository details below are read from the authenticated account and existing GitHub connections.',
        ),
        const DashboardSectionHeading(
          label: 'Profile & account',
          title: 'Signed in as a Project Manager.',
          description:
              'Role assignment is managed by the authenticated account and is not editable from this prototype.',
        ),
        const SizedBox(height: 16),
        _SettingsPanel(
          children: [
            _SettingsLine(label: 'Name', value: _displayName(data.profile)),
            _SettingsLine(
              label: 'Email',
              value: data.profile.email?.trim().isNotEmpty == true
                  ? data.profile.email!
                  : 'Unavailable',
            ),
            _SettingsLine(label: 'Role', value: _roleLabel(data.profile.role)),
            _SettingsLine(
              label: 'Onboarding',
              value: data.profile.onboardingCompleted
                  ? 'Completed'
                  : 'Status unavailable',
            ),
          ],
        ),
        const SizedBox(height: 34),
        const DashboardSectionHeading(
          label: 'Connected repositories',
          title: 'Your active project connections.',
          description:
              'Choose a repository under Projects to change the active context. Connection management uses the existing GitHub API.',
        ),
        const SizedBox(height: 14),
        if (data.repositories.isEmpty)
          DashboardEmptyState(
            icon: Icons.link_off_rounded,
            title: 'No connected repositories',
            description:
                'Repository settings will appear here after a connection is added.',
            action: TextButton(
              onPressed: () => data.onNavigate(ManagerDestination.projects),
              child: const Text('Open Projects'),
            ),
          )
        else
          _SettingsPanel(
            children: data.repositories
                .map(
                  (repository) => _SettingsLine(
                    label: repository.fullName,
                    value: repository.id == data.repository?.id
                        ? 'Active project'
                        : (repository.isPrivate ? 'Private' : 'Public'),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 34),
        const DashboardSectionHeading(
          label: 'Appearance',
          title: 'Choose your reading mode.',
          description:
              'Theme preference is saved by the existing application theme controller.',
        ),
        const SizedBox(height: 12),
        _SettingsPanel(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Light and dark appearance',
                    style: dashboardTextStyle(
                      color: colors.primaryText,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                if (themeController != null)
                  ThemeToggleButton(controller: themeController),
              ],
            ),
          ],
        ),
        const SizedBox(height: 34),
        const DashboardSectionHeading(
          label: 'Notifications & integrations',
          title: 'Unsupported preferences stay read-only.',
          description:
              'Notification preferences and additional integrations are not backed by workspace settings APIs yet.',
        ),
        const SizedBox(height: 12),
        const _SettingsPanel(
          children: [
            _SettingsLine(label: 'Notifications', value: 'Unavailable'),
            _SettingsLine(
              label: 'Additional integrations',
              value: 'Not connected',
            ),
            _SettingsLine(
              label: 'Security',
              value: 'Managed by your signed-in account',
            ),
          ],
        ),
        const SizedBox(height: 34),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: data.onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ),
      ],
    );
  }
}
