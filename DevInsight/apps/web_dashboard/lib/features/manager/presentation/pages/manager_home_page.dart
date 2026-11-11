import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_dashboard/core/config/app_config.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/manager/presentation/routing/manager_destination.dart';
import 'package:web_dashboard/features/manager/presentation/widgets/manager_dashboard_shell.dart';
import 'package:web_dashboard/features/manager/presentation/widgets/manager_workspace_pages.dart';
import 'package:web_dashboard/shared/widgets/dashboard_chrome.dart';

class ManagerHomePage extends StatefulWidget {
  const ManagerHomePage({
    super.key,
    required this.profile,
    this.api,
    this.authService,
  });

  final CurrentUserProfile profile;
  final DevInsightApi? api;
  final AuthService? authService;

  @override
  State<ManagerHomePage> createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientMotionController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  late final DevInsightApi _api =
      widget.api ?? DevInsightApi(baseUrl: AppConfig.apiBaseUrl);
  late final AuthService _authService =
      widget.authService ?? AuthService(api: _api);
  final _scrollController = ScrollController();
  final _currentProjectKey = GlobalKey();
  List<GitHubRepositoryConnection> _repositories = [];
  GitHubRepositoryConnection? _repository;
  GitHubRepositoryOverview? _overview;
  String? _repositoryError;
  bool _loadingRepository = false;
  bool _refreshingRepository = false;
  int _selectionVersion = 0;
  ManagerDestination _activeDestination = ManagerDestination.home;
  bool? _motionDisabled;

  String get _activeRepositoryPreferenceKey =>
      'devinsight.active_repository.${widget.profile.id}';

  @override
  void initState() {
    super.initState();
    if (_authService.hasSession) unawaited(_loadRepositories());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled == motionDisabled) return;
    _motionDisabled = motionDisabled;
    if (motionDisabled) {
      _ambientMotionController
        ..stop()
        ..value = 0;
    } else {
      _ambientMotionController.repeat();
    }
  }

  @override
  void dispose() {
    _ambientMotionController.dispose();
    _scrollController.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _loadRepositories() async {
    final requestVersion = ++_selectionVersion;
    setState(() {
      _loadingRepository = true;
      _repositoryError = null;
    });
    try {
      final repositories = await _authService.withSession(
        _api.getGitHubConnections,
      );
      if (!mounted || requestVersion != _selectionVersion) return;
      if (repositories.isEmpty) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_activeRepositoryPreferenceKey);
        if (!mounted || requestVersion != _selectionVersion) return;
        setState(() {
          _repositories = [];
          _repository = null;
          _overview = null;
          _loadingRepository = false;
        });
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      if (!mounted || requestVersion != _selectionVersion) return;
      final savedId = preferences.getString(_activeRepositoryPreferenceKey);
      final selected = repositories.firstWhere(
        (repository) => repository.id == savedId,
        orElse: () => repositories.first,
      );
      setState(() => _repositories = repositories);
      await _selectRepository(selected, persist: savedId != selected.id);
    } on DevInsightApiException catch (error) {
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
    } on AuthIntegrationException catch (error) {
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
    }
  }

  Future<void> _selectRepository(
    GitHubRepositoryConnection connection, {
    bool persist = true,
  }) async {
    final requestVersion = ++_selectionVersion;
    setState(() {
      _repository = connection;
      _overview = null;
      _repositoryError = null;
      _loadingRepository = true;
      _refreshingRepository = false;
    });
    if (persist) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _activeRepositoryPreferenceKey,
        connection.id,
      );
    }
    if (!mounted || requestVersion != _selectionVersion) return;
    try {
      final overview = await _authService.withSession(
        (token) => _api.getGitHubOverview(token, connection.id),
      );
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repository = overview.connection;
        _overview = overview;
        _loadingRepository = false;
      });
    } on DevInsightApiException catch (error) {
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
    } on AuthIntegrationException catch (error) {
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
    }
  }

  Future<void> _refreshRepository() async {
    final repository = _repository;
    if (repository == null || _refreshingRepository) return;
    final requestVersion = _selectionVersion;
    setState(() {
      _refreshingRepository = true;
      _repositoryError = null;
    });
    try {
      final overview = await _authService.withSession(
        (token) => _api.refreshGitHubRepository(token, repository.id),
      );
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repository = overview.connection;
        _overview = overview;
        _repositories = [
          overview.connection,
          ..._repositories.where((item) => item.id != overview.connection.id),
        ];
        _refreshingRepository = false;
        _repositoryError = overview.throttled
            ? 'Repository was synced recently. Showing the latest available data.'
            : null;
      });
    } on DevInsightApiException catch (error) {
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repositoryError = error.message;
        _refreshingRepository = false;
      });
    } on AuthIntegrationException catch (error) {
      if (!mounted || requestVersion != _selectionVersion) return;
      setState(() {
        _repositoryError = error.message;
        _refreshingRepository = false;
      });
    }
  }

  Future<void> _showConnectRepository() async {
    final controller = TextEditingController();
    final repositoryUrl = await showDashboardGlassDialog<String>(
      context: context,
      barrierLabel: 'Close connect repository dialog',
      builder: (dialogContext) => DashboardGlassSurface(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect a GitHub repository',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(dialogContext).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect a public repository to load its real GitHub metadata and activity.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Public GitHub repository URL',
                hintText: 'https://github.com/owner/repository',
              ),
              onSubmitted: (value) =>
                  Navigator.of(dialogContext).pop(value.trim()),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(controller.text.trim()),
                  icon: const Icon(Icons.add_link_rounded, size: 17),
                  label: const Text('Connect repository'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    final url = repositoryUrl?.trim();
    if (url == null || url.isEmpty || !mounted) return;
    setState(() {
      _loadingRepository = true;
      _repositoryError = null;
    });
    try {
      final connection = await _authService.withSession(
        (token) => _api.connectGitHubRepository(token, url),
      );
      if (!mounted) return;
      setState(() {
        _repositories = [
          connection,
          ..._repositories.where((item) => item.id != connection.id),
        ];
      });
      await _selectRepository(connection);
    } on DevInsightApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
      _showMessage(error.message);
    } on AuthIntegrationException catch (error) {
      if (!mounted) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
      _showMessage(error.message);
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _showMessage('Could not open the GitHub link.');
    } on PlatformException {
      _showMessage('Could not open the GitHub link.');
    } on FormatException {
      _showMessage('The GitHub link is invalid.');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/landing', (_) => false);
      }
    } on AuthIntegrationException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _selectDestination(ManagerDestination destination) {
    if (_activeDestination == destination) return;
    setState(() => _activeDestination = destination);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _showProfileDetails() {
    unawaited(
      showDashboardGlassDialog<void>(
        context: context,
        barrierLabel: 'Close account details',
        builder: (dialogContext) => DashboardGlassSurface(
          width: 410,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _AccountDetail(label: 'Name', value: _displayName()),
              _AccountDetail(
                label: 'Email',
                value: widget.profile.email?.trim().isNotEmpty == true
                    ? widget.profile.email!
                    : 'Not available',
              ),
              _AccountDetail(
                label: 'Role',
                value: _roleLabel(widget.profile.role),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu() {
    unawaited(
      showDashboardGlassDialog<void>(
        context: context,
        barrierLabel: 'Close profile menu',
        builder: (dialogContext) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height,
          ),
          child: DashboardGlassSurface(
            width: 340,
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      DashboardAvatar(name: _displayName(), size: 42),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  dialogContext,
                                ).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              widget.profile.email?.trim().isNotEmpty == true
                                  ? widget.profile.email!
                                  : 'Email unavailable',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ManagerRoleTag(
                      role: _roleLabel(widget.profile.role),
                    ),
                  ),
                  const Divider(height: 20),
                  _ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Account details',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _showProfileDetails();
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _selectDestination(ManagerDestination.settings);
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    color: const Color(0xFFCE4242),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _signOut();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayName() {
    final name = widget.profile.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = widget.profile.email?.trim();
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  ManagerWorkspaceData _workspaceData() => ManagerWorkspaceData(
    profile: widget.profile,
    scrollController: _scrollController,
    currentProjectKey: _currentProjectKey,
    repositories: _repositories,
    repository: _repository,
    overview: _overview,
    loading: _loadingRepository,
    refreshing: _refreshingRepository,
    error: _repositoryError,
    onSelectRepository: _selectRepository,
    onConnectRepository: _showConnectRepository,
    onRefresh: _refreshRepository,
    onRetry: _loadRepositories,
    onOpenLink: _openLink,
    onNavigate: _selectDestination,
    onMessage: _showMessage,
    onSignOut: _signOut,
  );

  @override
  Widget build(BuildContext context) {
    final data = _workspaceData();
    final child = switch (_activeDestination) {
      ManagerDestination.home => ManagerHomeView(
        data: data,
        scrollController: _scrollController,
        ambientMotion: _ambientMotionController,
      ),
      ManagerDestination.projects => ManagerProjectsView(data: data),
      ManagerDestination.issues => ManagerIssuesView(data: data),
      ManagerDestination.team => ManagerTeamView(data: data),
      ManagerDestination.analytics => ManagerAnalyticsView(data: data),
      ManagerDestination.reports => ManagerReportsView(data: data),
      ManagerDestination.settings => ManagerSettingsView(data: data),
    };
    return ManagerDashboardShell(
      profileName: _displayName(),
      role: _roleLabel(widget.profile.role),
      email: widget.profile.email,
      activeDestination: _activeDestination,
      scrollController: _scrollController,
      onDestinationSelected: _selectDestination,
      ambientMotion: _ambientMotionController,
      onProfile: _showProfileMenu,
      onAction: _showMessage,
      onHelp: () => _showMessage('Support resources are coming soon.'),
      child: child,
    );
  }
}

class _AccountDetail extends StatelessWidget {
  const _AccountDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    ),
  );
}

class _ManagerRoleTag extends StatelessWidget {
  const _ManagerRoleTag({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      role,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
