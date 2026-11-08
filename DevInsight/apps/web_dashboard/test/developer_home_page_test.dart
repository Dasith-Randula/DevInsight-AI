import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/pages/developer_home_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    expect(find.text('Repository Languages'), findsOneWidget);
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

  testWidgets('connection dialog validates GitHub URLs before submitting', (
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
    await tester.tap(find.text('Manage Repositories'));
    await _pumpDashboard(tester);
    expect(find.text('Connect New Repository'), findsOneWidget);
    await tester.tap(find.text('Connect New Repository'));
    await _pumpDashboard(tester);

    expect(find.text('Connect GitHub Repository'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('github-repository-url')),
      'https://example.com/owner/repository',
    );
    await tester.tap(find.text('Connect').last);
    await tester.pump();

    expect(find.text('Enter a public GitHub repository URL.'), findsOneWidget);
    expect(find.text('Connect GitHub Repository'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connecting a public repository displays live response data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/api/v1/github/connections') {
          return http.Response('[]', 200);
        }
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/github/connections') {
          return http.Response(jsonEncode(_connectionResponse), 200);
        }
        if (request.url.path ==
            '/api/v1/github/connections/connection-1/overview') {
          return http.Response(jsonEncode(_overviewResponse), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DeveloperHomePage(
          profile: profile,
          api: api,
          authService: _TestAuthService(api),
        ),
      ),
    );
    await _pumpDashboard(tester);
    await tester.tap(find.text('Connect repository').first);
    await _pumpDashboard(tester);
    await tester.enterText(
      find.byKey(const ValueKey('github-repository-url')),
      'https://github.com/acme/repository.git',
    );
    await tester.tap(find.text('Connect').last);
    await _pumpDashboard(tester);

    expect(find.text('acme/repository'), findsOneWidget);
    expect(find.text('Owner: acme  ·  Branch: main'), findsOneWidget);
    expect(find.text('Stars: 12  ·  Forks: 3'), findsOneWidget);
    expect(find.text('Open Pull Requests'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('Fix dashboard'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('36 commits · main'), findsOneWidget);
    expect(find.text('Recently active'), findsOneWidget);
    expect(find.text('Oldest open PR: 18 days · aging'), findsOneWidget);
    expect(find.text('Default branch commit · abc'), findsOneWidget);
    expect(find.text('Passing'), findsNWidgets(2));
    expect(find.text('Detected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores a saved repository when Developer Home is reopened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/github/connections') {
          return http.Response(jsonEncode([_connectionResponse]), 200);
        }
        return http.Response(jsonEncode(_overviewResponse), 200);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DeveloperHomePage(
          profile: profile,
          api: api,
          authService: _TestAuthService(api),
        ),
      ),
    );
    await _pumpDashboard(tester);

    expect(find.text('acme/repository'), findsOneWidget);
    expect(find.text('Stars: 12  ·  Forks: 3'), findsOneWidget);
    expect(find.text('Fix dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manage switches repository and remembers selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final secondConnection = {
      ..._connectionResponse,
      'id': 'connection-2',
      'github_repository_id': 456,
      'repository_full_name': 'acme/second',
      'repository_url': 'https://github.com/acme/second',
      'repository_name': 'second',
      'primary_language': 'Python',
    };
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/github/connections') {
          return http.Response(
            jsonEncode([_connectionResponse, secondConnection]),
            200,
          );
        }
        final selected = request.url.path.contains('/connection-2/overview')
            ? secondConnection
            : _connectionResponse;
        return http.Response(
          jsonEncode(
            _overviewFor(
              selected,
              selected == secondConnection ? 'Python' : 'Dart',
            ),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DeveloperHomePage(
          profile: profile,
          api: api,
          authService: _TestAuthService(api),
        ),
      ),
    );
    await _pumpDashboard(tester);
    expect(find.text('acme/repository'), findsOneWidget);
    expect(find.text('2 repositories connected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('manage-repositories')));
    await _pumpDashboard(tester);
    expect(find.text('Manage Repositories'), findsOneWidget);
    expect(find.text('acme/second'), findsOneWidget);
    expect(find.text('acme/repository'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('repository-connection-2')));
    await _pumpDashboard(tester);

    expect(find.text('acme/second'), findsOneWidget);
    expect(find.text('Primary language: Python'), findsOneWidget);
    expect(find.text('80 commits · main'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('devinsight.active_repository.${profile.id}'),
      'connection-2',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DeveloperHomePage(
          profile: profile,
          api: api,
          authService: _TestAuthService(api),
        ),
      ),
    );
    await _pumpDashboard(tester);
    expect(find.text('acme/second'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disconnect removes only that repository and selects a survivor',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final secondConnection = {
        ..._connectionResponse,
        'id': 'connection-2',
        'github_repository_id': 456,
        'repository_full_name': 'acme/second',
        'repository_url': 'https://github.com/acme/second',
        'repository_name': 'second',
        'primary_language': 'Python',
      };
      final api = DevInsightApi(
        baseUrl: 'http://127.0.0.1:8000',
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/github/connections') {
            return http.Response(
              jsonEncode([_connectionResponse, secondConnection]),
              200,
            );
          }
          if (request.method == 'DELETE') return http.Response('', 204);
          final selected = request.url.path.contains('/connection-2/overview')
              ? secondConnection
              : _connectionResponse;
          return http.Response(
            jsonEncode(
              _overviewFor(
                selected,
                selected == secondConnection ? 'Python' : 'Dart',
              ),
            ),
            200,
          );
        }),
      );
      addTearDown(api.close);

      await tester.pumpWidget(
        MaterialApp(
          home: DeveloperHomePage(
            profile: profile,
            api: api,
            authService: _TestAuthService(api),
          ),
        ),
      );
      await _pumpDashboard(tester);
      await tester.tap(find.byKey(const ValueKey('manage-repositories')));
      await _pumpDashboard(tester);
      await tester.tap(find.byTooltip('Disconnect acme/repository'));
      await _pumpDashboard(tester);
      expect(find.text('Disconnect repository?'), findsOneWidget);
      await tester.tap(find.text('Disconnect').last);
      await _pumpDashboard(tester);

      expect(find.text('acme/second'), findsNWidgets(2));
      expect(find.text('acme/repository'), findsNothing);
      expect(find.text('1 repository connected'), findsOneWidget);
      expect(find.text('Manage Repositories'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

class _TestAuthService extends AuthService {
  _TestAuthService(DevInsightApi api) : super(api: api);

  @override
  bool get hasSession => true;

  @override
  Future<T> withSession<T>(Future<T> Function(String accessToken) request) {
    return request('test-access-token');
  }
}

final _connectionResponse = {
  'id': 'connection-1',
  'github_repository_id': 123,
  'repository_full_name': 'acme/repository',
  'repository_url': 'https://github.com/acme/repository',
  'repository_owner': 'acme',
  'repository_name': 'repository',
  'description': 'A connected repository',
  'default_branch': 'main',
  'primary_language': 'Dart',
  'is_private': false,
  'stargazers_count': 12,
  'forks_count': 3,
  'connected_at': '2026-11-08T10:00:00Z',
  'last_synced_at': '2026-11-08T10:00:00Z',
  'cached_summary': {},
};

final _overviewResponse = {
  'connection': _connectionResponse,
  'is_stale': false,
  'summary': {
    'open_pull_requests': 2,
    'resolved_issues_30d': 1,
    'languages': [
      {'name': 'Dart', 'bytes': 100, 'percentage': 100.0},
    ],
    'recent_activity': [
      {
        'type': 'commit',
        'title': 'Fix dashboard',
        'author': 'developer',
        'url': 'https://github.com/acme/repository/commit/abc',
        'date': '2026-11-08T10:00:00Z',
        'labels': [],
      },
    ],
    'weekly_activity': {
      'availability': 'available',
      'is_complete': true,
      'weeks': [
        {'week_start': '2026-09-20', 'commits': 1},
        {'week_start': '2026-09-27', 'commits': 2},
        {'week_start': '2026-10-04', 'commits': 3},
        {'week_start': '2026-10-11', 'commits': 4},
        {'week_start': '2026-10-18', 'commits': 5},
        {'week_start': '2026-10-25', 'commits': 6},
        {'week_start': '2026-11-01', 'commits': 7},
        {'week_start': '2026-11-08', 'commits': 8},
      ],
      'total_commits': 36,
      'branch': 'main',
      'period_start': '2026-09-20',
      'period_end': '2026-11-14',
      'week_boundary': 'Sunday 00:00 UTC',
    },
    'repository_health': {
      'last_push_at': '2026-11-08T10:00:00Z',
      'latest_commit_at': '2026-11-08T10:00:00Z',
      'recent_activity_status': 'recently_active',
      'open_issues': 4,
      'recently_closed_issues_30d': 1,
      'open_pull_requests': 2,
      'oldest_open_pull_request': {
        'availability': 'available',
        'pull_request': {
          'number': 7,
          'title': 'Long-running pull request',
          'created_at': '2026-10-27T10:00:00Z',
          'age_days': 18,
          'url': 'https://github.com/acme/repository/pull/7',
        },
      },
      'ci_state': 'success',
      'ci_completed_at': '2026-11-08T10:00:00Z',
      'repository_updated_at': '2026-11-08T10:00:00Z',
    },
    'quality_signals': {
      'ci': {
        'availability': 'available',
        'state': 'success',
        'passed': 4,
        'failed': 0,
        'pending': 0,
        'last_completed_at': '2026-11-08T10:00:00Z',
        'url': 'https://github.com/acme/repository/actions',
      },
      'readme_present': true,
      'license_present': true,
      'tests_detected': true,
      'default_branch': 'main',
      'latest_commit': {
        'sha': 'abc',
        'date': '2026-11-08T10:00:00Z',
        'url': 'https://github.com/acme/repository/commit/abc',
      },
    },
  },
};

Map<String, Object?> _overviewFor(
  Map<String, Object?> connection,
  String language,
) => {
  'connection': connection,
  'is_stale': false,
  'summary': {
    'open_pull_requests': 2,
    'resolved_issues_30d': 1,
    'languages': [
      {'name': language, 'bytes': 100, 'percentage': 100.0},
    ],
    'recent_activity': [
      {
        'type': 'commit',
        'title': '$language update',
        'author': 'developer',
        'url': 'https://github.com/acme/repository/commit/abc',
        'date': '2026-11-08T10:00:00Z',
        'labels': [],
      },
    ],
    'weekly_activity': {
      'availability': 'available',
      'is_complete': true,
      'weeks': [
        {'week_start': '2026-09-20', 'commits': language == 'Python' ? 10 : 1},
        {'week_start': '2026-09-27', 'commits': language == 'Python' ? 10 : 1},
        {'week_start': '2026-10-04', 'commits': language == 'Python' ? 10 : 1},
        {'week_start': '2026-10-11', 'commits': language == 'Python' ? 10 : 1},
        {'week_start': '2026-10-18', 'commits': language == 'Python' ? 10 : 1},
        {'week_start': '2026-10-25', 'commits': language == 'Python' ? 10 : 1},
        {'week_start': '2026-11-01', 'commits': language == 'Python' ? 10 : 1},
        {'week_start': '2026-11-08', 'commits': language == 'Python' ? 10 : 1},
      ],
      'total_commits': language == 'Python' ? 80 : 8,
      'branch': 'main',
      'period_start': '2026-09-20',
      'period_end': '2026-11-14',
      'week_boundary': 'Sunday 00:00 UTC',
    },
  },
};

Future<void> _pumpDashboard(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
