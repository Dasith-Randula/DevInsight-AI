import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/connectivity_service.dart';
import '../widgets/charming_splash_background.dart';
import '../widgets/logo_reveal_view.dart';
import '../widgets/splash_loader.dart';

enum _SplashConnectionState { checking, offline }

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    ConnectivityService? connectivityService,
  }) : _connectivityService = connectivityService ?? const ConnectivityService();

  final ConnectivityService _connectivityService;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  _SplashConnectionState _connectionState = _SplashConnectionState.checking;
  bool _checkInProgress = false;
  bool _hasNavigated = false;

  ConnectivityService get _connectivityService => widget._connectivityService;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _revealController.forward();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (_checkInProgress || _hasNavigated) {
      return;
    }

    _checkInProgress = true;
    if (mounted) {
      setState(() {
        _connectionState = _SplashConnectionState.checking;
      });
    }

    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 2500),
    );
    final isOnline = await _connectivityService.hasConnection();
    await minimumSplash;

    if (!mounted) {
      _checkInProgress = false;
      return;
    }

    if (isOnline) {
      _checkInProgress = false;
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed('/landing');
    } else {
      _checkInProgress = false;
      setState(() {
        _connectionState = _SplashConnectionState.offline;
      });
    }
  }

  Widget _buildLoadingArea({required bool isCompact}) {
    if (_connectionState == _SplashConnectionState.offline) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: const ValueKey('offline'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                  color: const Color(0xFF1E293B),
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
                    color: const Color(0xFF64748B),
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
      child: Container(
        key: const ValueKey('checking'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0664F2).withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SplashLoader(
              size: isCompact ? 28.0 : 32.0,
              strokeWidth: 3.2,
            ),
            const SizedBox(width: 14),
            Text(
              'Checking connection...',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF334155),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
