import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dashboard/app/app.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/connectivity_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/theme_controller.dart';
import 'package:web_dashboard/features/auth/presentation/pages/auth_destination_page.dart';
import 'package:web_dashboard/features/manager/presentation/pages/manager_home_page.dart';
import 'package:web_dashboard/features/onboarding/presentation/pages/onboarding_flow_page.dart';

class _OnlineConnectivityService extends ConnectivityService {
  const _OnlineConnectivityService();

  @override
  Future<bool> hasConnection() async => true;
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.restore, {this.sessionAvailable = true}) : super();

  final Future<CurrentUserProfile?> Function() restore;
  final bool sessionAvailable;
  int restoreCalls = 0;

  @override
  bool get hasSession => sessionAvailable;

  @override
  Future<CurrentUserProfile?> restoreProfile() {
    restoreCalls += 1;
    return restore();
  }
}

void main() {
  Future<void> startApp(
    WidgetTester tester,
    _FakeAuthService authService, {
    String? initialRoute,
  }) async {
    tester.view.physicalSize = const Size(2600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      App(
        themeController: ThemeController(),
        authService: authService,
        connectivityService: const _OnlineConnectivityService(),
        initialRoute: initialRoute,
        landingPageBuilder: (_) => const Scaffold(body: Text('Public Landing')),
      ),
    );
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('restores a completed Developer from the authenticated route', (
    tester,
  ) async {
    final auth = _FakeAuthService(
      () async => const CurrentUserProfile(
        id: 'developer-id',
        nextStep: 'developer_home',
        role: 'developer',
        onboardingCompleted: true,
      ),
    );

    await startApp(tester, auth, initialRoute: '/auth');

    expect(auth.restoreCalls, 1);
    expect(find.text('Welcome back, Developer 👋'), findsOneWidget);
  });

  testWidgets(
    'restores a session even when refresh starts at the old login URL',
    (tester) async {
      final auth = _FakeAuthService(
        () async => const CurrentUserProfile(
          id: 'developer-id',
          nextStep: 'developer_home',
          role: 'developer',
          onboardingCompleted: true,
        ),
      );

      await startApp(tester, auth, initialRoute: '/login');

      expect(auth.restoreCalls, 1);
      expect(find.text('Welcome back, Developer 👋'), findsOneWidget);
    },
  );

  testWidgets(
    'restores a completed Project Manager from the authenticated route',
    (tester) async {
      final auth = _FakeAuthService(
        () async => const CurrentUserProfile(
          id: 'manager-id',
          nextStep: 'manager_home',
          role: 'project_manager',
          onboardingCompleted: true,
        ),
      );

      await startApp(tester, auth, initialRoute: '/auth');

      expect(auth.restoreCalls, 1);
      expect(find.byType(ManagerHomePage), findsOneWidget);
      expect(find.text('Project clarity starts here.'), findsOneWidget);
    },
  );

  testWidgets('restores an incomplete user to the saved onboarding step', (
    tester,
  ) async {
    final auth = _FakeAuthService(
      () async => const CurrentUserProfile(
        id: 'incomplete-id',
        nextStep: 'preferences',
        role: 'developer',
      ),
    );

    await startApp(tester, auth, initialRoute: '/auth');

    expect(auth.restoreCalls, 1);
    expect(find.byType(OnboardingFlowPage), findsOneWidget);
    expect(find.text('Make DevInsight Work for You'), findsOneWidget);
  });

  testWidgets('signed-out user follows the Splash-to-Landing flow', (
    tester,
  ) async {
    final auth = _FakeAuthService(() async => null, sessionAvailable: false);

    await startApp(tester, auth, initialRoute: '/auth');

    expect(auth.restoreCalls, 1);
    expect(find.text('Public Landing'), findsOneWidget);
    expect(find.byType(AuthDestinationPage), findsNothing);
  });

  testWidgets('expired session follows the signed-out startup flow', (
    tester,
  ) async {
    final auth = _FakeAuthService(
      () async => throw const AuthIntegrationException(
        'Your session has expired. Please sign in again.',
      ),
      sessionAvailable: false,
    );

    await startApp(tester, auth, initialRoute: '/auth');

    expect(auth.restoreCalls, 1);
    expect(find.text('Public Landing'), findsOneWidget);
  });

  testWidgets('temporary API failure stays in a retryable startup error', (
    tester,
  ) async {
    final auth = _FakeAuthService(
      () async => throw const AuthIntegrationException(
        'Could not connect to DevInsight. Check the connection and try again.',
      ),
    );

    await startApp(tester, auth, initialRoute: '/auth');

    expect(auth.restoreCalls, 1);
    expect(find.text('Could not restore your session'), findsOneWidget);
    expect(find.text('AI-Powered Project Intelligence'), findsNothing);
  });

  testWidgets('startup performs one restore and one authenticated navigation', (
    tester,
  ) async {
    final auth = _FakeAuthService(
      () async => const CurrentUserProfile(
        id: 'developer-id',
        nextStep: 'developer_home',
        role: 'developer',
        onboardingCompleted: true,
      ),
    );

    await startApp(tester, auth, initialRoute: '/auth');
    await tester.pump(const Duration(seconds: 10));

    expect(auth.restoreCalls, 1);
    expect(find.byType(AuthDestinationPage), findsOneWidget);
  });
}
