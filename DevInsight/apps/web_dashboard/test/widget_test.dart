import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dashboard/core/services/connectivity_service.dart';
import 'package:web_dashboard/features/splash/presentation/pages/splash_page.dart';

class FakeConnectivityService extends ConnectivityService {
  const FakeConnectivityService(this._isOnline);

  final bool _isOnline;

  @override
  Future<bool> hasConnection() async => _isOnline;
}

void main() {
  testWidgets('Splash app loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/landing': (_) => const Scaffold(body: Text('Landing page')),
        },
        home: const SplashPage(
          connectivityService: FakeConnectivityService(true),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();

    expect(find.text('Landing page'), findsOneWidget);
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
