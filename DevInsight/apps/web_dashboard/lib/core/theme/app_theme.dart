import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_theme_extension.dart';

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
    extensions: const [AppThemeExtension.light],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.darkText,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.cardBorder),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.focusBorder, width: 1.5),
      ),
    ),
    useMaterial3: true,
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4B8DFF),
      secondary: Color(0xFF24D1F4),
      surface: Color(0xFF111C30),
      onSurface: Color(0xFFF1F6FF),
    ),
    scaffoldBackgroundColor: const Color(0xFF080D19),
    dividerColor: const Color(0xFF22324B),
    cardColor: const Color(0xFF111C30),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF111C30),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFFF1F6FF),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: TextStyle(color: Color(0xFFB6C6DE)),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF17263F),
      textStyle: TextStyle(color: Color(0xFFF1F6FF)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1B2C49),
      contentTextStyle: TextStyle(color: Color(0xFFF1F6FF)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF17263F),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF263955)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF263955)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF4B8DFF), width: 1.5),
      ),
    ),
    extensions: const [AppThemeExtension.dark],
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFB8D4F5)),
      bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
    ),
    useMaterial3: true,
  );
}
