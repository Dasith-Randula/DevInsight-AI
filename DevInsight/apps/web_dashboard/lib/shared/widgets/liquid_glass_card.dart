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
    final opacity = switch (variant) {
      LiquidGlassVariant.subtle => 0.40,
      LiquidGlassVariant.standard => 0.52,
      LiquidGlassVariant.strong => 0.64,
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
                Colors.white.withValues(alpha: opacity + 0.10),
                const Color(0xFFF5FAFF).withValues(alpha: opacity),
                const Color(0xFFDCEEFF).withValues(alpha: opacity - 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.035),
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
