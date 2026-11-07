import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

class DevInsightApiException implements Exception {
  const DevInsightApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CurrentUserProfile {
  const CurrentUserProfile({
    required this.id,
    required this.nextStep,
    this.fullName,
    this.email,
    this.role,
    this.onboardingCompleted = false,
  });

  final String id;
  final String nextStep;
  final String? fullName;
  final String? email;
  final String? role;
  final bool onboardingCompleted;

  factory CurrentUserProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nextStep = json['next_step'];
    if (id is! String || nextStep is! String) {
      throw const DevInsightApiException(
        'The account response from the server was invalid.',
      );
    }

    return CurrentUserProfile(
      id: id,
      nextStep: nextStep,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      onboardingCompleted: json['onboarding_completed'] == true,
    );
  }
}

class DevInsightApi {
  DevInsightApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<CurrentUserProfile> getCurrentUser(String accessToken) async {
    late final http.Response response;
    try {
      final uri = Uri.parse(baseUrl).resolve('/api/v1/me');
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw const DevInsightApiException(
        'Could not connect to DevInsight. Check the connection and try again.',
      );
    } on TimeoutException {
      throw const DevInsightApiException(
        'Could not connect to DevInsight. Check the connection and try again.',
      );
    } on FormatException {
      throw const DevInsightApiException(
        'The DevInsight API address is not configured correctly.',
      );
    }

    if (response.statusCode == 401) {
      throw const DevInsightApiException('Your session has expired.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const DevInsightApiException(
        'DevInsight could not load your account. Please try again.',
      );
    }

    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Expected an object response.');
      }
      return CurrentUserProfile.fromJson(body);
    } on FormatException {
      throw const DevInsightApiException(
        'The account response from the server was invalid.',
      );
    } on TypeError {
      throw const DevInsightApiException(
        'The account response from the server was invalid.',
      );
    }
  }

  void close() => _client.close();
}
