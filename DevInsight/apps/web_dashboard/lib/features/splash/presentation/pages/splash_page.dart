import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/connectivity_service.dart';
import '../widgets/logo_reveal_view.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_loader.dart';

enum _SplashConnectionState { checking, offline }

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, ConnectivityService? connectivityService})
      : _connectivityService = connectivityService ?? const ConnectivityService();

  final ConnectivityService _connectivityService;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final AnimationController _progressController;
  _SplashConnectionState _connectionState = _SplashConnectionState.checking;
  bool _checkInProgress = false;
  bool _hasNavigated = false;
  int _attempt = 0;

  ConnectivityService get _connectivityService => widget._connectivityService;

  @override
  void initState() {
    super.initState();
    // 3.2s reveal timeline:
    // - 0.0-1.5s: Logo radial reveal & light sweep
    // - 1.2-3.0s: DevInsight character typing
    // - 2.4-3.0s: Subtitle entrance
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Exact 6-second progress controller for the loading bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _revealController.forward();
    _startStartupFlow();
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

    _progressController
      ..stop()
      ..value = 0.0;

    if (!_revealController.isAnimating && _revealController.value < 1.0) {
      _revealController.forward();
    }

    // 1. Kick off 6-second linear progress and connectivity check concurrently
    final progressFuture = _progressController.forward();
    final connectivityFuture = _connectivityService.hasConnection();

    final isOnline = await connectivityFuture;

    if (!mounted || attempt != _attempt) {
      return;
    }

    // 2. Handle offline condition
    if (!isOnline) {
      _progressController.stop();
      _checkInProgress = false;
      setState(() {
        _connectionState = _SplashConnectionState.offline;
      });
      return;
    }

    // 3. Await progress bar filling completely to 100% (6.0 seconds)
    await progressFuture;

    if (!mounted || attempt != _attempt) {
      return;
    }

    // 4. Exact 1.0-second completion hold (Total successful splash = 7.0 seconds)
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted || attempt != _attempt || _hasNavigated) {
      return;
    }

    _checkInProgress = false;
    _hasNavigated = true;
    _navigateToLanding();
  }

  void _navigateToLanding() {
    // Smooth fade navigation to the existing Landing Page
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/landing'),
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) {
          final app = context.findAncestorWidgetOfExactType<MaterialApp>();
          final builder = app?.routes?['/landing'];
          if (builder != null) {
            return builder(context);
          }
          return const SizedBox.shrink();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _retryConnection() {
    if (_checkInProgress) return;
    _startStartupFlow();
  }

  Widget _buildLoadingArea({
    required bool isMobile,
    required bool isTablet,
  }) {
    if (_connectionState == _SplashConnectionState.offline) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: const ValueKey('offline_view'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.darkBlueNavy.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.azureBlue.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.softBlueHighlight,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Check your internet connection',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.softLavender,
                fontSize: isMobile ? 15.0 : 16.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'No connection detected. Please verify your network and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.softLavender.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _checkInProgress ? null : _retryConnection,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final loaderWidth = isMobile
        ? 220.0
        : isTablet
            ? 250.0
            : 290.0;

    final loaderHeight = isMobile ? 6.0 : 7.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, _) {
          final progress = _progressController.value;
          // Animated ellipsis: . -> .. -> ...
          final dotCycle = (progress * 12).floor() % 3;
          final dots = dotCycle == 0
              ? '.'
              : dotCycle == 1
                  ? '..'
                  : '...';

          return Column(
            key: const ValueKey('checking_view'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SplashLoader(
                progress: progress,
                width: loaderWidth,
                height: loaderHeight,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Loading',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.softLavender.withValues(alpha: 0.88),
                      fontSize: isMobile ? 13.0 : 14.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    child: Text(
                      dots,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.softLavender.withValues(alpha: 0.88),
                        fontSize: isMobile ? 13.0 : 14.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlack,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 1024;

          return SplashBackground(
            isAnimating: _connectionState == _SplashConnectionState.checking,
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: LogoRevealView(
                  revealController: _revealController,
                  isCompact: isMobile,
                  loadingArea: _buildLoadingArea(
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
