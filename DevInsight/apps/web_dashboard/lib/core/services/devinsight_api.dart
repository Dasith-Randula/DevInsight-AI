import 'dart:async';
import 'dart:convert';

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
    _validateOptionalFields(
      json,
      const ['full_name', 'email', 'role'],
      'The account response from the server was invalid.',
    );
    if (json['onboarding_completed'] != null &&
        json['onboarding_completed'] is! bool) {
      throw const DevInsightApiException(
        'The account response from the server was invalid.',
      );
    }

    return CurrentUserProfile(
      id: id,
      nextStep: nextStep,
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      onboardingCompleted: json['onboarding_completed'] == true,
    );
  }
}

class OnboardingProfileData {
  const OnboardingProfileData({
    required this.id,
    required this.onboardingStep,
    required this.onboardingCompleted,
    this.fullName,
    this.username,
    this.organization,
    this.jobTitle,
    this.role,
  });

  final String id;
  final String? fullName;
  final String? username;
  final String? organization;
  final String? jobTitle;
  final String? role;
  final int onboardingStep;
  final bool onboardingCompleted;

  factory OnboardingProfileData.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) {
      throw const DevInsightApiException(
        'The saved onboarding profile was invalid.',
      );
    }
    _validateOptionalFields(
      json,
      const ['full_name', 'username', 'organization', 'job_title', 'role'],
      'The saved onboarding profile was invalid.',
    );
    final onboardingStep = json['onboarding_step'];
    if (onboardingStep != null && onboardingStep is! int) {
      throw const DevInsightApiException(
        'The saved onboarding profile was invalid.',
      );
    }
    final onboardingCompleted = json['onboarding_completed'];
    if (onboardingCompleted != null && onboardingCompleted is! bool) {
      throw const DevInsightApiException(
        'The saved onboarding profile was invalid.',
      );
    }
    return OnboardingProfileData(
      id: id,
      fullName: json['full_name'],
      username: json['username'],
      organization: json['organization'],
      jobTitle: json['job_title'],
      role: json['role'],
      onboardingStep: onboardingStep ?? 1,
      onboardingCompleted: onboardingCompleted ?? false,
    );
  }
}

class OnboardingState {
  const OnboardingState({
    required this.profile,
    required this.nextStep,
    this.interests = const [],
    this.emailEnabled,
    this.pushEnabled,
    this.notificationTopics = const [],
  });

  final OnboardingProfileData profile;
  final String nextStep;
  final List<String> interests;
  final bool? emailEnabled;
  final bool? pushEnabled;
  final List<String> notificationTopics;

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    final nextStep = json['next_step'];
    if (profileJson is! Map<String, dynamic> || nextStep is! String) {
      throw const DevInsightApiException(
        'The saved onboarding state was invalid.',
      );
    }

    final preferences = json['preferences'];
    final notifications = json['notifications'];
    if ((preferences != null && preferences is! Map<String, dynamic>) ||
        (notifications != null && notifications is! Map<String, dynamic>)) {
      throw const DevInsightApiException(
        'The saved onboarding state was invalid.',
      );
    }
    final interests = preferences is Map<String, dynamic>
        ? preferences['interests']
        : null;
    final topics = notifications is Map<String, dynamic>
        ? notifications['topics']
        : null;
    if ((interests != null && interests is! List) ||
        (topics != null && topics is! List)) {
      throw const DevInsightApiException(
        'The saved onboarding selections were invalid.',
      );
    }
    if ((interests is List && interests.any((value) => value is! String)) ||
        (topics is List && topics.any((value) => value is! String)) ||
        (notifications is Map<String, dynamic> &&
            (notifications['email_enabled'] != null &&
                notifications['email_enabled'] is! bool)) ||
        (notifications is Map<String, dynamic> &&
            (notifications['push_enabled'] != null &&
                notifications['push_enabled'] is! bool))) {
      throw const DevInsightApiException(
        'The saved onboarding selections were invalid.',
      );
    }

    return OnboardingState(
      profile: OnboardingProfileData.fromJson(profileJson),
      nextStep: nextStep,
      interests: interests == null
          ? const []
          : List<String>.unmodifiable(interests),
      emailEnabled: notifications is Map<String, dynamic>
          ? notifications['email_enabled']
          : null,
      pushEnabled: notifications is Map<String, dynamic>
          ? notifications['push_enabled']
          : null,
      notificationTopics: topics == null
          ? const []
          : List<String>.unmodifiable(topics),
    );
  }
}

class OnboardingCompletion {
  const OnboardingCompletion({
    required this.onboardingCompleted,
    required this.role,
    required this.nextStep,
  });

  final bool onboardingCompleted;
  final String role;
  final String nextStep;

  factory OnboardingCompletion.fromJson(Map<String, dynamic> json) {
    final completed = json['onboarding_completed'];
    final role = json['role'];
    final nextStep = json['next_step'];
    if (completed is! bool ||
        role is! String ||
        nextStep is! String ||
        !completed) {
      throw const DevInsightApiException(
        'The server did not confirm onboarding completion.',
      );
    }
    return OnboardingCompletion(
      onboardingCompleted: completed,
      role: role,
      nextStep: nextStep,
    );
  }
}

void _validateOptionalFields(
  Map<String, dynamic> values,
  List<String> fields,
  String errorMessage,
) {
  if (fields.any(
    (field) => values[field] != null && values[field] is! String,
  )) {
    throw DevInsightApiException(errorMessage);
  }
}

class DevInsightApi {
  DevInsightApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<CurrentUserProfile> getCurrentUser(String accessToken) async {
    final response = await _request(
      'GET',
      '/api/v1/me',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not load your account. Please try again.',
    );
    return CurrentUserProfile.fromJson(_decodeObject(response));
  }

  Future<OnboardingState> getOnboardingState(String accessToken) async {
    final response = await _request(
      'GET',
      '/api/v1/onboarding/state',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not load your saved onboarding details. Please try again.',
    );
    return OnboardingState.fromJson(_decodeObject(response));
  }

  Future<void> saveProfile(
    String accessToken, {
    required String fullName,
    required String username,
    required String? organization,
    required String? jobTitle,
    required String role,
  }) async {
    final response = await _request(
      'PUT',
      '/api/v1/onboarding/profile',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not save your onboarding details. Please try again.',
      body: {
        'full_name': fullName,
        'username': username,
        'organization': organization,
        'job_title': jobTitle,
        'role': role,
      },
    );
    _validateSaveResponse(response);
  }

  Future<void> savePreferences(
    String accessToken,
    List<String> interests,
  ) async {
    final response = await _request(
      'PUT',
      '/api/v1/onboarding/preferences',
      accessToken: accessToken,
      body: {'interests': interests},
      failureMessage:
          'DevInsight could not save your onboarding details. Please try again.',
    );
    _validateSaveResponse(response);
  }

  Future<void> saveNotifications(
    String accessToken, {
    required bool emailEnabled,
    required bool pushEnabled,
    required List<String> topics,
  }) async {
    final response = await _request(
      'PUT',
      '/api/v1/onboarding/notifications',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not save your onboarding details. Please try again.',
      body: {
        'email_enabled': emailEnabled,
        'push_enabled': pushEnabled,
        'topics': topics,
      },
    );
    _validateSaveResponse(response);
  }

  Future<OnboardingCompletion> completeOnboarding(String accessToken) async {
    final response = await _request(
      'POST',
      '/api/v1/onboarding/complete',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not confirm onboarding completion. Please try again.',
    );
    return OnboardingCompletion.fromJson(_decodeObject(response));
  }

  Future<http.Response> _request(
    String method,
    String path, {
    required String accessToken,
    required String failureMessage,
    Map<String, Object?>? body,
  }) async {
    try {
      final request = http.Request(method, Uri.parse(baseUrl).resolve(path))
        ..headers.addAll({
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401) {
        throw const DevInsightApiException('Your session has expired.');
      }
      if (response.statusCode == 409) {
        throw DevInsightApiException(_conflictMessage(response.body));
      }
      if (response.statusCode == 422) {
        throw const DevInsightApiException(
          'Some onboarding details are invalid. Review your selections and try again.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DevInsightApiException(failureMessage);
      }
      return response;
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
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Expected an object response.');
      }
      return body;
    } on FormatException {
      throw const DevInsightApiException(
        'The response from DevInsight was invalid.',
      );
    } on TypeError {
      throw const DevInsightApiException(
        'The response from DevInsight was invalid.',
      );
    }
  }

  void _validateSaveResponse(http.Response response) {
    final body = _decodeObject(response);
    if (body['status'] != 'saved' || body['onboarding_step'] is! int) {
      throw const DevInsightApiException(
        'The server did not confirm saving your onboarding details.',
      );
    }
  }

  String _conflictMessage(String responseBody) {
    try {
      final body = jsonDecode(responseBody);
      final detail = body is Map<String, dynamic> ? body['detail'] : null;
      if (detail is String && detail.toLowerCase().contains('username')) {
        return 'That username is already taken. Please choose another.';
      }
    } on FormatException {
      return 'This onboarding step cannot be saved yet. Complete the previous step first.';
    }
    return 'This onboarding step cannot be saved yet. Complete the previous step first.';
  }

  void close() => _client.close();
}
