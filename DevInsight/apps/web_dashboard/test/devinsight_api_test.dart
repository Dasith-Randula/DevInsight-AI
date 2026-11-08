import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';

void main() {
  test('GET /me sends bearer token and parses backend destination', () async {
    late http.Request capturedRequest;
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'id': 'user-id',
            'full_name': 'Test User',
            'role': 'developer',
            'onboarding_step': 3,
            'onboarding_completed': true,
            'next_step': 'developer_home',
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);

    final profile = await api.getCurrentUser('test-access-token');

    expect(capturedRequest.url.path, '/api/v1/me');
    expect(
      capturedRequest.headers['Authorization'],
      'Bearer test-access-token',
    );
    expect(profile.id, 'user-id');
    expect(profile.nextStep, 'developer_home');
    expect(profile.onboardingCompleted, isTrue);
  });

  test('401 response is reported as an expired session', () async {
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    addTearDown(api.close);

    expect(
      () => api.getCurrentUser('test-access-token'),
      throwsA(
        isA<DevInsightApiException>().having(
          (error) => error.message,
          'message',
          'Your session has expired.',
        ),
      ),
    );
  });

  test('server errors do not expose response details', () async {
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient(
        (_) async => http.Response('private server detail', 500),
      ),
    );
    addTearDown(api.close);

    expect(
      () => api.getCurrentUser('test-access-token'),
      throwsA(
        isA<DevInsightApiException>().having(
          (error) => error.message,
          'message',
          'DevInsight could not load your account. Please try again.',
        ),
      ),
    );
  });

  test('onboarding state restores saved profile and selections', () async {
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'profile': {
              'id': 'user-id',
              'full_name': 'Test User',
              'username': 'tester',
              'organization': 'DevInsight',
              'job_title': 'Engineer',
              'role': 'developer',
              'onboarding_step': 3,
              'onboarding_completed': false,
            },
            'preferences': {
              'interests': ['AI Recommendations'],
            },
            'notifications': {
              'email_enabled': true,
              'push_enabled': false,
              'topics': ['Project Updates'],
            },
            'next_step': 'notifications',
          }),
          200,
        ),
      ),
    );
    addTearDown(api.close);

    final state = await api.getOnboardingState('access-token');

    expect(state.profile.username, 'tester');
    expect(state.profile.role, 'developer');
    expect(state.interests, ['AI Recommendations']);
    expect(state.emailEnabled, isTrue);
    expect(state.pushEnabled, isFalse);
    expect(state.notificationTopics, ['Project Updates']);
    expect(state.nextStep, 'notifications');
  });

  test('malformed onboarding state returns a safe API error', () async {
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'profile': {'id': 'user-id'},
            'preferences': {
              'interests': [42],
            },
            'next_step': 'preferences',
          }),
          200,
        ),
      ),
    );
    addTearDown(api.close);

    await expectLater(
      api.getOnboardingState('access-token'),
      throwsA(
        isA<DevInsightApiException>().having(
          (error) => error.message,
          'message',
          'The saved onboarding selections were invalid.',
        ),
      ),
    );
  });

  test('profile request uses backend field names and role values', () async {
    late http.Request request;
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({'status': 'saved', 'onboarding_step': 2}),
          200,
        );
      }),
    );
    addTearDown(api.close);

    await api.saveProfile(
      'access-token',
      fullName: 'Test User',
      username: 'testuser',
      organization: 'DevInsight',
      jobTitle: 'Engineer',
      role: 'project_manager',
    );

    expect(request.method, 'PUT');
    expect(request.url.path, '/api/v1/onboarding/profile');
    expect(jsonDecode(request.body), {
      'full_name': 'Test User',
      'username': 'testuser',
      'organization': 'DevInsight',
      'job_title': 'Engineer',
      'role': 'project_manager',
    });
    expect(request.headers['Authorization'], 'Bearer access-token');
  });

  test('duplicate username response is actionable', () async {
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Username is already in use.'}),
          409,
        ),
      ),
    );
    addTearDown(api.close);

    await expectLater(
      api.saveProfile(
        'access-token',
        fullName: 'Test User',
        username: 'taken',
        organization: null,
        jobTitle: null,
        role: 'developer',
      ),
      throwsA(
        isA<DevInsightApiException>().having(
          (error) => error.message,
          'message',
          'That username is already taken. Please choose another.',
        ),
      ),
    );
  });

  test(
    'preferences and notification requests match backend payloads',
    () async {
      final requests = <http.Request>[];
      final api = DevInsightApi(
        baseUrl: 'http://127.0.0.1:8000',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'status': 'saved', 'onboarding_step': 3}),
            200,
          );
        }),
      );
      addTearDown(api.close);

      await api.savePreferences('access-token', ['AI Recommendations']);
      await api.saveNotifications(
        'access-token',
        emailEnabled: true,
        pushEnabled: false,
        topics: ['Project Updates'],
      );

      expect(requests[0].url.path, '/api/v1/onboarding/preferences');
      expect(jsonDecode(requests[0].body), {
        'interests': ['AI Recommendations'],
      });
      expect(requests[1].url.path, '/api/v1/onboarding/notifications');
      expect(jsonDecode(requests[1].body), {
        'email_enabled': true,
        'push_enabled': false,
        'topics': ['Project Updates'],
      });
    },
  );

  test('completion requires backend confirmation and destination', () async {
    final responses = [
      http.Response(
        jsonEncode({
          'onboarding_completed': true,
          'role': 'developer',
          'next_step': 'developer_home',
        }),
        200,
      ),
      http.Response(
        jsonEncode({
          'onboarding_completed': true,
          'role': 'project_manager',
          'next_step': 'manager_home',
        }),
        200,
      ),
    ];
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((_) async => responses.removeAt(0)),
    );
    addTearDown(api.close);

    expect(
      (await api.completeOnboarding('access-token')).nextStep,
      'developer_home',
    );
    expect(
      (await api.completeOnboarding('access-token')).nextStep,
      'manager_home',
    );
  });

  test(
    'GitHub connection and overview use authenticated API endpoints',
    () async {
      final requests = <http.Request>[];
      final connection = {
        'id': 'connection-id',
        'github_repository_id': 123,
        'repository_full_name': 'acme/repository',
        'repository_url': 'https://github.com/acme/repository',
        'repository_owner': 'acme',
        'repository_name': 'repository',
        'description': 'A real project',
        'default_branch': 'main',
        'primary_language': 'Dart',
        'is_private': false,
        'stargazers_count': 4,
        'forks_count': 1,
        'connected_at': '2026-11-08T10:00:00Z',
        'last_synced_at': '2026-11-08T10:00:00Z',
        'cached_summary': {},
      };
      final api = DevInsightApi(
        baseUrl: 'http://127.0.0.1:8000',
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            return http.Response(jsonEncode(connection), 200);
          }
          return http.Response(
            jsonEncode({
              'connection': connection,
              'is_stale': false,
              'summary': {
                'open_pull_requests': 3,
                'resolved_issues_30d': 5,
                'languages': [
                  {'name': 'Dart', 'bytes': 100, 'percentage': 100.0},
                ],
                'recent_activity': [],
                'weekly_activity': {
                  'availability': 'available',
                  'is_complete': true,
                  'weeks': [
                    {'week_start': '2026-11-08', 'commits': 3},
                  ],
                  'total_commits': 3,
                  'branch': 'main',
                  'period_start': '2026-11-08',
                  'period_end': '2026-11-14',
                  'week_boundary': 'Sunday 00:00 UTC',
                },
                'repository_health': {
                  'recent_activity_status': 'recently_active',
                  'ci_state': 'success',
                  'open_issues': 2,
                  'recently_closed_issues_30d': 1,
                  'open_pull_requests': 3,
                  'oldest_open_pull_request': {
                    'availability': 'available',
                    'pull_request': {
                      'age_days': 18,
                      'title': 'Long-running PR',
                      'url': 'https://github.com/acme/repository/pull/7',
                    },
                  },
                },
                'quality_signals': {
                  'ci': {
                    'availability': 'available',
                    'state': 'success',
                    'passed': 2,
                    'failed': 0,
                    'pending': 0,
                  },
                  'default_branch': 'main',
                  'readme_present': true,
                  'license_present': true,
                  'tests_detected': true,
                  'latest_commit': {
                    'sha': 'abcdef123456',
                    'url': 'https://github.com/acme/repository/commit/abcdef',
                  },
                },
              },
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);

      final saved = await api.connectGitHubRepository(
        'access-token',
        'https://github.com/acme/repository.git',
      );
      final overview = await api.getGitHubOverview('access-token', saved.id);

      expect(requests[0].url.path, '/api/v1/github/connections');
      expect(
        requests[0].headers['Authorization']!.startsWith('Bearer '),
        isTrue,
      );
      expect(
        requests[0].headers['Authorization']!.endsWith('access-token'),
        isTrue,
      );
      expect(jsonDecode(requests[0].body), {
        'repository_url': 'https://github.com/acme/repository.git',
      });
      expect(overview.connection.fullName, 'acme/repository');
      expect(overview.openPullRequests, 3);
      expect(overview.resolvedIssues30d, 5);
      expect(overview.languages.single.percentage, 100);
      expect(overview.isStale, isFalse);
      expect(overview.weeklyActivity!.totalCommits, 3);
      expect(overview.weeklyActivity!.weeks.single.commits, 3);
      expect(overview.repositoryHealth!.oldestOpenPullRequestAgeDays, 18);
      expect(overview.repositoryHealth!.oldestOpenPullRequestPresent, isTrue);
      expect(overview.qualitySignals!.ci.passed, 2);
      expect(overview.qualitySignals!.testsDetected, isTrue);
      expect(overview.qualitySignals!.latestCommitSha, 'abcdef123456');
    },
  );

  test('GitHub rate limit response has a safe actionable message', () async {
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((_) async => http.Response('{}', 429)),
    );
    addTearDown(api.close);

    await expectLater(
      api.connectGitHubRepository(
        'access-token',
        'https://github.com/acme/repository',
      ),
      throwsA(
        isA<DevInsightApiException>().having(
          (error) => error.message,
          'message',
          'GitHub is rate limiting requests. Please try again later.',
        ),
      ),
    );
  });

  test('disconnecting a GitHub repository uses its scoped endpoint', () async {
    late http.Request capturedRequest;
    final api = DevInsightApi(
      baseUrl: 'http://127.0.0.1:8000',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );
    addTearDown(api.close);

    await api.disconnectGitHubRepository('access-token', 'connection-1');

    expect(capturedRequest.method, 'DELETE');
    expect(capturedRequest.url.path, '/api/v1/github/connections/connection-1');
    expect(
      capturedRequest.headers['Authorization']!.endsWith('access-token'),
      isTrue,
    );
  });
}
