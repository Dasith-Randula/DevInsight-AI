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
}
