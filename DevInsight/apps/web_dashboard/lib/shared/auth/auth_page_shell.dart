import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_controller.dart';
import '../backgrounds/animated_aura_background.dart';
import '../widgets/theme_toggle_button.dart';

/// Full-page shell for authentication screens.
///
/// Provides:
/// - [AnimatedAuraBackground] (auth variant) behind everything.
/// - Page-enter animation: 600ms fade + 16px upward slide (easeOutCubic).
/// - Home/back button in the top-left corner.
///
/// The [child] (auth card) is rendered on top of the background.
/// [onNavigateHome] wires the back-button tap to the page's navigator call.
class AuthPageShell extends StatefulWidget {
  final Widget child;
  final VoidCallback onNavigateHome;
  final ThemeController? themeController;

  const AuthPageShell({
    super.key,
    required this.child,
    required this.onNavigateHome,
    this.themeController,
  });

  @override
  State<AuthPageShell> createState() => _AuthPageShellState();
}

class _AuthPageShellState extends State<AuthPageShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.025), // ~16px at typical auth card height
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    // Slight delay so the background is visible first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enterCtrl.forward();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Aura background (auth variant — very low intensity blue only)
          const AnimatedAuraBackground(variant: AuraBackgroundVariant.auth),

          // 2. Scrollable auth content with page-enter animation
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 40,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),

          // 3. Home / back button pinned top-left
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 16),
                child: _HomeButton(onTap: widget.onNavigateHome),
              ),
            ),
          ),
          if (widget.themeController != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 16),
                  child: ThemeToggleButton(controller: widget.themeController!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HomeButton({required this.onTap});

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: _hovered
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.68),
              ),
              const SizedBox(width: 6),
              Text(
                'Home',
                style: GoogleFonts.plusJakartaSans(
                  color: _hovered
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
