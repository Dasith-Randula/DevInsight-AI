import 'package:flutter/material.dart';
import 'package:web_dashboard/features/auth/presentation/pages/login_page.dart';
import 'package:web_dashboard/features/auth/presentation/pages/signup_page.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/landing/presentation/pages/landing_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class App extends StatelessWidget {
  const App({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) => AnimatedTheme(
        data: themeController.isDark ? AppTheme.dark : AppTheme.light,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        child: MaterialApp(
          title: 'DevInsight',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          home: const SplashPage(),
          routes: {
            '/landing': (_) => LandingPage(themeController: themeController),
            '/login': (_) => LoginPage(themeController: themeController),
            '/signup': (_) => SignUpPage(themeController: themeController),
          },
        ),
      ),
    );
  }
}
