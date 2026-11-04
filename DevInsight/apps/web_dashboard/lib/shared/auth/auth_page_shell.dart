import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AuthPageShell extends StatefulWidget {
  const AuthPageShell({super.key, required this.child});

  final Widget child;

  @override
  State<AuthPageShell> createState() => _AuthPageShellState();
}

class _AuthPageShellState extends State<AuthPageShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _fade = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enterController.forward();
    });
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light.copyWith(
        scaffoldBackgroundColor: AppColors.authBackground,
        colorScheme: AppTheme.light.colorScheme.copyWith(
          primary: AppColors.authRoyalBlue,
          secondary: AppColors.authAzureBlue,
          surface: Colors.white,
          onSurface: AppColors.authText,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.authBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.authBackground,
                    AppColors.softLavender,
                  ],
                ),
              ),
            ),
            const Positioned(
              top: -180,
              left: -100,
              child: _PageGlow(size: 500, opacity: 0.32),
            ),
            const Positioned(
              right: -180,
              bottom: -240,
              child: _PageGlow(size: 600, opacity: 0.22),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final verticalPadding = isMobile ? 20.0 : 32.0;
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 32,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - verticalPadding * 2)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                      ),
                      child: Center(
                        child: FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
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

class _PageGlow extends StatelessWidget {
  const _PageGlow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.authAzureBlue.withValues(alpha: opacity),
                AppColors.softLavender.withValues(alpha: opacity * 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
