import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dashboard/core/services/connectivity_service.dart';
import 'package:web_dashboard/features/landing/presentation/widgets/landing_hero.dart';
import 'package:web_dashboard/features/splash/presentation/pages/splash_page.dart';

class FakeConnectivityService extends ConnectivityService {
  const FakeConnectivityService(this._isOnline);

  final bool _isOnline;

  @override
  Future<bool> hasConnection() async => _isOnline;
}

class RecordingNavigatorObserver extends NavigatorObserver {
  final routeNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routeNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) routeNames.add(newRoute.settings.name);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

void main() {
  testWidgets('Splash app loads without crashing', (WidgetTester tester) async {
    final navigatorObserver = RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [navigatorObserver],
        routes: {
          '/landing': (_) =>
              const Scaffold(body: Text('AI-Powered Project Intelligence')),
        },
        home: const SplashPage(
          connectivityService: FakeConnectivityService(true),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('AI-Powered Project Intelligence'), findsOneWidget);
    expect(navigatorObserver.routeNames, contains('/landing'));
  });

  testWidgets('Landing page displays its current hero heading', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            child: LandingHero(
              height: 900,
              onGetStarted: _noop,
              onSignIn: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('AI-Powered Project Intelligence'), findsOneWidget);
  });

  testWidgets(
    'Splash page shows an offline state when there is no connection',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/landing': (_) => const Scaffold(body: Text('Landing page')),
          },
          home: const SplashPage(
            connectivityService: FakeConnectivityService(false),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 6700));
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets('splash holds the logo until startup restoration completes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final restoration = Completer<bool>();
    var restorationStarted = false;
    await tester.pumpWidget(
      MaterialApp(
        routes: {'/landing': (_) => const Scaffold(body: Text('Landing page'))},
        home: SplashPage(
          connectivityService: const FakeConnectivityService(true),
          onStartupComplete: (_) {
            restorationStarted = true;
            return restoration.future;
          },
        ),
      ),
    );

    await tester.pump();
    expect(find.byKey(const ValueKey('splash-orbit-scene')), findsOneWidget);
    expect(find.text('Loading'), findsNothing);
    expect(find.byKey(const ValueKey('checking_view')), findsNothing);

    await tester.pump(const Duration(milliseconds: 6700));
    await tester.pump();
    expect(find.text('Landing page'), findsNothing);
    expect(find.byKey(const ValueKey('splash-orbit-scene')), findsOneWidget);
    expect(find.text('DevInsight'), findsNothing);
    expect(restorationStarted, isTrue);
    final finalLogoSize = tester.getSize(
      find.byKey(const ValueKey('splash-final-logo')),
    );
    expect(finalLogoSize.width, closeTo(58 * 1.7, 0.1));
    expect(finalLogoSize.height, closeTo(finalLogoSize.width, 0.01));

    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.getSize(find.byKey(const ValueKey('splash-final-logo'))).width,
      closeTo(finalLogoSize.width, 0.1),
      reason: 'enlarged logo remains steady while restoration is pending',
    );

    restoration.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Landing page'), findsOneWidget);
  });

  testWidgets('splash uses a logo-only state with reduced motion', (
    tester,
  ) async {
    final restoration = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SplashPage(
            connectivityService: const FakeConnectivityService(true),
            onStartupComplete: (_) => restoration.future,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-orbit-scene')), findsNothing);
    expect(tester.takeException(), isNull);
    restoration.complete(true);
    await tester.pump();
  });
}

void _noop() {}
