import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum LiquidGlassVariant { subtle, standard, strong }

class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 20,
    this.variant = LiquidGlassVariant.standard,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final LiquidGlassVariant variant;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = switch (variant) {
      LiquidGlassVariant.subtle => isDark ? 0.42 : 0.40,
      LiquidGlassVariant.standard => isDark ? 0.56 : 0.52,
      LiquidGlassVariant.strong => isDark ? 0.72 : 0.64,
    };
    final blur = switch (variant) {
      LiquidGlassVariant.subtle => 10.0,
      LiquidGlassVariant.standard => 13.0,
      LiquidGlassVariant.strong => 16.0,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? const Color(0xFF29466C) : Colors.white).withValues(
                  alpha: opacity + 0.08,
                ),
                (isDark ? const Color(0xFF172B49) : const Color(0xFFF5FAFF))
                    .withValues(alpha: opacity),
                (isDark ? const Color(0xFF10213A) : const Color(0xFFDCEEFF))
                    .withValues(alpha: opacity - 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: (isDark ? const Color(0xFF7DD3FC) : Colors.white)
                  .withValues(alpha: isDark ? 0.28 : 0.82),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF0664F2) : AppColors.primaryBlue)
                        .withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF0F172A))
                    .withValues(alpha: isDark ? 0.16 : 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
