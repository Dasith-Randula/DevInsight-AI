import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:web_dashboard/core/theme/theme_controller.dart';
import 'package:web_dashboard/shared/widgets/theme_toggle_button.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 480),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [
                  Color(0xFF080D19),
                  Color(0xFF0B1830),
                  Color(0xFF102B4B),
                  Color(0xFF0B1426),
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7FAFF),
                  Color(0xFFEEF5FF),
                  Color(0xFFF9FBFF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.32, 0.72, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BlueDotPainter(animation: animation),
                size: Size.infinite,
              ),
            ),
          ),
          child,
        ],
      ),
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
      glowPaint.shader = const RadialGradient(
        colors: [Color(0x183B82F6), Color(0x0C38A5E8), Color(0x003B82F6)],
        stops: [0, 0.52, 1],
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

class DashboardNavigationItem<T> {
  const DashboardNavigationItem({
    required this.value,
    required this.label,
    required this.icon,
    this.key,
  });

  final T value;
  final String label;
  final IconData icon;
  final Key? key;
}

class DashboardNavigation<T> extends StatefulWidget {
  const DashboardNavigation({
    super.key,
    required this.primaryItems,
    required this.workspaceItems,
    required this.activeValue,
    required this.onSelect,
    required this.onHelp,
    this.expanded = false,
  });

  final List<DashboardNavigationItem<T>> primaryItems;
  final List<DashboardNavigationItem<T>> workspaceItems;
  final T activeValue;
  final ValueChanged<T> onSelect;
  final VoidCallback onHelp;
  final bool expanded;

  @override
  State<DashboardNavigation<T>> createState() => _DashboardNavigationState<T>();
}

class _DashboardNavigationState<T> extends State<DashboardNavigation<T>> {
  bool _hovered = false;
  bool _showLabels = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final expanded = widget.expanded || _hovered;
    final showLabels = widget.expanded || _showLabels;
    return MouseRegion(
      onEnter: widget.expanded
          ? null
          : (_) => setState(() {
              _hovered = true;
              _showLabels = false;
            }),
      onExit: widget.expanded
          ? null
          : (_) => setState(() {
              _hovered = false;
              _showLabels = false;
            }),
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
              if (_hovered && !_showLabels) {
                setState(() => _showLabels = true);
              }
            },
            width: widget.expanded
                ? double.infinity
                : expanded
                ? 224
                : 76,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: colors.sidebar.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.96
                    : 0.58,
              ),
              border: Border(
                right: BorderSide(color: colors.border.withValues(alpha: 0.78)),
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
                      for (final item in widget.primaryItems)
                        _NavigationItem<T>(
                          item: item,
                          active: item.value == widget.activeValue,
                          expanded: showLabels,
                          onTap: () => widget.onSelect(item.value),
                        ),
                      if (widget.workspaceItems.isNotEmpty)
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
                                  style: _dashboardTextStyle(
                                    color: const Color(0xFF8290A8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                )
                              : Divider(color: colors.divider, height: 12),
                        ),
                      for (final item in widget.workspaceItems)
                        _NavigationItem<T>(
                          item: item,
                          active: item.value == widget.activeValue,
                          expanded: showLabels,
                          onTap: () => widget.onSelect(item.value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Need Help?',
                  child: Material(
                    color: colors.surfaceSecondary,
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
                            Icon(
                              Icons.help_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 19,
                            ),
                            if (showLabels) ...[
                              const SizedBox(width: 10),
                              Text(
                                'Need Help?',
                                style: _dashboardTextStyle(
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

class _NavigationItem<T> extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.active,
    required this.expanded,
    required this.onTap,
  });

  final DashboardNavigationItem<T> item;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final color = active
        ? Theme.of(context).colorScheme.primary
        : colors.mutedText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Tooltip(
        key:
            item.key ??
            ValueKey(
              'sidebar-${item.label.toLowerCase().replaceAll(' ', '-')}',
            ),
        message: expanded ? '' : item.label,
        child: Material(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .14)
              : Colors.transparent,
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
                    child: Icon(item.icon, size: 18, color: color),
                  ),
                  if (expanded)
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _dashboardTextStyle(
                          color: active ? colors.primaryText : color,
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

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.name,
    required this.role,
    required this.scrollController,
    required this.onMenu,
    required this.onProfile,
    required this.onAction,
    required this.onSettings,
  });

  final String name;
  final String role;
  final ScrollController scrollController;
  final VoidCallback? onMenu;
  final VoidCallback onProfile;
  final ValueChanged<String> onAction;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final themeController = ThemeControllerScope.maybeOf(context);
    final compact = MediaQuery.sizeOf(context).width < 700;
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
                color: colors.topbar.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.96 - scrolled * 0.14
                      : 0.93 - scrolled * 0.39,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colors.border.withValues(
                      alpha: 0.82 - scrolled * 0.24,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (onMenu != null)
                    IconButton(
                      key: const ValueKey('dashboard-open-navigation'),
                      onPressed: onMenu,
                      tooltip: 'Open navigation',
                      icon: const Icon(Icons.menu_rounded),
                      color: colors.secondaryText,
                    ),
                  if (!compact)
                    OutlinedButton.icon(
                      onPressed: () =>
                          onAction('Workspace switching is coming soon.'),
                      icon: const Icon(Icons.code_rounded, size: 15),
                      label: const Text('My Workspace'),
                      iconAlignment: IconAlignment.start,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        textStyle: _dashboardTextStyle(
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
                                          style: _dashboardTextStyle(
                                            color: const Color(0xFF7E8CA4),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                              filled: true,
                              fillColor: colors.surfaceSecondary,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: BorderSide(color: colors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: BorderSide(color: colors.border),
                              ),
                            ),
                            style: _dashboardTextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!compact) const SizedBox(width: 16),
                  if (!compact && themeController != null) ...[
                    ThemeToggleButton(controller: themeController),
                    const SizedBox(width: 8),
                  ],
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
                      onPressed: onSettings,
                    ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: onProfile,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      foregroundColor: colors.primaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        DashboardAvatar(name: name, size: 31),
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
                                  style: _dashboardTextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _dashboardTextStyle(
                                    color: colors.mutedText,
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
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: 19),
    color: const Color(0xFF4A5D7A),
    visualDensity: VisualDensity.compact,
  );
}

class DashboardAvatar extends StatelessWidget {
  const DashboardAvatar({super.key, required this.name, required this.size});

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
        style: _dashboardTextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class DashboardGlassSurface extends StatelessWidget {
  const DashboardGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 20,
    this.blur = 12,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: dark ? .86 : .74),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: colors.border.withValues(alpha: dark ? .82 : .72),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: dark ? .45 : .7),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

Future<T?> showDashboardGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required String barrierLabel,
}) {
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: .18),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) => Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: reduceMotion ? 0 : 7,
              sigmaY: reduceMotion ? 0 : 7,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Center(
          child: SafeArea(
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  Navigator.of(dialogContext).pop();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: builder(dialogContext),
            ),
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
            begin: const Offset(0, .02),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: .97, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

TextStyle _dashboardTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
}) => GoogleFonts.plusJakartaSans(
  color: color,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  letterSpacing: letterSpacing,
);
