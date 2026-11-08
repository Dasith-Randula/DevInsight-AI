import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dashboard/core/constants/app_assets.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';
import 'package:web_dashboard/core/config/app_config.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFDFEAFE),
      drawer: Drawer(
        width: 272,
        child: SafeArea(
          child: _Navigation(
            expanded: true,
            onSelect: (label) {
              Navigator.of(context).pop();
              if (label != 'Home') _showMessage('$label is coming soon.');
            },
            onHelp: () {
              Navigator.of(context).pop();
              _showMessage('Support resources are coming soon.');
            },
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF7FAFF),
              Color(0xFFEEF5FF),
              Color(0xFFF9FBFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, 0.32, 0.72, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: _AnimatedDotBackground(
                animation: _ambientMotionController,
              ),
            ),
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
                                controller: _scrollController,
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
                                    child: _DashboardContent(
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
                                      refreshingRepository:
                                          _refreshingRepository,
                                      onConnect: _showConnectRepository,
                                      onManage: _showManageRepositories,
                                      onRetry: _loadRepositories,
                                      onRefresh: _refreshRepository,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: _TopBar(
                                name: _displayName,
                                role: _role,
                                scrollController: _scrollController,
                                onMenu: desktop
                                    ? null
                                    : () => _scaffoldKey.currentState
                                          ?.openDrawer(),
                                onProfile: _showProfileMenu,
                                onAction: _showMessage,
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
                          child: _Navigation(
                            expanded: false,
                            onSelect: (label) {
                              if (label != 'Home') {
                                _showMessage('$label is coming soon.');
                              }
                            },
                            onHelp: () => _showMessage(
                              'Support resources are coming soon.',
                            ),
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

class _AnimatedDotBackground extends StatelessWidget {
  const _AnimatedDotBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlueDotPainter(animation: animation),
      size: Size.infinite,
    );
  }
}

class _BlueDotPainter extends CustomPainter {
  const _BlueDotPainter({required this.animation}) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint();
    final glows = [
      (Offset(size.width * 0.86, size.height * 0.12), size.width * 0.42),
      (Offset(size.width * 0.16, size.height * 0.82), size.width * 0.38),
      (Offset(size.width * 0.84, size.height * 0.78), size.width * 0.34),
    ];
    for (final (center, radius) in glows) {
      glowPaint.shader = RadialGradient(
        colors: [
          const Color(0x183B82F6),
          const Color(0x0C38A5E8),
          const Color(0x003B82F6),
        ],
        stops: const [0, 0.52, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawRect(Offset.zero & size, glowPaint);
    }

    const spacing = 44.0;
    final phase = animation.value * math.pi * 2;
    for (var row = 0, y = 24.0; y < size.height; row++, y += spacing) {
      for (var column = 0, x = 22.0; x < size.width; column++, x += spacing) {
        final wave = math.sin(phase + column * 0.23 + row * 0.18);
        final radius = 1.0 + (wave + 1) * 0.48;
        final opacity = 0.11 + (wave + 1) * 0.055;
        final paint = Paint()..color = Color.fromRGBO(34, 111, 226, opacity);
        canvas.drawCircle(Offset(x, y + wave * 1.2), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BlueDotPainter oldDelegate) =>
      oldDelegate.animation != animation;
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
                      child: _BrandIntro(
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
                    child: _ScrollMouseIndicator(
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
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _MetricGrid(
                key: nextSectionKey,
                width: width,
                overview: overview,
                hasRepository: repository != null,
                loading: loadingRepository,
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _ResponsivePair(
                breakpoint: 820,
                children: [
                  _ChartPanel(
                    title: 'Weekly Productivity',
                    subtitle:
                        'Weekly commit activity from the connected repository.',
                    icon: Icons.insights_rounded,
                    overview: overview,
                  ),
                  _ChartPanel(
                    title: 'Project Risk Trend',
                    subtitle:
                        'Machine-learning risk predictions are not implemented.',
                    icon: Icons.trending_down_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _ResponsivePair(
                breakpoint: 820,
                children: [
                  _TasksPanel(onAction: onAction),
                  _ContributionPanel(overview: overview),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _InsightsSection(onAction: onAction),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _ResponsivePair(
                breakpoint: 820,
                children: [
                  _ProjectHealthPanel(overview: overview, onAction: onAction),
                  _QualityMetricsPanel(overview: overview, onAction: onAction),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _ResponsivePair(
                breakpoint: 820,
                children: [
                  _ActivityPanel(
                    onAction: onAction,
                    overview: overview,
                    hasRepository: repository != null,
                  ),
                  _RemindersPanel(onAction: onAction),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _QuickActions(onAction: onAction),
            ),
          ],
        );
      },
    );
  }
}

class _ScrollMouseIndicator extends StatefulWidget {
  const _ScrollMouseIndicator({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ScrollMouseIndicator> createState() => _ScrollMouseIndicatorState();
}

class _ScrollMouseIndicatorState extends State<_ScrollMouseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wheelMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool? _motionDisabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled == motionDisabled) return;
    _motionDisabled = motionDisabled;
    if (motionDisabled) {
      _wheelMotion
        ..stop()
        ..value = 0;
    } else {
      _wheelMotion.repeat();
    }
  }

  @override
  void dispose() {
    _wheelMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Scroll to dashboard content',
        child: Tooltip(
          message: 'Scroll to dashboard content',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('scroll-down-button'),
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(28, 44),
                      painter: _ScrollMousePainter(animation: _wheelMotion),
                    ),
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

class _ScrollMousePainter extends CustomPainter {
  const _ScrollMousePainter({required this.animation})
    : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final mouse = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 2, size.width - 6, size.height - 4),
      const Radius.circular(11),
    );
    final glowPaint = Paint()
      ..color = const Color(0xFF1769E8).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final outlinePaint = Paint()
      ..color = const Color(0xFF1769E8).withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..isAntiAlias = true;
    canvas
      ..drawRRect(mouse, glowPaint)
      ..drawRRect(mouse, outlinePaint);

    final progress = animation.value;
    final wheelTop = 9 + progress * 10;
    final wheelOpacity = (1 - progress).clamp(0.0, 1.0);
    final wheel = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 1.2, wheelTop, 2.4, 5),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      wheel,
      Paint()
        ..color = const Color(0xFF1769E8).withValues(alpha: wheelOpacity)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _ScrollMousePainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _Navigation extends StatefulWidget {
  const _Navigation({
    required this.expanded,
    required this.onSelect,
    required this.onHelp,
  });

  final bool expanded;
  final ValueChanged<String> onSelect;
  final VoidCallback onHelp;

  @override
  State<_Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<_Navigation> {
  bool _hovered = false;
  bool _showLabels = false;

  static const _mainItems = [
    ('Home', Icons.home_rounded),
    ('Projects', Icons.folder_open_rounded),
    ('My Work', Icons.bar_chart_rounded),
    ('Issues', Icons.bug_report_outlined),
    ('Pull Requests', Icons.merge_rounded),
    ('Code Quality', Icons.verified_outlined),
    ('Analytics', Icons.show_chart_rounded),
    ('AI Insights', Icons.auto_awesome_rounded),
  ];

  static const _workspaceItems = [
    ('Team', Icons.people_outline_rounded),
    ('Reports', Icons.description_outlined),
    ('Settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final expanded = widget.expanded || _hovered;
    final showLabels = widget.expanded || _showLabels;
    return MouseRegion(
      onEnter: widget.expanded
          ? null
          : (_) {
              setState(() {
                _hovered = true;
                _showLabels = false;
              });
            },
      onExit: widget.expanded
          ? null
          : (_) {
              setState(() {
                _hovered = false;
                _showLabels = false;
              });
            },
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(expanded ? 18 : 0),
          bottomRight: Radius.circular(expanded ? 18 : 0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            onEnd: () {
              if (_hovered && !_showLabels) setState(() => _showLabels = true);
            },
            width: widget.expanded
                ? double.infinity
                : expanded
                ? 224
                : 76,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              border: Border(
                right: BorderSide(
                  color: const Color(0xFFDCE7F8).withValues(alpha: 0.78),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final item in _mainItems)
                        _NavItem(
                          title: item.$1,
                          icon: item.$2,
                          active: item.$1 == 'Home',
                          expanded: showLabels,
                          onTap: () => widget.onSelect(item.$1),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          expanded ? 12 : 0,
                          14,
                          0,
                          8,
                        ),
                        child: showLabels
                            ? Text(
                                'WORKSPACE',
                                style: _textStyle(
                                  color: const Color(0xFF8290A8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              )
                            : const Divider(
                                color: Color(0xFFE6ECF7),
                                height: 12,
                              ),
                      ),
                      for (final item in _workspaceItems)
                        _NavItem(
                          title: item.$1,
                          icon: item.$2,
                          active: false,
                          expanded: showLabels,
                          onTap: () => widget.onSelect(item.$1),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Need Help?',
                  child: Material(
                    color: const Color(0xFFEDF4FF),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: widget.onHelp,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: expanded ? 12 : 9,
                          vertical: 11,
                        ),
                        child: Row(
                          mainAxisAlignment: showLabels
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.help_outline_rounded,
                              color: AppColors.primaryBlue,
                              size: 19,
                            ),
                            if (showLabels) ...[
                              const SizedBox(width: 10),
                              Text(
                                'Need Help?',
                                style: _textStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.title,
    required this.icon,
    required this.active,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryBlue : const Color(0xFF596A85);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Tooltip(
        message: expanded ? '' : title,
        child: Material(
          color: active ? const Color(0xFFE6EFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              height: 39,
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Icon(icon, size: 18, color: color),
                  ),
                  if (expanded)
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          color: active ? const Color(0xFF163A91) : color,
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    required this.role,
    required this.scrollController,
    required this.onMenu,
    required this.onProfile,
    required this.onAction,
  });

  final String name;
  final String role;
  final ScrollController scrollController;
  final VoidCallback? onMenu;
  final VoidCallback onProfile;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrolled = scrollController.hasClients
            ? (scrollController.offset / 54).clamp(0.0, 1.0)
            : 0.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 8 + scrolled * 16,
              sigmaY: 8 + scrolled * 16,
            ),
            child: Container(
              key: const ValueKey('topbar-surface'),
              height: 62,
              margin: const EdgeInsets.fromLTRB(10, 7, 10, 0),
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93 - scrolled * 0.39),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(
                      0xFFD8E4F6,
                    ).withValues(alpha: 0.82 - scrolled * 0.24),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (onMenu != null)
                    IconButton(
                      onPressed: onMenu,
                      tooltip: 'Open navigation',
                      icon: const Icon(Icons.menu_rounded),
                      color: const Color(0xFF334567),
                    ),
                  if (!compact)
                    OutlinedButton.icon(
                      onPressed: () =>
                          onAction('Workspace switching is coming soon.'),
                      icon: const Icon(Icons.code_rounded, size: 15),
                      label: const Text('My Workspace'),
                      iconAlignment: IconAlignment.start,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF263B62),
                        side: const BorderSide(color: Color(0xFFE1E9F7)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        textStyle: _textStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (!compact) const SizedBox(width: 20),
                  Expanded(
                    child: Align(
                      alignment: compact
                          ? Alignment.centerLeft
                          : Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 470),
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            readOnly: true,
                            onTap: () => onAction(
                              'Search will be available when workspace data is connected.',
                            ),
                            decoration: InputDecoration(
                              hintText: compact
                                  ? 'Search'
                                  : 'Search projects, issues, PRs, people...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                              ),
                              suffixIcon: compact
                                  ? null
                                  : Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Center(
                                        widthFactor: 1,
                                        child: Text(
                                          'Ctrl + K',
                                          style: _textStyle(
                                            color: const Color(0xFF7E8CA4),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                              filled: true,
                              fillColor: const Color(0xFFF5F8FE),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5ECF7),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5ECF7),
                                ),
                              ),
                            ),
                            style: _textStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!compact) const SizedBox(width: 16),
                  _TopBarIcon(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifications',
                    onPressed: () => onAction('You have no new notifications.'),
                  ),
                  if (!compact)
                    _TopBarIcon(
                      icon: Icons.help_outline_rounded,
                      tooltip: 'Help',
                      onPressed: () =>
                          onAction('Support resources are coming soon.'),
                    ),
                  if (!compact)
                    _TopBarIcon(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: () => onAction('Settings are coming soon.'),
                    ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: onProfile,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      foregroundColor: const Color(0xFF233552),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _Avatar(name: name, size: 31),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _textStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _textStyle(
                                    color: const Color(0xFF7887A0),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 19),
      color: const Color(0xFF4A5D7A),
      visualDensity: VisualDensity.compact,
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
                _Avatar(name: name, size: 42),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0764F6), Color(0xFF29B7F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Text(
        initials.isEmpty ? 'D' : initials,
        style: _textStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BrandIntro extends StatelessWidget {
  const _BrandIntro({required this.animation, required this.topPadding});

  final Animation<double> animation;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = (constraints.maxWidth * 0.168).clamp(67.2, 140.8);
        final baseStyle = GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 3.52,
        );
        final insightStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
        final outlineWidth = ((fontSize / 1.6) / 26).clamp(2.0, 3.2) * 0.62;
        return Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  key: const ValueKey('devinsight-wordmark'),
                  fit: BoxFit.scaleDown,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final phase = animation.value;
                      const fillEnd = 0.60;
                      const holdEnd = 0.68;
                      const drainEnd = 0.96;
                      final fillDuration = fillEnd / 'INSIGHT'.length;
                      final drainDuration =
                          (drainEnd - holdEnd) / 'INSIGHT'.length;
                      return Semantics(
                        label: 'DevInsight',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'DEV',
                              style: baseStyle.copyWith(
                                color: const Color(0xFF111C31),
                                letterSpacing: fontSize * 0.05,
                              ),
                            ),
                            SizedBox(width: fontSize * 0.05),
                            for (
                              var index = 0;
                              index < 'INSIGHT'.length;
                              index++
                            )
                              _WaterFillLetter(
                                letter: 'INSIGHT'[index],
                                style: insightStyle,
                                outlineWidth: outlineWidth,
                                progress: _letterFillProgress(
                                  phase: phase,
                                  index: index,
                                  fillDuration: fillDuration,
                                  fillEnd: fillEnd,
                                  holdEnd: holdEnd,
                                  drainEnd: drainEnd,
                                  drainDuration: drainDuration,
                                ),
                                wavePhase: phase * math.pi * 2 + index * 0.9,
                                rightPadding: index == 'INSIGHT'.length - 1
                                    ? 0
                                    : fontSize * 0.025,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Powered Software Engineering Intelligence',
                  textAlign: TextAlign.center,
                  style: _textStyle(
                    color: const Color(0xFF273C61),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Smarter development. Clearer insights. Better decisions.',
                  textAlign: TextAlign.center,
                  style: _textStyle(
                    color: const Color(0xFF71819C),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

double _letterFillProgress({
  required double phase,
  required int index,
  required double fillDuration,
  required double fillEnd,
  required double holdEnd,
  required double drainEnd,
  required double drainDuration,
}) {
  if (phase < fillEnd) {
    final local = ((phase - index * fillDuration) / fillDuration).clamp(
      0.0,
      1.0,
    );
    return Curves.easeInOutCubic.transform(local);
  }
  if (phase < holdEnd) return 1;
  if (phase < drainEnd) {
    final reverseIndex = 'INSIGHT'.length - 1 - index;
    final local =
        ((phase - holdEnd - reverseIndex * drainDuration) / drainDuration)
            .clamp(0.0, 1.0);
    return 1 - Curves.easeInOutCubic.transform(local);
  }
  return 0;
}

class _WaterFillLetter extends StatelessWidget {
  const _WaterFillLetter({
    required this.letter,
    required this.style,
    required this.outlineWidth,
    required this.progress,
    required this.wavePhase,
    required this.rightPadding,
  });

  final String letter;
  final TextStyle style;
  final double outlineWidth;
  final double progress;
  final double wavePhase;
  final double rightPadding;

  @override
  Widget build(BuildContext context) {
    final painter = _WaterFillPainter(
      letter: letter,
      style: style,
      outlineWidth: outlineWidth,
      progress: progress,
      wavePhase: wavePhase,
    );
    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: Stack(
        key: ValueKey('wordmark-letter-$letter'),
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.all(painter.padding),
            child: Text(
              letter,
              style: style.copyWith(color: Colors.transparent),
              textScaler: TextScaler.noScaling,
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: painter)),
        ],
      ),
    );
  }
}

class _WaterFillPainter extends CustomPainter {
  _WaterFillPainter({
    required this.letter,
    required this.style,
    required this.outlineWidth,
    required this.progress,
    required this.wavePhase,
  }) : _outline = _createPainter(
         letter,
         style.copyWith(
           foreground: Paint()
             ..style = PaintingStyle.stroke
             ..strokeWidth = outlineWidth
             ..strokeJoin = StrokeJoin.bevel
             ..isAntiAlias = true
             ..color = const Color(0xFF1769E8),
         ),
       ),
       _fill = _createPainter(letter, _fillStyle(letter, style, outlineWidth)),
       padding = style.fontSize! * 0.10 + outlineWidth {
    size = Size(_fill.width + padding * 2, _fill.height + padding * 2);
  }

  final String letter;
  final TextStyle style;
  final double outlineWidth;
  final double progress;
  final double wavePhase;
  final TextPainter _outline;
  final TextPainter _fill;
  final double padding;
  late final Size size;

  static TextPainter _createPainter(String letter, TextStyle style) =>
      TextPainter(
        text: TextSpan(text: letter, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();

  static TextStyle _fillStyle(
    String letter,
    TextStyle style,
    double outlineWidth,
  ) {
    final painter = _createPainter(letter, style);
    final textPadding = style.fontSize! * 0.10 + outlineWidth;
    return style.copyWith(
      foreground: Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF0756D8), Color(0xFF168DF1)],
            ).createShader(
              Rect.fromLTWH(
                textPadding,
                textPadding,
                painter.width,
                painter.height,
              ),
            ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final textOrigin = Offset(padding, padding);
    if (progress < 1) {
      _outline.paint(canvas, textOrigin);
    }
    if (progress <= 0) return;

    canvas.save();
    if (progress < 1) {
      canvas.clipPath(_waterSurface(size), doAntiAlias: true);
    }
    _fill.paint(canvas, textOrigin);
    canvas.restore();
  }

  Path _waterSurface(Size paintSize) {
    final level = paintSize.height * (1 - progress);
    final amplitude = math.min(2.8, paintSize.height * 0.025);
    final path = Path()..moveTo(0, level + math.sin(wavePhase) * amplitude);
    for (double x = 2; x < paintSize.width; x += 2) {
      final y = level + math.sin(wavePhase + x * 0.045) * amplitude;
      path.lineTo(x, y);
    }
    return path
      ..lineTo(paintSize.width, paintSize.height)
      ..lineTo(0, paintSize.height)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _WaterFillPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.wavePhase != wavePhase ||
      oldDelegate.style != style ||
      oldDelegate.outlineWidth != outlineWidth;
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
    final projectPanel = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          width: compact ? double.infinity : 270,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.88),
                const Color(0xFFEAF4FF).withValues(alpha: 0.78),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF08256F).withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.24),
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
                          color: const Color(0xFF52617A),
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
                    color: const Color(0xFF687A96),
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
                    color: const Color(0xFF687A96),
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Owner: ${repository!.owner}  ·  Branch: ${repository!.defaultBranch ?? 'Unknown'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    color: const Color(0xFF687A96),
                    fontSize: 9,
                  ),
                ),
                Text(
                  'Stars: ${repository!.stars}  ·  Forks: ${repository!.forks}',
                  style: _textStyle(
                    color: const Color(0xFF687A96),
                    fontSize: 9,
                  ),
                ),
                Text(
                  'Primary language: ${repository!.primaryLanguage ?? 'Not available'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    color: const Color(0xFF687A96),
                    fontSize: 9,
                  ),
                ),
                Text(
                  '${repositoryError ?? 'Public repository'} · Last synced ${_formatSyncTime(repository!.lastSyncedAt)}${overview?.isStale == true || repositoryError != null ? ' · Cached data may be stale' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    color: const Color(0xFF687A96),
                    fontSize: 9,
                  ),
                ),
                const Divider(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree_rounded,
                      size: 14,
                      color: Color(0xFF52617A),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$repositoryCount ${repositoryCount == 1 ? 'repository' : 'repositories'} connected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          color: const Color(0xFF52617A),
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
            gradient: const LinearGradient(
              colors: [Color(0xCC0341C4), Color(0xCC066BE0), Color(0xCC1795DF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF165ADC).withValues(alpha: 0.18),
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
            color: Colors.white.withValues(alpha: 0.15),
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
              color: const Color(0xFFE3F0FF),
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    super.key,
    required this.width,
    required this.overview,
    required this.hasRepository,
    required this.loading,
  });

  final double width;
  final GitHubRepositoryOverview? overview;
  final bool hasRepository;
  final bool loading;

  List<
    ({
      String title,
      IconData icon,
      Color accent,
      Color tint,
      String value,
      String detail,
    })
  >
  get _metrics => [
    (
      title: 'Assigned Issues',
      icon: Icons.code_rounded,
      accent: const Color(0xFF2878F0),
      tint: const Color(0xFFEAF2FF),
      value: 'Not linked',
      detail: 'Personal GitHub identity is not linked',
    ),
    (
      title: 'Resolved Issues',
      icon: Icons.check_circle_outline_rounded,
      accent: const Color(0xFF12A878),
      tint: const Color(0xFFE7F8F1),
      value: !hasRepository
          ? 'No repository'
          : loading
          ? 'Loading'
          : overview?.resolvedIssues30d?.toString() ?? 'Unavailable',
      detail: 'Closed issues in the last 30 days',
    ),
    (
      title: 'Productivity Score',
      icon: Icons.bolt_rounded,
      accent: const Color(0xFF1989E8),
      tint: const Color(0xFFE8F5FF),
      value: 'Unavailable',
      detail: 'A validated score is not implemented',
    ),
    (
      title: 'Open Pull Requests',
      icon: Icons.merge_rounded,
      accent: const Color(0xFF795BF5),
      tint: const Color(0xFFF0ECFF),
      value: !hasRepository
          ? 'No repository'
          : loading
          ? 'Loading'
          : overview?.openPullRequests?.toString() ?? 'Unavailable',
      detail: overview?.openPullRequests == 0
          ? 'No open pull requests'
          : 'Open GitHub pull requests',
    ),
    (
      title: 'Code Quality',
      icon: Icons.shield_outlined,
      accent: const Color(0xFF2C72D5),
      tint: const Color(0xFFEAF2FF),
      value: switch (overview?.qualitySignals?.ci.state) {
        'success' => 'CI passing',
        'failure' => 'CI failing',
        'pending' => 'Checks pending',
        'not_configured' => 'Not configured',
        _ => 'Not measured',
      },
      detail: 'CI status only · not a quality score',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final columns = width >= 1200
        ? 5
        : width >= 760
        ? 3
        : 2;
    const gap = 12.0;
    final itemWidth = (width - (columns - 1) * gap) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final metric in _metrics)
          SizedBox(
            width: itemWidth,
            child: _MetricCard(
              title: metric.title,
              icon: metric.icon,
              accent: metric.accent,
              tint: metric.tint,
              value: metric.value,
              detail: metric.detail,
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.value,
    required this.detail,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color tint;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: accent),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      color: const Color(0xFF72819A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.info_outline_rounded, size: 13, color: accent),
              ],
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(color: const Color(0xFF8A96AA), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.children, this.breakpoint = 820});

  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.overview,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final GitHubRepositoryOverview? overview;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: 14),
          Container(
            height: 204,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAF0FA)),
            ),
            child: title == 'Weekly Productivity'
                ? _WeeklyActivityChart(overview: overview)
                : Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _ChartGridPainter()),
                      ),
                      const Center(
                        child: _EmptyState(
                          icon: Icons.show_chart_rounded,
                          title: 'Risk prediction unavailable',
                          detail:
                              'Machine-learning risk prediction is not implemented.',
                          compact: true,
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

class _WeeklyActivityChart extends StatefulWidget {
  const _WeeklyActivityChart({required this.overview});

  final GitHubRepositoryOverview? overview;

  @override
  State<_WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeeklyActivityChartState extends State<_WeeklyActivityChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  int? _hoveredWeek;

  GitHubWeeklyActivity? get _activity => widget.overview?.weeklyActivity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _animationController
        ..stop()
        ..value = 1;
    } else if (_animationController.status == AnimationStatus.dismissed) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _WeeklyActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overview?.connection.id != widget.overview?.connection.id ||
        oldWidget.overview?.connection.lastSyncedAt !=
            widget.overview?.connection.lastSyncedAt) {
      _hoveredWeek = null;
      if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
        _animationController
          ..value = 0
          ..forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    if (widget.overview == null) {
      return const _WeeklyActivityEmpty(
        title: 'Connect a repository',
        detail: 'Weekly commit totals will appear after GitHub data is loaded.',
      );
    }
    if (activity == null ||
        activity.availability != 'available' ||
        !activity.isComplete ||
        activity.weeks.length != 8 ||
        activity.weeks.any((week) => week.commits == null)) {
      final status = activity?.availability;
      final message = status == 'processing'
          ? 'GitHub is preparing weekly statistics. Refresh later to retry.'
          : status == 'incomplete'
          ? 'GitHub has not returned a complete 8-week period. Totals are withheld.'
          : 'Weekly activity is not measured by GitHub yet.';
      return _WeeklyActivityEmpty(
        title: status == 'processing'
            ? 'Statistics processing'
            : 'Activity unavailable',
        detail: message,
      );
    }

    final weeks = activity.weeks;
    final total = activity.totalCommits;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${total ?? 0} commits · ${activity.branch ?? 'default branch'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    color: const Color(0xFF31527E),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_hoveredWeek case final index?)
                Text(
                  '${_weekLabel(weeks[index].weekStart)}: ${weeks[index].commits}',
                  style: _textStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) {
                    if (constraints.maxWidth <= 0) return;
                    final index =
                        ((event.localPosition.dx / constraints.maxWidth) *
                                weeks.length)
                            .floor()
                            .clamp(0, weeks.length - 1);
                    if (_hoveredWeek != index) {
                      setState(() => _hoveredWeek = index);
                    }
                  },
                  onExit: (_) => setState(() => _hoveredWeek = null),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _WeeklyActivityPainter(
                        values: weeks.map((week) => week.commits!).toList(),
                        progress: _animationController.value,
                        hoveredIndex: _hoveredWeek,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              for (final week in weeks)
                Expanded(
                  child: Text(
                    _weekLabel(week.weekStart),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: _textStyle(
                      color: const Color(0xFF7588A5),
                      fontSize: 7,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${_formatDate(activity.periodStart)} – ${_formatDate(activity.periodEnd)} UTC · weeks start ${activity.weekBoundary}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(color: const Color(0xFF8090A7), fontSize: 7),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityEmpty extends StatelessWidget {
  const _WeeklyActivityEmpty({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _ChartGridPainter())),
        Center(
          child: _EmptyState(
            icon: Icons.insights_rounded,
            title: title,
            detail: detail,
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _WeeklyActivityPainter extends CustomPainter {
  const _WeeklyActivityPainter({
    required this.values,
    required this.progress,
    required this.hoveredIndex,
  });

  final List<int> values;
  final double progress;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 20.0;
    const right = 5.0;
    const top = 7.0;
    const bottom = 9.0;
    final chartWidth = math.max(0.0, size.width - left - right);
    final chartHeight = math.max(0.0, size.height - top - bottom);
    if (chartWidth == 0 || chartHeight == 0 || values.isEmpty) return;

    final maximum = math.max(1, values.reduce(math.max));
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE8F7)
      ..strokeWidth = 1;
    for (var line = 0; line <= 3; line++) {
      final y = top + chartHeight * line / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    final slotWidth = chartWidth / values.length;
    final barWidth = math.min(20.0, slotWidth * 0.54);
    for (var index = 0; index < values.length; index++) {
      final barHeight =
          chartHeight *
          values[index] /
          maximum *
          Curves.easeOutCubic.transform(progress);
      final x = left + slotWidth * index + (slotWidth - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          top + chartHeight - barHeight,
          barWidth,
          math.max(2, barHeight),
        ),
        const Radius.circular(4),
      );
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF58CAFF), Color(0xFF2277FF), Color(0xFF0056FF)],
        ).createShader(rect.outerRect)
        ..colorFilter = ColorFilter.mode(
          hoveredIndex == index
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          BlendMode.srcATop,
        );
      canvas.drawRRect(rect, paint);
      if (hoveredIndex == index) {
        canvas.drawCircle(
          Offset(x + barWidth / 2, top + chartHeight - barHeight),
          3.5,
          Paint()..color = const Color(0xFF0056FF),
        );
      }
    }

    final labelPainter = TextPainter(
      text: TextSpan(
        text: maximum.toString(),
        style: const TextStyle(
          color: Color(0xFF8393AA),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(0, top - 4));
    final zeroPainter = TextPainter(
      text: const TextSpan(
        text: '0',
        style: TextStyle(color: Color(0xFF8393AA), fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    zeroPainter.paint(canvas, Offset(5, top + chartHeight - 4));
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.progress != progress ||
      oldDelegate.hoveredIndex != hoveredIndex;
}

String _weekLabel(DateTime week) =>
    '${week.month}/${week.day.toString().padLeft(2, '0')}';

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.month}/${date.day}/${date.year}';
}

class _ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7EDF8)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), paint);
    }
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartGridPainter oldDelegate) => false;
}

class _TasksPanel extends StatelessWidget {
  const _TasksPanel({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'My Tasks',
            subtitle: 'Tasks assigned to you across active projects.',
            trailing: TextButton(
              onPressed: () => onAction(
                'Tasks will be available when a project is connected.',
              ),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 12),
          const _TaskHeaders(),
          const SizedBox(height: 4),
          const SizedBox(
            height: 154,
            child: Center(
              child: _EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'No tasks yet',
                detail: 'Tasks will appear here after you connect a project.',
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskHeaders extends StatelessWidget {
  const _TaskHeaders();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labels = constraints.maxWidth < 560
            ? 'ISSUE  ·  TASK  ·  PRIORITY  ·  STATUS  ·  DUE DATE  ·  PROJECT'
            : 'ISSUE ID                      TASK                                      PRIORITY       STATUS          DUE DATE       PROJECT';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            labels,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              color: const Color(0xFF8995A9),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
            ),
          ),
        );
      },
    );
  }
}

class _ContributionPanel extends StatelessWidget {
  const _ContributionPanel({required this.overview});

  final GitHubRepositoryOverview? overview;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Repository Languages',
            subtitle: 'Repository language composition from GitHub.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 154,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final languages =
                    overview?.languages ?? const <GitHubLanguage>[];
                if (languages.isNotEmpty) {
                  return ListView(
                    children: [
                      for (final language in languages.take(5)) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                language.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _textStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${language.percentage.toStringAsFixed(1)}%',
                              style: _textStyle(
                                color: const Color(0xFF687A96),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (language.percentage / 100).clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2EAF6),
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }
                final compact = constraints.maxWidth < 450;
                final chart = SizedBox(
                  width: compact ? 112 : 142,
                  height: compact ? 112 : 142,
                  child: CustomPaint(
                    painter: _EmptyDonutPainter(),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.code_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No data',
                            style: _textStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                const legend = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(label: 'Languages', value: 'Not available'),
                    SizedBox(height: 10),
                    _LegendItem(label: 'Commits', value: 'Not available'),
                    SizedBox(height: 10),
                    _LegendItem(label: 'Pull requests', value: 'Not available'),
                  ],
                );
                if (compact) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      chart,
                      const SizedBox(height: 10),
                      Text(
                        overview == null
                            ? 'Connect a repository to view its language composition.'
                            : 'No language data is available for this repository.',
                        textAlign: TextAlign.center,
                        style: _textStyle(
                          color: const Color(0xFF77869D),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [chart, legend],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, size: 7, color: Color(0xFF8FA5C9)),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: _textStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
            Text(
              value,
              style: _textStyle(color: const Color(0xFF8190A6), fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = const Color(0xFFE2EAF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawArc(rect.deflate(9), 0, 6.283, false, paint);
    final accent = Paint()
      ..color = const Color(0xFF94B8F4).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(rect.deflate(2), -1.5, 1.5, false, accent);
  }

  @override
  bool shouldRepaint(covariant _EmptyDonutPainter oldDelegate) => false;
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.onAction});

  final ValueChanged<String> onAction;

  static const _insights = [
    (
      'Risk prediction unavailable',
      'Machine-learning risk predictions are not implemented.',
      Icons.warning_amber_rounded,
      Color(0xFFEF4444),
      Color(0xFFFEE2E2),
      Color(0xFFB91C1C),
      'Review Changes',
    ),
    (
      'Issue prioritization unavailable',
      'Validated AI issue-priority recommendations are not implemented.',
      Icons.lightbulb_outline_rounded,
      Color(0xFF0056FF),
      Color(0xFFDBEAFE),
      Color(0xFF1D4ED8),
      'Update Priority',
    ),
    (
      'Root-cause analysis unavailable',
      'AI root-cause analysis is not implemented.',
      Icons.account_tree_outlined,
      Color(0xFF7C3AED),
      Color(0xFFEDE9FE),
      Color(0xFF6D28D9),
      'View Analysis',
    ),
    (
      'Workload recommendations unavailable',
      'Validated team workload recommendations are not implemented.',
      Icons.auto_awesome_rounded,
      Color(0xFF06B6D4),
      Color(0xFFCFFAFE),
      Color(0xFF0E7490),
      'Rebalance Workload',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'AI Insights',
            subtitle:
                'Machine-learning predictions and recommendations are not available yet.',
            icon: Icons.auto_awesome_rounded,
            actionLabel: 'View all insights',
            onAction: () => onAction(
              'AI predictions and recommendations are not implemented.',
            ),
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;
              const gap = 10.0;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in _insights)
                    SizedBox(
                      width: cardWidth,
                      child: _InsightCard(
                        title: item.$1,
                        detail: item.$2,
                        icon: item.$3,
                        accent: item.$4,
                        tint: item.$5,
                        darkAccent: item.$6,
                        action: item.$7,
                        onPressed: () => onAction(
                          '${item.$1} is unavailable until project data is connected.',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.darkAccent,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final Color tint;
  final Color darkAccent;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      child: Container(
        constraints: const BoxConstraints.tightFor(height: 150),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tint,
          border: Border.all(color: accent.withValues(alpha: 0.48)),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: accent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      color: darkAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                color: const Color(0xFF64748A),
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                minimumSize: const Size(0, 29),
                backgroundColor: Colors.white.withValues(alpha: 0.76),
                textStyle: _textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectHealthPanel extends StatelessWidget {
  const _ProjectHealthPanel({required this.overview, required this.onAction});

  final GitHubRepositoryOverview? overview;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final health = overview?.repositoryHealth;
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Project Health',
            subtitle:
                'Repository Health — GitHub Signals · push within 14 days; open PRs over 14 days are aging. No ML risk score.',
            icon: Icons.favorite_border_rounded,
          ),
          const SizedBox(height: 12),
          Container(
            height: 184,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEAF0F8)),
            ),
            child: health == null
                ? const Center(
                    child: _EmptyState(
                      icon: Icons.folder_open_rounded,
                      title: 'Repository signals not measured',
                      detail:
                          'Connect or synchronize a repository to load GitHub operational signals.',
                      compact: true,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _HealthSignal(
                                icon: Icons.bolt_rounded,
                                title: 'Development activity',
                                value: switch (health.recentActivityStatus) {
                                  'recently_active' => 'Recently active',
                                  'no_recent_push' => 'No push in 14 days',
                                  _ => 'Not measured',
                                },
                                color: switch (health.recentActivityStatus) {
                                  'recently_active' => const Color(0xFF169B62),
                                  'no_recent_push' => const Color(0xFFD58A13),
                                  _ => const Color(0xFF8290A4),
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _HealthSignal(
                                icon: Icons.bug_report_outlined,
                                title: 'Open issues',
                                value:
                                    health.openIssues?.toString() ??
                                    'Not measured',
                                color: const Color(0xFF52617A),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _HealthSignal(
                                icon: Icons.merge_rounded,
                                title: 'Open pull requests',
                                value:
                                    health.openPullRequests?.toString() ??
                                    'Not measured',
                                color: const Color(0xFF52617A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _HealthSignal(
                                icon: Icons.verified_outlined,
                                title: 'CI',
                                value: _ciLabel(health.ciState),
                                color: _ciColor(health.ciState),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _HealthSignal(
                                icon: Icons.history_rounded,
                                title: 'Recently closed issues',
                                value:
                                    health.closedIssues30d?.toString() ??
                                    'Not measured',
                                color: const Color(0xFF52617A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _HealthSignal(
                                icon: Icons.update_rounded,
                                title: 'Last push',
                                value: _formatRelativeDate(
                                  health.lastPushAt ?? health.latestCommitAt,
                                ),
                                color: const Color(0xFF52617A),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: const Color(0xFF7C8BA2),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: InkWell(
                                onTap: health.oldestOpenPullRequestUrl == null
                                    ? null
                                    : () => _openRepositoryUrl(
                                        health.oldestOpenPullRequestUrl!,
                                        onAction,
                                      ),
                                child: Text(
                                  health.oldestOpenPullRequestAgeDays == null
                                      ? !health.oldestOpenPullRequestPresent &&
                                                health.oldestOpenPullRequestAvailability ==
                                                    'available'
                                            ? 'No open pull requests'
                                            : 'Oldest open PR age: Not measured'
                                      : 'Oldest open PR: ${health.oldestOpenPullRequestAgeDays} days${health.oldestOpenPullRequestAgeDays! > 14 ? ' · aging' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _textStyle(
                                    color:
                                        health.oldestOpenPullRequestAgeDays !=
                                                null &&
                                            health.oldestOpenPullRequestAgeDays! >
                                                14
                                        ? const Color(0xFFD58A13)
                                        : const Color(0xFF687A96),
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Updated ${_formatSyncTime(health.lastUpdatedAt)}',
                                maxLines: 1,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: _textStyle(
                                  color: const Color(0xFF687A96),
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QualityMetricsPanel extends StatelessWidget {
  const _QualityMetricsPanel({required this.overview, required this.onAction});

  final GitHubRepositoryOverview? overview;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final signals = overview?.qualitySignals;
    final ci = signals?.ci;
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Quality Metrics',
            subtitle:
                'GitHub CI and repository hygiene signals · no coverage or code-quality score.',
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 12),
          Container(
            height: 184,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEAF0F8)),
            ),
            child: signals == null
                ? const Center(
                    child: _EmptyState(
                      icon: Icons.shield_outlined,
                      title: 'Signals not measured',
                      detail:
                          'Connect or synchronize a repository to retrieve CI and hygiene data.',
                      compact: true,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _QualitySignal(
                                title: 'CI status',
                                value: _ciLabel(ci!.state),
                                color: _ciColor(ci.state),
                                icon: Icons.verified_outlined,
                                onTap: ci.url == null
                                    ? null
                                    : () =>
                                          _openRepositoryUrl(ci.url!, onAction),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QualitySignal(
                                title: 'Passed checks',
                                value: ci.passed?.toString() ?? 'Not measured',
                                color: const Color(0xFF169B62),
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _QualitySignal(
                                title: 'Failed checks',
                                value: ci.failed?.toString() ?? 'Not measured',
                                color: ci.failed == null
                                    ? const Color(0xFF8290A4)
                                    : ci.failed == 0
                                    ? const Color(0xFF169B62)
                                    : const Color(0xFFD84848),
                                icon: Icons.error_outline_rounded,
                                onTap: ci.url == null
                                    ? null
                                    : () =>
                                          _openRepositoryUrl(ci.url!, onAction),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QualitySignal(
                                title: 'Pending checks',
                                value: ci.pending?.toString() ?? 'Not measured',
                                color: const Color(0xFFD58A13),
                                icon: Icons.hourglass_bottom_rounded,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _QualitySignal(
                                title: 'Tests detected',
                                value: _boolSignal(signals.testsDetected),
                                color: _boolSignalColor(signals.testsDetected),
                                icon: Icons.science_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QualitySignal(
                                title: 'README / license',
                                value:
                                    '${_boolShort(signals.readmePresent)} / ${_boolShort(signals.licensePresent)}',
                                color:
                                    signals.readmePresent == false ||
                                        signals.licensePresent == false
                                    ? const Color(0xFFD58A13)
                                    : signals.readmePresent == true &&
                                          signals.licensePresent == true
                                    ? const Color(0xFF169B62)
                                    : const Color(0xFF8290A4),
                                icon: Icons.menu_book_outlined,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: signals.latestCommitUrl == null
                                  ? null
                                  : () => _openRepositoryUrl(
                                      signals.latestCommitUrl!,
                                      onAction,
                                    ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.code_rounded,
                                    size: 12,
                                    color: Color(0xFF52617A),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      signals.latestCommitSha == null
                                          ? 'Default-branch commit: Not measured'
                                          : 'Default branch commit · ${_shortSha(signals.latestCommitSha!)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _textStyle(
                                        color: const Color(0xFF52617A),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (signals.latestCommitUrl != null)
                                    const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 10,
                                      color: Color(0xFF52617A),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'Last completed check: ${_formatSyncTime(ci.lastCompletedAt)} · detected tests are not proof of passing.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _textStyle(
                                color: const Color(0xFF75859C),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HealthSignal extends StatelessWidget {
  const _HealthSignal({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(color: const Color(0xFF8491A5), fontSize: 7),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QualitySignal extends StatelessWidget {
  const _QualitySignal({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      color: const Color(0xFF8491A5),
                      fontSize: 7,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.open_in_new_rounded,
                size: 10,
                color: Color(0xFF8491A5),
              ),
          ],
        ),
      ),
    );
  }
}

String _ciLabel(String state) => switch (state) {
  'success' => 'Passing',
  'failure' => 'Failing',
  'pending' => 'Pending',
  'not_configured' => 'Not configured',
  _ => 'Not measured',
};

Color _ciColor(String state) => switch (state) {
  'success' => const Color(0xFF169B62),
  'failure' => const Color(0xFFD84848),
  'pending' => const Color(0xFFD58A13),
  _ => const Color(0xFF8290A4),
};

String _boolSignal(bool? value) => switch (value) {
  true => 'Detected',
  false => 'Not detected',
  null => 'Not measured',
};

String _boolShort(bool? value) => switch (value) {
  true => 'Yes',
  false => 'No',
  null => '—',
};

String _shortSha(String sha) => sha.length <= 7 ? sha : sha.substring(0, 7);

Color _boolSignalColor(bool? value) => switch (value) {
  true => const Color(0xFF169B62),
  false => const Color(0xFFD58A13),
  null => const Color(0xFF8290A4),
};

String _formatRelativeDate(DateTime? date) {
  if (date == null) return 'Not measured';
  final delta = DateTime.now().toUtc().difference(date.toUtc());
  if (delta.isNegative) return 'Just now';
  if (delta.inDays == 0) return 'Today';
  if (delta.inDays == 1) return '1 day ago';
  return '${delta.inDays} days ago';
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.onAction,
    required this.overview,
    required this.hasRepository,
  });

  final ValueChanged<String> onAction;
  final GitHubRepositoryOverview? overview;
  final bool hasRepository;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Recent Repository Activity',
            subtitle: 'Recent commits, issues, and pull requests from GitHub.',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: overview == null || overview!.recentActivity.isEmpty
                ? Center(
                    child: _EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No recent activity',
                      detail: hasRepository
                          ? 'GitHub returned no recent commit, issue, or pull request activity.'
                          : 'Connect a repository to load actual GitHub activity.',
                      compact: true,
                    ),
                  )
                : ListView.separated(
                    itemCount: overview!.recentActivity.take(5).length,
                    separatorBuilder: (_, _) => const Divider(height: 10),
                    itemBuilder: (context, index) {
                      final activity = overview!.recentActivity[index];
                      final icon = switch (activity.type) {
                        'commit' => Icons.commit_rounded,
                        'issue' => Icons.bug_report_outlined,
                        'pull_request' => Icons.merge_rounded,
                        _ => Icons.history_rounded,
                      };
                      return Row(
                        children: [
                          Icon(icon, size: 15, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _textStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${activity.type.replaceAll('_', ' ')}${activity.state == null ? '' : ' · ${activity.state}'} · ${activity.author} · ${_formatSyncTime(activity.date)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _textStyle(
                                    color: const Color(0xFF687A96),
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open on GitHub',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                _openRepositoryUrl(activity.url, onAction),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RemindersPanel extends StatelessWidget {
  const _RemindersPanel({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Upcoming & Reminders',
            subtitle: 'Important events and delivery dates.',
            icon: Icons.event_note_rounded,
            actionLabel: 'View calendar',
            onAction: () => onAction('Project calendar is not available yet.'),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 148,
            child: Center(
              child: _EmptyState(
                icon: Icons.event_available_outlined,
                title: 'Nothing scheduled',
                detail: 'Project milestones and reminders will appear here.',
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            ('Run Analysis', Icons.analytics_outlined),
            ('Generate Report', Icons.description_outlined),
            ('Explore Projects', Icons.add_rounded),
          ];
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get more from DevInsight',
                style: _textStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Explore advanced analytics, AI assistance, and reports to improve your workflow.',
                style: _textStyle(color: const Color(0xFF697A94), fontSize: 10),
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
                  icon: Icon(action.$2, size: 14),
                  label: Text(action.$1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2456AE),
                    backgroundColor: const Color(0xFFF7FAFF),
                    side: const BorderSide(color: Color(0xFFDCE7F8)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    textStyle: _textStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          );
          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 14), buttons],
            );
          }
          return Row(
            children: [
              const _BrandMark(),
              const SizedBox(width: 12),
              Expanded(child: copy),
              const SizedBox(width: 14),
              buttons,
            ],
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.devInsightLogo,
      width: 36,
      height: 36,
      fit: BoxFit.contain,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.icon,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 5),
                    Icon(icon, size: 14, color: const Color(0xFF657D9D)),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(color: const Color(0xFF73829A), fontSize: 13),
              ),
            ],
          ),
        ),
        ?trailing,
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              minimumSize: const Size(0, 26),
              textStyle: _textStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xEBFFFFFF), Color(0xE2F0F5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFDEE8F7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB7CDF2).withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  const _HoverCard({required this.child});

  final Widget child;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF8EB2E8).withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
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
  Color color = const Color(0xFF182846),
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
