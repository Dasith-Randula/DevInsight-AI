import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = controller.isDark;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: IconButton(
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        onPressed: controller.toggle,
        style: IconButton.styleFrom(
          backgroundColor: colors.surface.withValues(
            alpha: isDark ? 0.72 : 0.78,
          ),
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween<double>(begin: -0.15, end: 0).animate(animation),
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
          ),
        ),
      ),
    );
  }
}
