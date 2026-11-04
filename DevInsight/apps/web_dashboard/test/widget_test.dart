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
          '/landing': (_) => const Scaffold(
            body: Text('AI-Powered Project Intelligence'),
          ),
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

  testWidgets('Splash page shows an offline state when there is no connection',
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
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('Check your internet connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

void _noop() {}
