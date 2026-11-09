import 'package:flutter/material.dart';
import 'package:web_dashboard/features/auth/presentation/pages/login_page.dart';
import 'package:web_dashboard/features/auth/presentation/pages/signup_page.dart';

import '../core/services/connectivity_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/devinsight_api.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/presentation/auth_navigation.dart';
import '../features/landing/presentation/pages/landing_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.themeController,
    this.authService,
    this.connectivityService,
    this.initialRoute,
    this.landingPageBuilder,
  });

  final ThemeController themeController;
  final AuthService? authService;
  final ConnectivityService? connectivityService;
  final String? initialRoute;
  final WidgetBuilder? landingPageBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) => ThemeControllerScope(
        controller: themeController,
        child: MaterialApp(
          title: 'DevInsight',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          themeAnimationDuration: const Duration(milliseconds: 360),
          themeAnimationCurve: Curves.easeOutCubic,
          initialRoute: initialRoute,
          home: _startupPage(),
          routes: {
            AuthNavigation.authenticatedRoute: (_) => _startupPage(),
            '/landing': (context) =>
                landingPageBuilder?.call(context) ??
                LandingPage(themeController: themeController),
            '/login': (_) =>
                _publicEntryPage(LoginPage(themeController: themeController)),
            '/signup': (_) =>
                _publicEntryPage(SignUpPage(themeController: themeController)),
          },
        ),
      ),
    );
  }

  Widget _publicEntryPage(Widget page) =>
      (authService ?? AuthService()).hasSession ? _startupPage() : page;

  SplashPage _startupPage() => SplashPage(
    connectivityService: connectivityService,
    onStartupComplete: (context) async {
      try {
        final profile = await (authService ?? AuthService()).restoreProfile();
        if (profile == null) return false;
        if (!context.mounted) return false;
        await AuthNavigation.replaceFromProfile(context, profile);
        return true;
      } on AuthIntegrationException catch (error) {
        if (error.message.startsWith('Your session has expired.')) {
          return false;
        }
        rethrow;
      } on DevInsightApiException catch (error) {
        throw AuthIntegrationException(error.message);
      }
    },
  );
}
