import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final isDark = controller.isDark;
      const height = 34.0;
      const thumbSize = 27.0;

      return Semantics(
        button: true,
        label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        child: Tooltip(
          message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: GestureDetector(
            onTap: controller.toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: 70,
              height: height,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFD8D8D8),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: isDark
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: SizedBox(
                      width: thumbSize,
                      height: thumbSize,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
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
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFE8A900),
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    alignment: isDark
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: isDark
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: SizedBox(
                      width: thumbSize,
                      height: thumbSize,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                          child: isDark
                              ? const _MoonAndStars(key: ValueKey(true))
                              : const SizedBox(
                                  key: ValueKey(false),
                                  width: 20,
                                  height: 20,
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
    },
  );
}

class _MoonAndStars extends StatelessWidget {
  const _MoonAndStars({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 1,
          top: 3,
          child: Icon(Icons.nightlight_round, size: 15, color: Colors.white),
        ),
        Positioned(
          right: 0,
          top: 2,
          child: Icon(Icons.star_rounded, size: 6, color: Colors.white),
        ),
        Positioned(
          right: 2,
          bottom: 3,
          child: Icon(Icons.star_rounded, size: 4, color: Colors.white),
        ),
      ],
    ),
  );
}
