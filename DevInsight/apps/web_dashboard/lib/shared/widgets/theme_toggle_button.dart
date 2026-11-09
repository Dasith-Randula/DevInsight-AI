import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final isDark = controller.isDark;
      final colors = context.appTheme;
      const height = 28.0;
      const thumbSize = 20.0;

      return Semantics(
        button: true,
        label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        child: Tooltip(
          message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: FocusableActionDetector(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  controller.toggle();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              onTap: controller.toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: 56,
                height: height,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceSecondary
                      : const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF4B8DFF)
                        : const Color(0xFFB7D2F5),
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: isDark
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF9FC7F7) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0xFF4B8DFF).withValues(alpha: .32)
                              : Colors.black.withValues(alpha: .12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          key: ValueKey(isDark),
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0056FF),
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
