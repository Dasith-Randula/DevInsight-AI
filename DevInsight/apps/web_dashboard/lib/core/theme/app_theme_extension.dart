import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.pageBackground,
    required this.secondaryBackground,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.sidebar,
    required this.topbar,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.border,
    required this.divider,
    required this.illustrationSurface,
    required this.chartGrid,
    required this.shadow,
  });

  final Color pageBackground;
  final Color secondaryBackground;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color sidebar;
  final Color topbar;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color border;
  final Color divider;
  final Color illustrationSurface;
  final Color chartGrid;
  final Color shadow;

  static const light = AppThemeExtension(
    pageBackground: Color(0xFFF5F9FF),
    secondaryBackground: Color(0xFFEEF5FF),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF7FAFF),
    surfaceElevated: Color(0xFFFFFFFF),
    sidebar: Color(0xFFFFFFFF),
    topbar: Color(0xFFFFFFFF),
    primaryText: Color(0xFF101B33),
    secondaryText: Color(0xFF516180),
    mutedText: Color(0xFF71809A),
    border: Color(0xFFE2EDF8),
    divider: Color(0xFFDCE7F5),
    illustrationSurface: Color(0xFFFFFFFF),
    chartGrid: Color(0xFFDCE7F5),
    shadow: Color(0x160056FF),
  );

  static const dark = AppThemeExtension(
    pageBackground: Color(0xFF080D19),
    secondaryBackground: Color(0xFF0B1426),
    surface: Color(0xFF111C30),
    surfaceSecondary: Color(0xFF17263F),
    surfaceElevated: Color(0xFF1B2C49),
    sidebar: Color(0xFF0B1426),
    topbar: Color(0xCC0D1830),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFB8D4F5),
    mutedText: Color(0xFF91B7E6),
    border: Color(0xFF263955),
    divider: Color(0xFF22324B),
    illustrationSurface: Color(0xFF13213A),
    chartGrid: Color(0xFF263955),
    shadow: Color(0x55000000),
  );

  @override
  AppThemeExtension copyWith({
    Color? pageBackground,
    Color? secondaryBackground,
    Color? surface,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? sidebar,
    Color? topbar,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? border,
    Color? divider,
    Color? illustrationSurface,
    Color? chartGrid,
    Color? shadow,
  }) => AppThemeExtension(
    pageBackground: pageBackground ?? this.pageBackground,
    secondaryBackground: secondaryBackground ?? this.secondaryBackground,
    surface: surface ?? this.surface,
    surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    sidebar: sidebar ?? this.sidebar,
    topbar: topbar ?? this.topbar,
    primaryText: primaryText ?? this.primaryText,
    secondaryText: secondaryText ?? this.secondaryText,
    mutedText: mutedText ?? this.mutedText,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    illustrationSurface: illustrationSurface ?? this.illustrationSurface,
    chartGrid: chartGrid ?? this.chartGrid,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppThemeExtension lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      secondaryBackground: Color.lerp(
        secondaryBackground,
        other.secondaryBackground,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      topbar: Color.lerp(topbar, other.topbar, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      illustrationSurface: Color.lerp(
        illustrationSurface,
        other.illustrationSurface,
        t,
      )!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppThemeExtension.dark
          : AppThemeExtension.light);
}
