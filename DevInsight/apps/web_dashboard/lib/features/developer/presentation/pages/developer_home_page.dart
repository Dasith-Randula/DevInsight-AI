import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';
import 'package:web_dashboard/core/config/app_config.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_dashboard/features/developer/presentation/routing/dashboard_destination.dart';
import 'package:web_dashboard/features/developer/presentation/pages/ai_insights_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/analytics_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/code_quality_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/issues_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/my_work_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/projects_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/pull_requests_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/reports_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/settings_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/team_page.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/developer_home_sections.dart';
import 'package:web_dashboard/shared/widgets/dashboard_chrome.dart';
import 'package:web_dashboard/shared/widgets/dashboard_scroll_indicator.dart';
import 'package:web_dashboard/shared/widgets/devinsight_animated_wordmark.dart';

class DeveloperHomePage extends StatefulWidget {
  const DeveloperHomePage({
    super.key,
    required this.profile,
    this.api,
    this.authService,
  });

  final CurrentUserProfile profile;
  final DevInsightApi? api;
  final AuthService? authService;

  @override
  State<DeveloperHomePage> createState() => _DeveloperHomePageState();
}

class _DeveloperHomePageState extends State<DeveloperHomePage>
    with SingleTickerProviderStateMixin {
  late final DevInsightApi _api =
      widget.api ?? DevInsightApi(baseUrl: AppConfig.apiBaseUrl);
  late final AuthService _authService =
      widget.authService ?? AuthService(api: _api);
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _nextSectionKey = GlobalKey();
  late final AnimationController _ambientMotionController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  bool? _motionDisabled;
  List<GitHubRepositoryConnection> _repositories = [];
  GitHubRepositoryConnection? _repository;
  GitHubRepositoryOverview? _overview;
  String? _repositoryError;
  bool _loadingRepository = false;
  bool _refreshingRepository = false;
  int _selectionVersion = 0;
  DashboardDestination _activeDestination = DashboardDestination.home;

  String get _activeRepositoryPreferenceKey =>
      'devinsight.active_repository.${widget.profile.id}';

  @override
  void initState() {
    super.initState();
    if (_authService.hasSession) _loadRepositories();
  }

  Future<void> _loadRepositories() async {
    setState(() {
      _loadingRepository = true;
      _repositoryError = null;
    });
    try {
      final repositories = await _authService.withSession(
        _api.getGitHubConnections,
      );
      if (!mounted) return;
      if (repositories.isEmpty) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_activeRepositoryPreferenceKey);
        if (!mounted) return;
        setState(() {
          _repositories = [];
          _repository = null;
          _overview = null;
          _loadingRepository = false;
        });
        return;
      }
      setState(() {
        _repositories = repositories;
      });
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      final savedId = preferences.getString(_activeRepositoryPreferenceKey);
      final connection = repositories.firstWhere(
        (repository) => repository.id == savedId,
        orElse: () => repositories.first,
      );
      await _selectRepository(connection, persist: savedId != connection.id);
    } on DevInsightApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
    } on AuthIntegrationException catch (error) {
      if (!mounted) return;
      setState(() {
        _repositoryError = error.message;
        _loadingRepository = false;
      });
    }
  }

  Future<void> _connectRepository(String repositoryUrl) async {
    setState(() {
      _loadingRepository = true;
      _repositoryError = null;
    });
    try {
      final connection = await _authService.withSession(
        (token) => _api.connectGitHubRepository(token, repositoryUrl),
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
      if (mounted) {
        setState(() {
          _repositoryError = error.message;
          _loadingRepository = false;
        });
      }
      rethrow;
    } on AuthIntegrationException catch (error) {
      if (mounted) {
        setState(() {
          _repositoryError = error.message;
          _loadingRepository = false;
        });
      }
      rethrow;
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

  Future<bool> _disconnectRepository(
    GitHubRepositoryConnection connection,
  ) async {
    try {
      await _authService.withSession(
        (token) => _api.disconnectGitHubRepository(token, connection.id),
      );
      if (!mounted) return true;
      final repositories = _repositories
          .where((item) => item.id != connection.id)
          .toList();
      setState(() => _repositories = repositories);
      if (_repository?.id == connection.id) {
        final preferences = await SharedPreferences.getInstance();
        if (!mounted) return true;
        if (repositories.isEmpty) {
          await preferences.remove(_activeRepositoryPreferenceKey);
          if (!mounted) return true;
          ++_selectionVersion;
          setState(() {
            _repository = null;
            _overview = null;
            _repositoryError = null;
            _loadingRepository = false;
          });
        } else {
          await _selectRepository(repositories.first);
        }
      }
      return true;
    } on DevInsightApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on AuthIntegrationException catch (error) {
      if (mounted) _showMessage(error.message);
    }
    return false;
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

  Future<void> _showManageRepositories() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ManageRepositoriesDialog(
        repositories: _repositories,
        activeRepositoryId: _repository?.id,
        onSelect: (connection) async {
          Navigator.of(dialogContext).pop();
          await _selectRepository(connection);
        },
        onConnect: () {
          Navigator.of(dialogContext).pop();
          _showConnectRepository();
        },
        onDisconnect: _disconnectRepository,
      ),
    );
  }

  Future<void> _showConnectRepository() async {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close repository connection dialog',
      barrierColor: Colors.transparent,
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: reduceMotion ? 0 : 14,
                sigmaY: reduceMotion ? 0 : 14,
              ),
              child: ColoredBox(
                color: const Color(0xFF102345).withValues(alpha: 0.13),
              ),
            ),
          ),
          Center(
            child: SafeArea(
              child: _ConnectRepositoryDialog(onConnect: _connectRepository),
            ),
          ),
        ],
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  String get _displayName {
    final name = widget.profile.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = widget.profile.email?.trim();
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Developer';
  }

  String get _firstName => _displayName.split(RegExp(r'\s+')).first;

  String get _role {
    final role = widget.profile.role?.trim();
    return role == null || role.isEmpty ? 'Developer' : role;
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectDestination(DashboardDestination destination) {
    if (_activeDestination == destination) return;
    setState(() => _activeDestination = destination);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Widget _buildDestinationContent() {
    return switch (_activeDestination) {
      DashboardDestination.home => _DashboardContent(
        scrollController: _scrollController,
        nextSectionKey: _nextSectionKey,
        ambientMotion: _ambientMotionController,
        firstName: _firstName,
        role: _role,
        onAction: _showMessage,
        repository: _repository,
        overview: _overview,
        repositories: _repositories,
        repositoryError: _repositoryError,
        loadingRepository: _loadingRepository,
        refreshingRepository: _refreshingRepository,
        onConnect: _showConnectRepository,
        onManage: _showManageRepositories,
        onRetry: _loadRepositories,
        onRefresh: _refreshRepository,
      ),
      DashboardDestination.projects => ProjectsPage(
        scrollController: _scrollController,
        profile: widget.profile,
        repositories: _repositories,
        repository: _repository,
        overview: _overview,
        loading: _loadingRepository,
        error: _repositoryError,
        onConnect: _showConnectRepository,
        onSelect: _selectRepository,
        onManage: _showManageRepositories,
        onRefresh: _refreshRepository,
        onOpenRepository: (url) => _openRepositoryUrl(url, _showMessage),
      ),
      DashboardDestination.myWork => MyWorkPage(
        scrollController: _scrollController,
        profile: widget.profile,
        repository: _repository,
        overview: _overview,
        error: _repositoryError,
        onOpenRepository: (url) => _openRepositoryUrl(url, _showMessage),
      ),
      DashboardDestination.issues => IssuesPage(
        scrollController: _scrollController,
        repository: _repository,
        overview: _overview,
        loading: _loadingRepository,
        error: _repositoryError,
        onOpenLink: (url) => _openRepositoryUrl(url, _showMessage),
      ),
      DashboardDestination.pullRequests => PullRequestsPage(
        scrollController: _scrollController,
        repository: _repository,
        overview: _overview,
        loading: _loadingRepository,
        error: _repositoryError,
        onOpenLink: (url) => _openRepositoryUrl(url, _showMessage),
      ),
      DashboardDestination.codeQuality => CodeQualityPage(
        scrollController: _scrollController,
        repository: _repository,
        overview: _overview,
        loading: _loadingRepository,
        error: _repositoryError,
        onOpenLink: (url) => _openRepositoryUrl(url, _showMessage),
      ),
      DashboardDestination.analytics => AnalyticsPage(
        scrollController: _scrollController,
        repository: _repository,
        overview: _overview,
        loading: _loadingRepository,
        error: _repositoryError,
      ),
      DashboardDestination.aiInsights => AiInsightsPage(
        scrollController: _scrollController,
        repository: _repository,
        overview: _overview,
        error: _repositoryError,
      ),
      DashboardDestination.team => TeamPage(
        scrollController: _scrollController,
        repository: _repository,
        overview: _overview,
        error: _repositoryError,
      ),
      DashboardDestination.reports => ReportsPage(
        scrollController: _scrollController,
        repository: _repository,
        overview: _overview,
        error: _repositoryError,
      ),
      DashboardDestination.settings => SettingsPage(
        scrollController: _scrollController,
        profile: widget.profile,
        repositories: _repositories,
        repository: _repository,
        authService: _authService,
      ),
    };
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/landing', (_) => false);
      }
    } on AuthIntegrationException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _showProfileMenu() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close profile menu',
      barrierColor: Colors.black.withValues(alpha: 0.30),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final width = MediaQuery.sizeOf(dialogContext).width;
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(dialogContext).pop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: 72,
                right: width < 400 ? 12 : 24,
                child: SafeArea(
                  child: _ProfileMenu(
                    name: _displayName,
                    email: widget.profile.email,
                    role: _role,
                    onClose: () => Navigator.of(dialogContext).pop(),
                    onAccount: () {
                      Navigator.of(dialogContext).pop();
                      _showAccountDetails();
                    },
                    onNotifications: () {
                      Navigator.of(dialogContext).pop();
                      _showMessage('Notification preferences are coming soon.');
                    },
                    onSupport: () {
                      Navigator.of(dialogContext).pop();
                      _showMessage('Support resources are coming soon.');
                    },
                    onSignOut: () {
                      Navigator.of(dialogContext).pop();
                      _signOut();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showAccountDetails() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Account details',
          style: _textStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $_displayName'),
            const SizedBox(height: 8),
            Text(
              'Email: ${widget.profile.email?.trim().isNotEmpty == true ? widget.profile.email : 'Not available'}',
            ),
            const SizedBox(height: 8),
            Text('Role: $_role'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ambientMotionController.dispose();
    _scrollController.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DeveloperDashboardShell(
      scaffoldKey: _scaffoldKey,
      profileName: _displayName,
      role: _role,
      activeDestination: _activeDestination,
      scrollController: _scrollController,
      ambientMotion: _ambientMotionController,
      onDestinationSelected: _selectDestination,
      onProfile: _showProfileMenu,
      onAction: _showMessage,
      onHelp: () => _showMessage('Support resources are coming soon.'),
      child: _buildDestinationContent(),
    );
  }
}

class DeveloperDashboardShell extends StatelessWidget {
  const DeveloperDashboardShell({
    super.key,
    required this.scaffoldKey,
    required this.profileName,
    required this.role,
    required this.activeDestination,
    required this.scrollController,
    required this.ambientMotion,
    required this.onDestinationSelected,
    required this.onProfile,
    required this.onAction,
    required this.onHelp,
    required this.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final String profileName;
  final String role;
  final DashboardDestination activeDestination;
  final ScrollController scrollController;
  final Animation<double> ambientMotion;
  final ValueChanged<DashboardDestination> onDestinationSelected;
  final VoidCallback onProfile;
  final ValueChanged<String> onAction;
  final VoidCallback onHelp;
  final Widget child;

  void _selectFromDrawer(
    BuildContext context,
    DashboardDestination destination,
  ) {
    Navigator.of(context).pop();
    onDestinationSelected(destination);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: colors.secondaryBackground,
      drawer: Drawer(
        width: 272,
        child: SafeArea(
          child: DashboardNavigation<DashboardDestination>(
            primaryItems: DashboardDestination.values
                .where((destination) => !destination.isWorkspace)
                .map(
                  (destination) => DashboardNavigationItem(
                    value: destination,
                    label: destination.label,
                    icon: destination.icon,
                  ),
                )
                .toList(),
            workspaceItems: DashboardDestination.values
                .where((destination) => destination.isWorkspace)
                .map(
                  (destination) => DashboardNavigationItem(
                    value: destination,
                    label: destination.label,
                    icon: destination.icon,
                  ),
                )
                .toList(),
            activeValue: activeDestination,
            onSelect: (destination) => _selectFromDrawer(context, destination),
            onHelp: () {
              Navigator.of(context).pop();
              onHelp();
            },
            expanded: true,
          ),
        ),
      ),
      body: DashboardBackground(
        animation: ambientMotion,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 900;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: desktop ? 76 : 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Stack(
                          key: const ValueKey('dashboard-content'),
                          children: [
                            Positioned.fill(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  constraints.maxWidth < 600 ? 14 : 24,
                                  78,
                                  constraints.maxWidth < 600 ? 14 : 24,
                                  28,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1500,
                                    ),
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        color: colors.primaryText,
                                      ),
                                      child: KeyedSubtree(
                                        key: ValueKey(
                                          'destination-${activeDestination.name}',
                                        ),
                                        child: child,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: DashboardTopBar(
                                name: profileName,
                                role: role,
                                scrollController: scrollController,
                                onMenu: desktop
                                    ? null
                                    : () => scaffoldKey.currentState
                                          ?.openDrawer(),
                                onProfile: onProfile,
                                onAction: onAction,
                                onSettings: () => onDestinationSelected(
                                  DashboardDestination.settings,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (desktop)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: DashboardNavigation<DashboardDestination>(
                            primaryItems: DashboardDestination.values
                                .where(
                                  (destination) => !destination.isWorkspace,
                                )
                                .map(
                                  (destination) => DashboardNavigationItem(
                                    value: destination,
                                    label: destination.label,
                                    icon: destination.icon,
                                  ),
                                )
                                .toList(),
                            workspaceItems: DashboardDestination.values
                                .where((destination) => destination.isWorkspace)
                                .map(
                                  (destination) => DashboardNavigationItem(
                                    value: destination,
                                    label: destination.label,
                                    icon: destination.icon,
                                  ),
                                )
                                .toList(),
                            activeValue: activeDestination,
                            onSelect: onDestinationSelected,
                            onHelp: onHelp,
                            expanded: false,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectRepositoryDialog extends StatefulWidget {
  const _ConnectRepositoryDialog({required this.onConnect});

  final Future<void> Function(String repositoryUrl) onConnect;

  @override
  State<_ConnectRepositoryDialog> createState() =>
      _ConnectRepositoryDialogState();
}

class _ConnectRepositoryDialogState extends State<_ConnectRepositoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? input) {
    final value = input?.trim() ?? '';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.toLowerCase() != 'github.com' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return 'Enter a public GitHub repository URL.';
    }
    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.length != 2) return 'Use the format github.com/owner/repository.';
    final owner = parts[0];
    final name = parts[1].endsWith('.git')
        ? parts[1].substring(0, parts[1].length - 4)
        : parts[1];
    if (!RegExp(
          r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$',
        ).hasMatch(owner) ||
        !RegExp(
          r'^[A-Za-z0-9](?:[A-Za-z0-9._-]{0,98}[A-Za-z0-9])?$',
        ).hasMatch(name) ||
        name == '.' ||
        name == '..') {
      return 'Enter a valid GitHub owner and repository name.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_connecting || !_formKey.currentState!.validate()) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await widget.onConnect(_urlController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } on DevInsightApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _connecting = false;
        });
      }
    } on AuthIntegrationException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _connecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFDCEBFF).withValues(alpha: 0.9),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.96),
                const Color(0xFFEAF4FF).withValues(alpha: 0.91),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1765DB).withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.78),
                blurRadius: 1,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Connect GitHub Repository',
              style: _textStyle(fontWeight: FontWeight.w800),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect a public repository to load its real GitHub metadata and activity.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('github-repository-url'),
                      controller: _urlController,
                      enabled: !_connecting,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Repository URL',
                        hintText: 'https://github.com/username/repository',
                        prefixIcon: Icon(Icons.link_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateUrl,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        key: const ValueKey('repository-connect-error'),
                        style: _textStyle(
                          color: const Color(0xFFB42318),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_connecting) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _connecting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: _connecting ? null : _submit,
                icon: _connecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_link_rounded),
                label: Text(_connecting ? 'Connecting...' : 'Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageRepositoriesDialog extends StatefulWidget {
  const _ManageRepositoriesDialog({
    required this.repositories,
    required this.activeRepositoryId,
    required this.onSelect,
    required this.onConnect,
    required this.onDisconnect,
  });

  final List<GitHubRepositoryConnection> repositories;
  final String? activeRepositoryId;
  final Future<void> Function(GitHubRepositoryConnection) onSelect;
  final VoidCallback onConnect;
  final Future<bool> Function(GitHubRepositoryConnection) onDisconnect;

  @override
  State<_ManageRepositoriesDialog> createState() =>
      _ManageRepositoriesDialogState();
}

class _ManageRepositoriesDialogState extends State<_ManageRepositoriesDialog> {
  late final List<GitHubRepositoryConnection> _repositories = [
    ...widget.repositories,
  ];
  late String? _activeRepositoryId = widget.activeRepositoryId;
  String? _disconnectingId;

  Future<void> _disconnect(GitHubRepositoryConnection repository) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect repository?'),
        content: Text(
          'Remove ${repository.fullName} from your connected repositories? This will not change anything on GitHub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _disconnectingId = repository.id);
    final disconnected = await widget.onDisconnect(repository);
    if (!mounted) return;
    setState(() {
      _disconnectingId = null;
      if (disconnected) {
        _repositories.removeWhere((item) => item.id == repository.id);
        if (_activeRepositoryId == repository.id) {
          _activeRepositoryId = _repositories.isEmpty
              ? null
              : _repositories.first.id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.97),
              const Color(0xFFEAF4FF).withValues(alpha: 0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1765DB).withValues(alpha: 0.16),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Manage Repositories',
                    style: _textStyle(
                      color: const Color(0xFF172B4D),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Choose the active project or disconnect a repository.',
              style: _textStyle(color: const Color(0xFF687A96), fontSize: 12),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: _repositories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: _EmptyState(
                        icon: Icons.folder_open_rounded,
                        title: 'No repositories connected',
                        detail:
                            'Connect a public GitHub repository to see its project data here.',
                        compact: true,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _repositories.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final repository = _repositories[index];
                        final active = repository.id == _activeRepositoryId;
                        final disconnecting = repository.id == _disconnectingId;
                        return ListTile(
                          key: ValueKey('repository-${repository.id}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          onTap: active || disconnecting
                              ? null
                              : () => widget.onSelect(repository),
                          title: Text(
                            repository.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _textStyle(
                              color: const Color(0xFF172B4D),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            [
                              'Branch: ${repository.defaultBranch ?? 'Unknown'}',
                              if (repository.primaryLanguage != null)
                                repository.primaryLanguage!,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _textStyle(
                              color: const Color(0xFF687A96),
                              fontSize: 11,
                            ),
                          ),
                          leading: Icon(
                            active
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: active
                                ? AppColors.primaryBlue
                                : const Color(0xFF91A0B5),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (active)
                                Text(
                                  'Active',
                                  style: _textStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Disconnect ${repository.fullName}',
                                onPressed: disconnecting
                                    ? null
                                    : () => _disconnect(repository),
                                icon: disconnecting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.link_off_rounded,
                                        size: 19,
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('connect-new-repository'),
                onPressed: widget.onConnect,
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Connect New Repository'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSyncTime(DateTime? date) {
  if (date == null) return 'not synchronized yet';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

Future<void> _openRepositoryUrl(
  String url,
  ValueChanged<String> onError,
) async {
  try {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) onError('Could not open the GitHub repository link.');
  } on PlatformException {
    onError('Could not open the GitHub repository link.');
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.scrollController,
    required this.nextSectionKey,
    required this.ambientMotion,
    required this.firstName,
    required this.role,
    required this.onAction,
    required this.repository,
    required this.overview,
    required this.repositories,
    required this.repositoryError,
    required this.loadingRepository,
    required this.refreshingRepository,
    required this.onConnect,
    required this.onManage,
    required this.onRetry,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final GlobalKey nextSectionKey;
  final Animation<double> ambientMotion;
  final String firstName;
  final String role;
  final ValueChanged<String> onAction;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final List<GitHubRepositoryConnection> repositories;
  final String? repositoryError;
  final bool loadingRepository;
  final bool refreshingRepository;
  final VoidCallback onConnect;
  final VoidCallback onManage;
  final VoidCallback onRetry;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final desktopHero = width >= 900 && viewportHeight >= 640;
        final introMinHeight = desktopHero
            ? math.max(0.0, viewportHeight - 78 + 24)
            : 0.0;
        final brandTopSpacing = desktopHero
            ? (viewportHeight * 0.045).clamp(28.0, 48.0)
            : (viewportHeight * 0.022).clamp(14.0, 24.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: introMinHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: desktopHero
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: brandTopSpacing),
                    child: _Reveal(
                      controller: scrollController,
                      child: DevInsightAnimatedWordmark(
                        animation: ambientMotion,
                        topPadding: desktopHero ? 16 : 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: desktopHero
                        ? (viewportHeight * 0.035).clamp(22.0, 32.0)
                        : 18,
                  ),
                  _Reveal(
                    controller: scrollController,
                    child: _WelcomeHero(
                      firstName: firstName,
                      role: role,
                      compact: width < 850,
                      ambientMotion: ambientMotion,
                      onAction: onAction,
                      repository: repository,
                      repositoryCount: repositories.length,
                      overview: overview,
                      repositoryError: repositoryError,
                      loadingRepository: loadingRepository,
                      refreshingRepository: refreshingRepository,
                      onConnect: onConnect,
                      onManage: onManage,
                      onRetry: onRetry,
                      onRefresh: onRefresh,
                    ),
                  ),
                  if (!desktopHero) const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(bottom: desktopHero ? 28 : 0),
                    child: DashboardScrollIndicator(
                      onPressed: () {
                        final targetContext = nextSectionKey.currentContext;
                        if (targetContext == null) return;
                        Scrollable.ensureVisible(
                          targetContext,
                          alignment: 0.10,
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 44),
            _Reveal(
              controller: scrollController,
              child: DeveloperHomeSections(
                scrollController: scrollController,
                overviewSectionKey: nextSectionKey,
                overview: overview,
                hasRepository: repository != null,
                loading: loadingRepository,
                onAction: onAction,
                onOpenRepository: (url) => _openRepositoryUrl(url, onAction),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.name,
    required this.email,
    required this.role,
    required this.onClose,
    required this.onAccount,
    required this.onNotifications,
    required this.onSupport,
    required this.onSignOut,
  });

  final String name;
  final String? email;
  final String role;
  final VoidCallback onClose;
  final VoidCallback onAccount;
  final VoidCallback onNotifications;
  final VoidCallback onSupport;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 22,
      shadowColor: const Color(0xFF071A3F).withValues(alpha: 0.24),
      child: Container(
        width: MediaQuery.sizeOf(context).width < 400
            ? MediaQuery.sizeOf(context).width - 24
            : 318,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E9F6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                DashboardAvatar(name: name, size: 42),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        email?.trim().isNotEmpty == true
                            ? email!
                            : 'Email unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          color: const Color(0xFF7787A0),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role,
                  style: _textStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            _ProfileAction(
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              onTap: onAccount,
            ),
            _ProfileAction(
              icon: Icons.manage_accounts_outlined,
              title: 'Account Settings',
              onTap: onAccount,
            ),
            _ProfileAction(
              icon: Icons.notifications_none_rounded,
              title: 'Notification Preferences',
              onTap: onNotifications,
            ),
            _ProfileAction(
              icon: Icons.support_agent_rounded,
              title: 'Help / Support',
              onTap: onSupport,
            ),
            const Divider(height: 10),
            _ProfileAction(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              color: const Color(0xFFCE4242),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF334665),
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.firstName,
    required this.role,
    required this.compact,
    required this.ambientMotion,
    required this.onAction,
    required this.repository,
    required this.repositoryCount,
    required this.overview,
    required this.repositoryError,
    required this.loadingRepository,
    required this.refreshingRepository,
    required this.onConnect,
    required this.onManage,
    required this.onRetry,
    required this.onRefresh,
  });

  final String firstName;
  final String role;
  final bool compact;
  final Animation<double> ambientMotion;
  final ValueChanged<String> onAction;
  final GitHubRepositoryConnection? repository;
  final int repositoryCount;
  final GitHubRepositoryOverview? overview;
  final String? repositoryError;
  final bool loadingRepository;
  final bool refreshingRepository;
  final VoidCallback onConnect;
  final VoidCallback onManage;
  final VoidCallback onRetry;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectPanel = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          width: compact ? double.infinity : 270,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [colors.surfaceElevated, colors.surfaceSecondary]
                  : [
                      Colors.white.withValues(alpha: 0.88),
                      const Color(0xFFEAF4FF).withValues(alpha: 0.78),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? colors.border
                  : Colors.white.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? colors.shadow
                    : const Color(0xFF08256F).withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: isDark
                    ? colors.surfaceSecondary.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.24),
                blurRadius: 1,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_open_rounded,
                        size: 17,
                        color: Color(0xFF1765DB),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Project',
                        style: _textStyle(
                          color: colors.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (repository != null) const _ConnectedStatusIndicator(),
                ],
              ),
              const SizedBox(height: 8),
              if (repository == null) ...[
                Text(
                  loadingRepository
                      ? 'Loading repository...'
                      : 'No project connected',
                  style: _textStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  repositoryError ??
                      'Connect a public GitHub repository to load real project data.',
                  style: _textStyle(
                    color: colors.mutedText,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                if (loadingRepository)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  TextButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.add_link_rounded, size: 15),
                    label: const Text('Connect repository'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: EdgeInsets.zero,
                      textStyle: _textStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                if (repositoryError != null && !loadingRepository)
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                TextButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.settings_rounded, size: 15),
                  label: const Text('Manage Repositories'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.zero,
                    textStyle: _textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                    minimumSize: const Size(0, 28),
                  ),
                ),
              ] else ...[
                Text(
                  repository!.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  repository!.description?.trim().isNotEmpty == true
                      ? repository!.description!
                      : 'No repository description provided.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    color: colors.mutedText,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Owner: ${repository!.owner}  ·  Branch: ${repository!.defaultBranch ?? 'Unknown'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(color: colors.mutedText, fontSize: 9),
                ),
                Text(
                  'Stars: ${repository!.stars}  ·  Forks: ${repository!.forks}',
                  style: _textStyle(color: colors.mutedText, fontSize: 9),
                ),
                Text(
                  'Primary language: ${repository!.primaryLanguage ?? 'Not available'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(color: colors.mutedText, fontSize: 9),
                ),
                Text(
                  '${repositoryError ?? 'Public repository'} · Last synced ${_formatSyncTime(repository!.lastSyncedAt)}${overview?.isStale == true || repositoryError != null ? ' · Cached data may be stale' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(color: colors.mutedText, fontSize: 9),
                ),
                const Divider(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree_rounded,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$repositoryCount ${repositoryCount == 1 ? 'repository' : 'repositories'} connected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          color: colors.secondaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('manage-repositories'),
                      onPressed: onManage,
                      icon: const Icon(Icons.tune_rounded, size: 14),
                      label: const Text('Manage'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        textStyle: _textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _openRepositoryUrl(repository!.url, onAction),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('View on GitHub'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: EdgeInsets.zero,
                        textStyle: _textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: refreshingRepository ? null : onRefresh,
                      icon: refreshingRepository
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 14),
                      label: Text(
                        refreshingRepository ? 'Refreshing' : 'Refresh',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: EdgeInsets.zero,
                        textStyle: _textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 24,
            vertical: compact ? 28 : 32,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      Color(0xFF101D38),
                      Color(0xFF123568),
                      Color(0xFF145278),
                    ]
                  : const [
                      Color(0xCC0341C4),
                      Color(0xCC066BE0),
                      Color(0xCC1795DF),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? colors.shadow.withValues(alpha: 0.9)
                    : const Color(0xFF165ADC).withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _HeroWavePainter(animation: ambientMotion),
                  ),
                ),
              ),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCopy(
                      firstName: firstName,
                      role: role,
                      onAction: onAction,
                    ),
                    const SizedBox(height: 18),
                    projectPanel,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _HeroCopy(
                        firstName: firstName,
                        role: role,
                        onAction: onAction,
                      ),
                    ),
                    const SizedBox(width: 24),
                    projectPanel,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.firstName,
    required this.role,
    required this.onAction,
  });

  final String firstName;
  final String role;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role,
            style: _textStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome back, $firstName 👋',
          style: _textStyle(
            color: Colors.white,
            fontSize: MediaQuery.sizeOf(context).width < 600 ? 23 : 29,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 610),
          child: Text(
            "Here's what's happening in your projects today. Track progress, spot risks, and make data-driven engineering decisions with DevInsight.",
            style: _textStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : context.appTheme.secondaryText,
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            _HeroButton(
              label: 'View Insights',
              icon: Icons.insights_rounded,
              filled: true,
              onPressed: () => onAction(
                'Insights will be available after a repository is connected.',
              ),
            ),
            _HeroButton(
              label: 'Open Workspace',
              icon: Icons.folder_open_rounded,
              filled: false,
              onPressed: () =>
                  onAction('No project workspace is connected yet.'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: filled ? const Color(0xFF12C7EE) : Colors.transparent,
        foregroundColor: Colors.white,
        side: BorderSide(
          color: filled
              ? const Color(0xFF12C7EE)
              : Colors.white.withValues(alpha: 0.55),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: _textStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  _HeroWavePainter({required this.animation}) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value * math.pi * 2;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var x = size.width * 0.58; x < size.width; x += 8) {
      for (var y = size.height * 0.32; y < size.height; y += 8) {
        final wave =
            size.height * 0.72 -
            (x - size.width * 0.58) * 0.34 +
            15 * (1 + math.sin(x / 20 + phase));
        if (y > wave) {
          final shimmer = (math.sin(phase + x * 0.025 + y * 0.018) + 1) / 2;
          paint.color = Colors.white.withValues(alpha: 0.24 + shimmer * 0.24);
          canvas.drawCircle(
            Offset(x + math.sin(phase + y * 0.02) * 1.4, y),
            0.9 + shimmer * 0.45,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroWavePainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _ConnectedStatusIndicator extends StatefulWidget {
  const _ConnectedStatusIndicator();

  @override
  State<_ConnectedStatusIndicator> createState() =>
      _ConnectedStatusIndicatorState();
}

class _ConnectedStatusIndicatorState extends State<_ConnectedStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
    value: 0.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _pulse
        ..stop()
        ..value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Connected',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Transform.scale(
              scale: 0.94 + _pulse.value * 0.12,
              child: child,
            ),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.42),
                    blurRadius: 9,
                    spreadRadius: 1.2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Connected',
            style: _textStyle(
              color: const Color(0xFF168A47),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.detail,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 30 : 38,
            height: compact ? 30 : 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(compact ? 10 : 13),
            ),
            child: Icon(
              icon,
              size: compact ? 16 : 20,
              color: const Color(0xFF4C81D7),
            ),
          ),
          SizedBox(height: compact ? 7 : 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _textStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                color: const Color(0xFF78879D),
                fontSize: compact ? 8 : 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(covariant _Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_checkVisibility);
      widget.controller.addListener(_checkVisibility);
    }
  }

  void _checkVisibility() {
    if (_revealed || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final height = MediaQuery.sizeOf(context).height;
    if (top < height * 0.92 && bottom > 56) {
      setState(() => _revealed = true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedOpacity(
      opacity: _revealed || reduceMotion ? 1 : 0,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _revealed || reduceMotion
            ? Offset.zero
            : const Offset(0, 0.035),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

TextStyle _textStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );
}
