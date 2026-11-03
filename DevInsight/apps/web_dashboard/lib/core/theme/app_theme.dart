import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.secondaryBlue,
      surface: AppColors.white,
      onSurface: AppColors.darkText,
    ),
    scaffoldBackgroundColor: AppColors.softBlueBg,
    useMaterial3: true,
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF00B4D8),
      surface: Color(0xFF172B49),
      onSurface: Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: const Color(0xFF080F20),
    dividerColor: const Color(0xFF304562),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Color(0xFF15243B),
    ),
    useMaterial3: true,
  );
}
