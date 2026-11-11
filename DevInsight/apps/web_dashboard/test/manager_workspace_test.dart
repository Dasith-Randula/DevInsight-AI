import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/auth/presentation/pages/auth_destination_page.dart';
import 'package:web_dashboard/features/developer/presentation/pages/developer_home_page.dart';
import 'package:web_dashboard/features/manager/presentation/pages/manager_home_page.dart';
import 'package:web_dashboard/features/manager/presentation/routing/manager_destination.dart';
import 'package:web_dashboard/shared/widgets/dashboard_chrome.dart';

void main() {
  const managerProfile = CurrentUserProfile(
    id: 'manager-id',
    nextStep: 'manager_home',
    fullName: 'Morgan Manager',
    email: 'morgan@example.com',
    role: 'Project Manager',
    onboardingCompleted: true,
  );
  const developerProfile = CurrentUserProfile(
    id: 'developer-id',
    nextStep: 'developer_home',
    fullName: 'Dev User',
    role: 'Developer',
    onboardingCompleted: true,
  );

  testWidgets('routes each authenticated role to its own workspace', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthDestinationPage(
          title: 'Project Manager Home',
          description: 'Manager workspace',
          profile: managerProfile,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ManagerHomePage), findsOneWidget);
    expect(find.byType(DeveloperHomePage), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: AuthDestinationPage(
          title: 'Developer Home',
          description: 'Developer workspace',
          profile: developerProfile,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(DeveloperHomePage), findsOneWidget);
    expect(find.byType(ManagerHomePage), findsNothing);
  });

  testWidgets('all Manager navigation destinations render their pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ManagerHomePage(profile: managerProfile)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Project clarity starts here.'), findsOneWidget);
    expect(find.text('Morgan Manager'), findsOneWidget);

    const destinations = <(String, String)>[
      ('manager-nav-projects', 'Every connected repository, in view.'),
      ('manager-nav-issues', 'Make the next review count.'),
      ('manager-nav-team', 'See the collaboration, not a score.'),
      ('manager-nav-analytics', 'Evidence for the next decision.'),
      ('manager-nav-reports', 'A clear snapshot for the conversation.'),
      ('manager-nav-settings', 'Your account, your workspace.'),
      ('manager-nav-home', 'Project clarity starts here.'),
    ];
    for (final (key, heading) in destinations) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(heading), findsOneWidget);
      if (key == 'manager-nav-projects') {
        expect(find.text('Connect repository'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('Manager navigation adapts to a narrow browser', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ManagerHomePage(profile: managerProfile)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('dashboard-open-navigation')));
    await tester.pump();
    expect(
      tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('manager-nav-projects')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Every connected repository, in view.'), findsOneWidget);
    expect(find.text('Connect repository'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('desktop sidebar expands on hover without shifting content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ManagerHomePage(profile: managerProfile)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final sidebar = find.byType(DashboardNavigation<ManagerDestination>).last;
    final content = find.byKey(const ValueKey('manager-dashboard-content'));
    final initialContentLeft = tester.getRect(content).left;
    expect(tester.getSize(sidebar).width, 76);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(24, 120));
    await mouse.moveTo(const Offset(24, 120));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    expect(tester.getSize(sidebar).width, 224);
    expect(tester.getRect(content).left, initialContentLeft);

    await mouse.moveTo(const Offset(500, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    expect(tester.getSize(sidebar).width, 76);
    expect(tester.getRect(content).left, initialContentLeft);
    await mouse.removePointer();
    await tester.pump(const Duration(milliseconds: 250));
  });
}
