import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../shared/widgets/liquid_glass_card.dart';
import '../widgets/splash_background.dart';
import '../widgets/logo_reveal_view.dart';
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
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _revealController.forward();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
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
      ..value = 0;
    final progressComplete = _progressController.forward();
    final isOnline = await _connectivityService.hasConnection();

    if (!mounted || attempt != _attempt) {
      return;
    }

    if (!isOnline) {
      _progressController.stop();
      _checkInProgress = false;
      setState(() {
        _connectionState = _SplashConnectionState.offline;
      });
      return;
    }

    await progressComplete;
    if (!mounted || attempt != _attempt) {
      return;
    }

    _checkInProgress = false;
    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed('/landing');
  }

  Widget _buildLoadingArea({required bool isCompact}) {
    if (_connectionState == _SplashConnectionState.offline) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: LiquidGlassCard(
          key: const ValueKey('offline'),
          borderRadius: 16,
          variant: LiquidGlassVariant.strong,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFCA5A5).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Check your internet connection',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  'No internet connection detected. Please reconnect and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.68),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _checkInProgress ? null : _checkConnection,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, _) => Column(
          key: const ValueKey('checking'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SplashLoader(
              progress: _progressController.value,
              width: isCompact ? 180 : 240,
              height: 7,
            ),
            const SizedBox(height: 10),
            Text(
              'Checking connection...',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
                fontSize: isCompact ? 14.0 : 15.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          return CharmingSplashBackground(
            isAnimating: _connectionState == _SplashConnectionState.checking,
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: LogoRevealView(
                  revealController: _revealController,
                  isCompact: isCompact,
                  loadingArea: _buildLoadingArea(isCompact: isCompact),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
