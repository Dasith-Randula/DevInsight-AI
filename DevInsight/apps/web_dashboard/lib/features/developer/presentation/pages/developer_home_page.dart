import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/constants/app_assets.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';

class DeveloperHomePage extends StatefulWidget {
  const DeveloperHomePage({super.key, required this.profile});

  final CurrentUserProfile profile;

  @override
  State<DeveloperHomePage> createState() => _DeveloperHomePageState();
}

class _DeveloperHomePageState extends State<DeveloperHomePage>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _nextSectionKey = GlobalKey();
  late final AnimationController _ambientMotionController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  bool? _motionDisabled;

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
  });

  final ScrollController scrollController;
  final GlobalKey nextSectionKey;
  final Animation<double> ambientMotion;
  final String firstName;
  final String role;
  final ValueChanged<String> onAction;

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
              child: _MetricGrid(key: nextSectionKey, width: width),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _ResponsivePair(
                breakpoint: 820,
                children: const [
                  _ChartPanel(
                    title: 'Weekly Productivity',
                    subtitle: 'Commits, merged PRs, and issue resolutions.',
                    icon: Icons.insights_rounded,
                  ),
                  _ChartPanel(
                    title: 'Project Risk Trend',
                    subtitle:
                        'Overall project risk across code, issues, and delivery.',
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
                  const _ContributionPanel(),
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
                children: const [_ProjectHealthPanel(), _QualityMetricsPanel()],
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              controller: scrollController,
              child: _ResponsivePair(
                breakpoint: 820,
                children: [
                  _ActivityPanel(onAction: onAction),
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
  });

  final String firstName;
  final String role;
  final bool compact;
  final Animation<double> ambientMotion;
  final ValueChanged<String> onAction;

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
              Row(
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
              const SizedBox(height: 8),
              Text(
                'No project connected',
                style: _textStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                'Connect a GitHub repository to start collecting project intelligence.',
                style: _textStyle(
                  color: const Color(0xFF687A96),
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () =>
                    onAction('Repository connection is coming soon.'),
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({super.key, required this.width});

  final double width;

  static const _metrics = [
    (
      'Assigned Issues',
      Icons.code_rounded,
      Color(0xFF2878F0),
      Color(0xFFEAF2FF),
    ),
    (
      'Resolved Issues',
      Icons.check_circle_outline_rounded,
      Color(0xFF12A878),
      Color(0xFFE7F8F1),
    ),
    (
      'Productivity Score',
      Icons.bolt_rounded,
      Color(0xFF1989E8),
      Color(0xFFE8F5FF),
    ),
    (
      'Open Pull Requests',
      Icons.merge_rounded,
      Color(0xFF795BF5),
      Color(0xFFF0ECFF),
    ),
    (
      'Code Quality',
      Icons.shield_outlined,
      Color(0xFF2C72D5),
      Color(0xFFEAF2FF),
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
              title: metric.$1,
              icon: metric.$2,
              accent: metric.$3,
              tint: metric.$4,
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
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color tint;

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
              style: _textStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'No data yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      color: const Color(0xFF72819A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.info_outline_rounded, size: 13, color: accent),
              ],
            ),
            Text(
              'Connect a repository to view',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(color: const Color(0xFF8A96AA), fontSize: 8),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: 14),
          Container(
            height: 176,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAF0FA)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _ChartGridPainter()),
                ),
                const Center(
                  child: _EmptyState(
                    icon: Icons.show_chart_rounded,
                    title: 'Chart data will appear here',
                    detail: 'Connect a repository to start tracking trends.',
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
  const _ContributionPanel();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Code Contribution',
            subtitle: 'Your activity across connected repositories.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 194,
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                        'Connect a repository to view contribution data.',
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
      'Risk Alert',
      'Risk indicators will appear when project data is available.',
      Icons.warning_amber_rounded,
      Color(0xFFCC5656),
      Color(0xFFFFF1F1),
      'Review Changes',
    ),
    (
      'Prioritize Issue',
      'Issue priority recommendations need connected project issues.',
      Icons.lightbulb_outline_rounded,
      Color(0xFF2876D8),
      Color(0xFFEEF6FF),
      'Update Priority',
    ),
    (
      'Root Cause Hint',
      'Root-cause analysis will be available after data sync.',
      Icons.account_tree_outlined,
      Color(0xFF755BDD),
      Color(0xFFF3F0FF),
      'View Analysis',
    ),
    (
      'Workload Balance',
      'Workload recommendations need current team activity.',
      Icons.auto_awesome_rounded,
      Color(0xFF148EAD),
      Color(0xFFEBFAFC),
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
                'Recommendations to help you deliver faster and with lower risk.',
            icon: Icons.auto_awesome_rounded,
            actionLabel: 'View all insights',
            onAction: () => onAction(
              'AI insights are unavailable until project data is connected.',
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
                        action: item.$6,
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
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final Color tint;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      child: Container(
        constraints: const BoxConstraints.tightFor(height: 150),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.48),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(13),
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
                      fontSize: 10,
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
                fontSize: 9,
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
                textStyle: _textStyle(fontSize: 9, fontWeight: FontWeight.w800),
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
  const _ProjectHealthPanel();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Project Health',
            subtitle: 'High-level project health for your active projects.',
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
            child: const Center(
              child: _EmptyState(
                icon: Icons.folder_open_rounded,
                title: 'No project health data',
                detail:
                    'Connect a repository to track project quality and delivery.',
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityMetricsPanel extends StatelessWidget {
  const _QualityMetricsPanel();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Quality Metrics',
            subtitle: 'Quality signals from your connected codebase.',
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
            child: const Center(
              child: _EmptyState(
                icon: Icons.shield_outlined,
                title: 'Metrics are not available yet',
                detail:
                    'Test coverage, code smells, and security findings will appear here.',
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Team Activity',
            subtitle: 'Recent updates from your team and projects.',
            icon: Icons.people_outline_rounded,
            actionLabel: 'View all activity',
            onAction: () => onAction('Team activity is not available yet.'),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 148,
            child: Center(
              child: _EmptyState(
                icon: Icons.forum_outlined,
                title: 'No recent activity',
                detail:
                    'Team updates will appear when your project is connected.',
                compact: true,
              ),
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
                        fontSize: 14,
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
                style: _textStyle(color: const Color(0xFF73829A), fontSize: 9),
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
              textStyle: _textStyle(fontSize: 9, fontWeight: FontWeight.w800),
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
