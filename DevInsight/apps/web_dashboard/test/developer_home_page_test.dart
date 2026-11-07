import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/pages/developer_home_page.dart';

void main() {
  const profile = CurrentUserProfile(
    id: 'developer-id',
    nextStep: 'developer_home',
    fullName: 'Dasith Randula',
    email: 'dasith@example.com',
    role: 'developer',
    onboardingCompleted: true,
  );

  testWidgets('renders the authenticated name and truthful dashboard states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);

    expect(find.text('DEV'), findsOneWidget);
    expect(
      find.text('AI-Powered Software Engineering Intelligence'),
      findsOneWidget,
    );
    expect(
      find.text('Smarter development. Clearer insights. Better decisions.'),
      findsOneWidget,
    );
    expect(find.text('Developer Home'), findsNothing);
    expect(find.text('Welcome back, Dasith 👋'), findsOneWidget);
    expect(find.text('No project connected'), findsOneWidget);
    expect(find.text('Weekly Productivity'), findsOneWidget);
    expect(find.text('Project Risk Trend'), findsOneWidget);
    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('Code Contribution'), findsOneWidget);
    expect(find.text('AI Insights'), findsOneWidget);
    expect(find.text('Project Health'), findsOneWidget);
    expect(find.text('Quality Metrics'), findsOneWidget);
    expect(find.text('No recent activity'), findsOneWidget);
    expect(find.text('Nothing scheduled'), findsOneWidget);
    expect(find.text('devinsight-platform'), findsNothing);
    expect(find.text('87/100'), findsNothing);
  });

  testWidgets('wordmark scales up and stays centered without clipping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);

    final desktopStyle = tester.widget<Text>(find.text('DEV')).style!;
    expect(desktopStyle.fontSize, closeTo(140.8, 0.01));
    final wordmarkRect = tester.getRect(
      find.byKey(const ValueKey('devinsight-wordmark')),
    );
    final contentRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-content')),
    );
    expect(wordmarkRect.center.dx, closeTo(contentRect.center.dx, 1));
    expect(wordmarkRect.left, greaterThanOrEqualTo(contentRect.left));
    expect(wordmarkRect.right, lessThanOrEqualTo(contentRect.right));
    expect(
      tester.getTopLeft(find.text('Assigned Issues')).dy,
      greaterThanOrEqualTo(tester.view.physicalSize.height),
    );
    for (final letter in 'INSIGHT'.split('')) {
      expect(
        find.byKey(ValueKey('wordmark-letter-$letter')),
        findsNWidgets('INSIGHT'.split(letter).length - 1),
      );
    }
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);

    final mobileWordmarkRect = tester.getRect(
      find.byKey(const ValueKey('devinsight-wordmark')),
    );
    final mobileContentRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-content')),
    );
    expect(
      mobileWordmarkRect.width,
      lessThanOrEqualTo(mobileContentRect.width),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll button smoothly reaches the metric section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);

    final button = find.byKey(const ValueKey('scroll-down-button'));
    expect(button, findsOneWidget);
    expect(find.text('Scroll to explore'), findsNothing);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    final metricTop = tester.getTopLeft(find.text('Assigned Issues')).dy;
    expect(metricTop, greaterThanOrEqualTo(78));
    expect(metricTop, lessThan(tester.view.physicalSize.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero intro fits desktop, laptop, and mobile viewports', (
    tester,
  ) async {
    for (final size in [
      const Size(1440, 1000),
      const Size(1366, 768),
      const Size(1024, 768),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(home: DeveloperHomePage(profile: profile)),
      );
      await _pumpDashboard(tester);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
      expect(find.byKey(const ValueKey('scroll-down-button')), findsOneWidget);
      expect(find.text('Welcome back, Dasith 👋'), findsOneWidget);
      if (size.width >= 900) {
        expect(
          tester.getTopLeft(find.text('Assigned Issues')).dy,
          greaterThanOrEqualTo(size.height),
          reason: 'KPI content should follow the desktop hero at $size',
        );
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('profile popup shows the authenticated account and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);
    await tester.tap(find.text('Dasith Randula').first);
    await _pumpDashboard(tester);

    expect(find.text('dasith@example.com'), findsOneWidget);
    expect(find.text('Notification Preferences'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _pumpDashboard(tester);
    expect(find.text('Sign Out'), findsNothing);
  });

  testWidgets('topbar surface becomes more transparent while scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);

    Color topbarColor() {
      final surface = tester.widget<Container>(
        find.byKey(const ValueKey('topbar-surface')),
      );
      return (surface.decoration! as BoxDecoration).color!;
    }

    final initialOpacity = topbarColor().a;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -420),
    );
    await tester.pump();

    expect(topbarColor().a, lessThan(initialOpacity));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar expands on hover and mobile uses a navigation drawer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);
    expect(tester.takeException(), isNull, reason: 'desktop initial layout');

    expect(find.text('Projects'), findsNothing);
    final collapsedLeft = tester
        .getTopLeft(find.byKey(const ValueKey('dashboard-content')))
        .dx;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(38, 110));
    await mouse.moveTo(const Offset(38, 110));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();
    expect(find.text('Projects'), findsOneWidget);
    final expandedLeft = tester
        .getTopLeft(find.byKey(const ValueKey('dashboard-content')))
        .dx;
    expect(expandedLeft, collapsedLeft);
    expect(
      tester.takeException(),
      isNull,
      reason: 'expanded desktop navigation',
    );
    await mouse.moveTo(const Offset(500, 110));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();
    expect(find.text('Projects'), findsNothing);
    expect(
      tester.takeException(),
      isNull,
      reason: 'collapsed desktop navigation',
    );
    await mouse.removePointer();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      const MaterialApp(home: DeveloperHomePage(profile: profile)),
    );
    await _pumpDashboard(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Open navigation'));
    await _pumpDashboard(tester);

    expect(find.text('Projects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDashboard(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
