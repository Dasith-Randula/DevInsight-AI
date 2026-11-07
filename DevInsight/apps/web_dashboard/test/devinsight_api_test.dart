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
}
