import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:web_dashboard/core/theme/theme_controller.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';
import 'package:web_dashboard/shared/widgets/theme_toggle_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.scrollController,
    required this.profile,
    required this.repositories,
    required this.repository,
    required this.authService,
  });

  final ScrollController scrollController;
  final CurrentUserProfile profile;
  final List<GitHubRepositoryConnection> repositories;
  final GitHubRepositoryConnection? repository;
  final AuthService authService;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _sectionKeys = List.generate(7, (_) => GlobalKey());
  OnboardingState? _savedState;
  String? _loadError;
  String? _saveError;
  bool _loading = true;
  bool _saving = false;
  bool _emailEnabled = false;
  bool _pushEnabled = false;
  Set<String> _topics = {};
  int _selectedSection = 0;

  static const _sections = [
    ('Profile', Icons.person_outline_rounded),
    ('Account', Icons.manage_accounts_outlined),
    ('Connected repositories', Icons.folder_open_rounded),
    ('Notifications', Icons.notifications_none_rounded),
    ('Appearance', Icons.palette_outlined),
    ('Security', Icons.shield_outlined),
    ('Integrations', Icons.extension_outlined),
  ];

  static const _notificationTopics = [
    'Critical Risk Alerts',
    'Project Updates',
    'Issue Assignments',
    'AI Recommendations',
    'Project Activity',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!widget.authService.hasSession) {
      setState(() {
        _loading = false;
        _loadError =
            'An authenticated session is required to load saved preferences.';
      });
      return;
    }
    try {
      final saved = await widget.authService.fetchOnboardingState();
      if (!mounted) return;
      setState(() {
        _savedState = saved;
        _emailEnabled = saved.emailEnabled ?? false;
        _pushEnabled = saved.pushEnabled ?? false;
        _topics = saved.notificationTopics.toSet();
        _loading = false;
      });
    } on AuthIntegrationException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    } on DevInsightApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _saveNotifications() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.authService.saveOnboardingNotifications(
        emailEnabled: _emailEnabled,
        pushEnabled: _pushEnabled,
        topics: _topics.toList(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savedState = _savedState == null
            ? null
            : OnboardingState(
                profile: _savedState!.profile,
                nextStep: _savedState!.nextStep,
                interests: _savedState!.interests,
                emailEnabled: _emailEnabled,
                pushEnabled: _pushEnabled,
                notificationTopics: _topics.toList(),
              );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences saved.')),
      );
    } on AuthIntegrationException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.message;
        _saving = false;
      });
    } on DevInsightApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.message;
        _saving = false;
      });
    }
  }

  void _selectSection(int index) {
    setState(() => _selectedSection = index);
    final target = _sectionKeys[index].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: .08,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DashboardPageHeading(
        controller: widget.scrollController,
        eyebrow: 'Workspace preferences',
        title: 'Your workspace, your preferences.',
        description:
            'Review your account and connected project details. Settings are editable only when DevInsight has a supported persistence endpoint.',
      ),
      DashboardScrollReveal(
        controller: widget.scrollController,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final categoryNav = _CategoryNavigation(
              sections: _sections,
              selected: _selectedSection,
              compact: compact,
              onSelect: _selectSection,
            );
            final sections = _settingsSections();
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [categoryNav, const SizedBox(height: 24), sections],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 220, child: categoryNav),
                const SizedBox(width: 38),
                Expanded(child: sections),
              ],
            );
          },
        ),
      ),
    ],
  );

  Widget _settingsSections() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SettingsSection(
        controller: widget.scrollController,
        sectionKey: _sectionKeys[0],
        index: 0,
        title: 'Profile',
        description:
            'Authenticated identity details from your current session.',
        child: Column(
          children: [
            _ReadOnlySetting(
              'Full name',
              _profileValue(widget.profile.fullName),
            ),
            _ReadOnlySetting('Email', _profileValue(widget.profile.email)),
            _ReadOnlySetting('Role', _profileValue(widget.profile.role)),
            _ReadOnlySetting('Profile ID', widget.profile.id),
          ],
        ),
      ),
      _SettingsSection(
        controller: widget.scrollController,
        sectionKey: _sectionKeys[1],
        index: 1,
        title: 'Account',
        description: 'Account state and onboarding information.',
        child: Column(
          children: [
            _ReadOnlySetting(
              'Onboarding',
              widget.profile.onboardingCompleted ? 'Completed' : 'In progress',
            ),
            _ReadOnlySetting(
              'Saved profile',
              _savedState?.profile.fullName ?? 'Not loaded',
            ),
            _ReadOnlySetting(
              'Username',
              _savedState?.profile.username ?? 'Not available',
            ),
          ],
        ),
      ),
      _SettingsSection(
        controller: widget.scrollController,
        sectionKey: _sectionKeys[2],
        index: 2,
        title: 'Connected repositories',
        description: 'These connections are shared by all dashboard pages.',
        child: widget.repositories.isEmpty
            ? const DashboardEmptyState(
                icon: Icons.folder_open_rounded,
                title: 'No connected repositories',
                description:
                    'Connect a repository from Developer Home to see it here.',
              )
            : Column(
                children: [
                  for (final item in widget.repositories)
                    DashboardDataRow(
                      leading: Icon(
                        item.id == widget.repository?.id
                            ? Icons.check_circle_rounded
                            : Icons.folder_outlined,
                      ),
                      title: item.fullName,
                      detail:
                          '${item.primaryLanguage ?? 'Language unavailable'} · ${item.url}',
                      trailing: item.id == widget.repository?.id
                          ? const DashboardStatusTag(
                              'ACTIVE',
                              color: dashboardBlue,
                            )
                          : null,
                    ),
                ],
              ),
      ),
      _SettingsSection(
        controller: widget.scrollController,
        sectionKey: _sectionKeys[3],
        index: 3,
        title: 'Notification preferences',
        description:
            'Email, push, and topics are persisted through the existing onboarding preferences API.',
        child: _notificationSettings(),
      ),
      _SettingsSection(
        controller: widget.scrollController,
        sectionKey: _sectionKeys[4],
        index: 4,
        title: 'Appearance',
        description: 'The current appearance is inherited from the app theme.',
        child: Builder(
          builder: (context) {
            final controller = ThemeControllerScope.maybeOf(context);
            if (controller == null) {
              return const DashboardEmptyState(
                icon: Icons.palette_outlined,
                title: 'Theme preference is managed by the app',
                description:
                    'Theme controls are available when the application theme controller is active.',
              );
            }
            return Row(
              children: [
                ThemeToggleButton(controller: controller),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => Text(
                      controller.isDark
                          ? 'Dark mode is active across the application.'
                          : 'Light mode is active across the application.',
                      style: dashboardTextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      _SettingsSection(
        controller: widget.scrollController,
        sectionKey: _sectionKeys[5],
        index: 5,
        title: 'Security',
        description: 'Your session and credential safety.',
        child: const DashboardEmptyState(
          icon: Icons.shield_outlined,
          title: 'Session protected by Supabase authentication',
          description:
              'DevInsight does not expose access tokens or provide password controls on this page. Use the supported account recovery flow for credentials.',
        ),
      ),
      _SettingsSection(
        controller: widget.scrollController,
        sectionKey: _sectionKeys[6],
        index: 6,
        title: 'Integrations',
        description: 'Connected services available in this workspace.',
        child: Column(
          children: [
            _ReadOnlySetting(
              'GitHub',
              widget.repositories.isEmpty
                  ? 'No repositories connected'
                  : '${widget.repositories.length} public repository connection${widget.repositories.length == 1 ? '' : 's'}',
            ),
            const _ReadOnlySetting(
              'FastAPI',
              'Available through authenticated DevInsight API calls',
            ),
            const _ReadOnlySetting(
              'ML inference',
              'Not connected · research capabilities are planned',
            ),
          ],
        ),
      ),
      if (_loadError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: DashboardEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Saved preferences could not be loaded',
            description: _loadError!,
            action: TextButton.icon(
              onPressed: _loading ? null : _retryLoad,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ),
    ],
  );

  Widget _notificationSettings() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_savedState == null) {
      return DashboardEmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'Notification preferences are read-only',
        description:
            _loadError ?? 'Saved notification preferences are unavailable.',
      );
    }
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Email notifications'),
          subtitle: const Text('Persisted account preference'),
          value: _emailEnabled,
          onChanged: (value) => setState(() => _emailEnabled = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Push notifications'),
          subtitle: const Text('Persisted account preference'),
          value: _pushEnabled,
          onChanged: (value) => setState(() => _pushEnabled = value),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Notification topics',
            style: dashboardTextStyle(size: 11, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [
            for (final topic in _notificationTopics)
              FilterChip(
                label: Text(topic),
                selected: _topics.contains(topic),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _topics.add(topic);
                  } else {
                    _topics.remove(topic);
                  }
                }),
              ),
          ],
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _saveError!,
              style: dashboardTextStyle(
                color: const Color(0xFFB42318),
                size: 10,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveNotifications,
            icon: _saving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving' : 'Save notification preferences'),
          ),
        ),
      ],
    );
  }

  Future<void> _retryLoad() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _loadSettings();
  }
}

class _CategoryNavigation extends StatelessWidget {
  const _CategoryNavigation({
    required this.sections,
    required this.selected,
    required this.compact,
    required this.onSelect,
  });

  final List<(String, IconData)> sections;
  final int selected;
  final bool compact;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.appTheme.surfaceElevated,
      border: Border.all(color: context.appTheme.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: dashboardTextStyle(
            color: dashboardMuted,
            size: 9,
            weight: FontWeight.w800,
          ).copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: 9),
        if (compact)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (index, item) in sections.indexed)
                ChoiceChip(
                  avatar: Icon(item.$2, size: 15),
                  label: Text(item.$1),
                  selected: selected == index,
                  onSelected: (_) => onSelect(index),
                ),
            ],
          )
        else
          for (final (index, item) in sections.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                selected: selected == index,
                selectedTileColor: context.appTheme.surfaceSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: Icon(item.$2, size: 17),
                title: Text(
                  item.$1,
                  style: dashboardTextStyle(size: 10, weight: FontWeight.w700),
                ),
                onTap: () => onSelect(index),
              ),
            ),
      ],
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.controller,
    required this.sectionKey,
    required this.index,
    required this.title,
    required this.description,
    required this.child,
  });

  final ScrollController controller;
  final GlobalKey sectionKey;
  final int index;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => DashboardScrollReveal(
    controller: controller,
    delay: Duration(milliseconds: 45 * index),
    child: Padding(
      key: sectionKey,
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: dashboardTextStyle(size: 19, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: dashboardTextStyle(
              color: dashboardMuted,
              size: 10,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 20),
          const Divider(color: dashboardRule),
        ],
      ),
    ),
  );
}

class _ReadOnlySetting extends StatelessWidget {
  const _ReadOnlySetting(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: dashboardRule)),
    ),
    child: DashboardDataRow(
      leading: const Icon(Icons.lock_outline_rounded),
      title: label,
      detail: value,
      trailing: const DashboardStatusTag('READ ONLY', color: dashboardMuted),
    ),
  );
}

String _profileValue(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : 'Not available';
