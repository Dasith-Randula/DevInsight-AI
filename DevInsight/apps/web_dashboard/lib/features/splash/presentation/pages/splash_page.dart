import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/devinsight_api.dart';
import '../widgets/splash_ecosystem_view.dart';

enum _SplashConnectionState { checking, offline, startupError }

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    ConnectivityService? connectivityService,
    this.onStartupComplete,
  }) : _connectivityService =
           connectivityService ?? const ConnectivityService();

  final ConnectivityService _connectivityService;
  final Future<bool> Function(BuildContext context)? onStartupComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _timelineController;
  late final Animation<double> _visualTimeline;
  _SplashConnectionState _connectionState = _SplashConnectionState.checking;
  bool? _motionDisabled;
  bool _checkInProgress = false;
  bool _hasNavigated = false;
  int _attempt = 0;

  ConnectivityService get _connectivityService => widget._connectivityService;

  @override
  void initState() {
    super.initState();
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6600),
    );
    _visualTimeline = Tween<double>(
      begin: 0,
      end: 6600 / 5600,
    ).animate(_timelineController);
    _timelineController.forward();
    _startStartupFlow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled == motionDisabled) return;
    _motionDisabled = motionDisabled;
    if (motionDisabled) {
      _timelineController
        ..stop()
        ..value = 1;
    } else if (_timelineController.isCompleted) {
      _timelineController
        ..value = 0
        ..forward();
    }
  }

  Future<void> _waitForTimeline() {
    if (_motionDisabled == true || _timelineController.isCompleted) {
      return Future<void>.value();
    }

    final completed = Completer<void>();
    late final AnimationStatusListener listener;
    listener = (status) {
      if (status != AnimationStatus.completed) return;
      _timelineController.removeStatusListener(listener);
      completed.complete();
    };
    _timelineController.addStatusListener(listener);
    if (!_timelineController.isAnimating) {
      _timelineController.forward();
    }
    return completed.future;
  }

  Future<void> _startStartupFlow() async {
    if (_checkInProgress || _hasNavigated) {
      return;
    }

    _checkInProgress = true;
    final attempt = ++_attempt;

    if (mounted) {
      setState(() {
        _connectionState = _SplashConnectionState.checking;
      });
    }

    if (_timelineController.isCompleted && _motionDisabled != true) {
      _timelineController
        ..value = 0
        ..forward();
    }
    final connectivityFuture = _connectivityService.hasConnection();

    final isOnline = await connectivityFuture;
    if (!mounted || attempt != _attempt) {
      return;
    }

    // 2. Handle offline condition
    if (!isOnline) {
      await _waitForTimeline();
      if (!mounted || attempt != _attempt || _hasNavigated) return;
      _checkInProgress = false;
      setState(() {
        _connectionState = _SplashConnectionState.offline;
      });
      return;
    }

    await _waitForTimeline();
    if (!mounted || attempt != _attempt || _hasNavigated) return;

    try {
      final startupHandler = widget.onStartupComplete;
      final didRestoreSession = startupHandler == null
          ? false
          : await startupHandler(context);
      if (!mounted || attempt != _attempt || _hasNavigated) return;
      _checkInProgress = false;
      _hasNavigated = true;
      if (!didRestoreSession) _navigateToLanding();
    } on AuthIntegrationException {
      _showStartupError(attempt);
    } on DevInsightApiException {
      _showStartupError(attempt);
    }
  }

  void _showStartupError(int attempt) {
    if (!mounted || attempt != _attempt) return;
    _checkInProgress = false;
    setState(() {
      _connectionState = _SplashConnectionState.startupError;
    });
  }

  void _navigateToLanding() {
    final reducedMotion = _motionDisabled ?? false;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/landing'),
        transitionDuration: Duration(milliseconds: reducedMotion ? 180 : 550),
        pageBuilder: (context, animation, secondaryAnimation) {
          final app = context.findAncestorWidgetOfExactType<MaterialApp>();
          final builder = app?.routes?['/landing'];
          if (builder != null) {
            return builder(context);
          }
          return const SizedBox.shrink();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final progress = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: progress,
            child: reducedMotion
                ? child
                : SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.012),
                      end: Offset.zero,
                    ).animate(progress),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.992,
                        end: 1,
                      ).animate(progress),
                      child: child,
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _retryConnection() {
    if (_checkInProgress) return;
    _startStartupFlow();
  }

  Widget _buildErrorView() {
    final startupError =
        _connectionState == _SplashConnectionState.startupError;
    return Semantics(
      liveRegion: true,
      child: Column(
        key: ValueKey(startupError ? 'startup_error_view' : 'offline_view'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            startupError
                ? 'Could not restore your session'
                : 'Check your internet connection',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF14243D),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              startupError
                  ? 'DevInsight could not load your account. Check your connection and retry.'
                  : 'No connection detected. Please verify your network and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF65758E),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _checkInProgress ? null : _retryConnection,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryAnimation = ModalRoute.of(context)?.secondaryAnimation;
    final splashPage = Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: SplashEcosystemView(
                    key: const ValueKey('splash-ecosystem'),
                    animation: _visualTimeline,
                    reducedMotion: _motionDisabled ?? false,
                  ),
                ),
                if (_connectionState != _SplashConnectionState.checking)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: math.max(24, constraints.maxHeight * 0.06),
                    child: Center(child: _buildErrorView()),
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (secondaryAnimation == null) return splashPage;

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOutCubic,
        ),
      ),
      child: splashPage,
    );
  }
}
