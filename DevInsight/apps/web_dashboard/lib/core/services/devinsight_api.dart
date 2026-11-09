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
    _validateOptionalFields(json, const [
      'full_name',
      'email',
      'role',
    ], 'The account response from the server was invalid.');
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
    _validateOptionalFields(json, const [
      'full_name',
      'username',
      'organization',
      'job_title',
      'role',
    ], 'The saved onboarding profile was invalid.');
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

class GitHubRepositoryConnection {
  const GitHubRepositoryConnection({
    required this.id,
    required this.githubRepositoryId,
    required this.fullName,
    required this.url,
    required this.owner,
    required this.name,
    required this.isPrivate,
    required this.connectedAt,
    required this.cachedSummary,
    this.stars = 0,
    this.forks = 0,
    this.description,
    this.defaultBranch,
    this.primaryLanguage,
    this.repositoryCreatedAt,
    this.repositoryUpdatedAt,
    this.repositoryPushedAt,
    this.lastSyncedAt,
  });

  final String id;
  final int githubRepositoryId;
  final String fullName;
  final String url;
  final String owner;
  final String name;
  final String? description;
  final String? defaultBranch;
  final String? primaryLanguage;
  final DateTime? repositoryCreatedAt;
  final DateTime? repositoryUpdatedAt;
  final DateTime? repositoryPushedAt;
  final bool isPrivate;
  final int stars;
  final int forks;
  final DateTime connectedAt;
  final DateTime? lastSyncedAt;
  final Map<String, dynamic> cachedSummary;

  factory GitHubRepositoryConnection.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final repositoryId = json['github_repository_id'];
    final fullName = json['repository_full_name'];
    final url = json['repository_url'];
    final owner = json['repository_owner'];
    final name = json['repository_name'];
    final isPrivate = json['is_private'];
    final connectedAt = DateTime.tryParse('${json['connected_at'] ?? ''}');
    final cachedSummary = json['cached_summary'];
    final stars = json['stargazers_count'] ?? 0;
    final forks = json['forks_count'] ?? 0;
    final repositoryCreatedAt = _optionalDate(json['github_created_at']);
    final repositoryUpdatedAt = _optionalDate(json['github_updated_at']);
    final repositoryPushedAt = _optionalDate(json['github_pushed_at']);
    final lastSyncedAt = json['last_synced_at'] == null
        ? null
        : DateTime.tryParse('${json['last_synced_at']}');
    if (id is! String ||
        repositoryId is! int ||
        fullName is! String ||
        url is! String ||
        owner is! String ||
        name is! String ||
        isPrivate is! bool ||
        stars is! int ||
        forks is! int ||
        connectedAt == null ||
        cachedSummary is! Map<String, dynamic> ||
        (json['github_created_at'] != null && repositoryCreatedAt == null) ||
        (json['github_updated_at'] != null && repositoryUpdatedAt == null) ||
        (json['github_pushed_at'] != null && repositoryPushedAt == null) ||
        (json['last_synced_at'] != null && lastSyncedAt == null)) {
      throw const DevInsightApiException(
        'The GitHub repository response was invalid.',
      );
    }
    _validateOptionalFields(json, const [
      'description',
      'default_branch',
      'primary_language',
    ], 'The GitHub repository response was invalid.');
    return GitHubRepositoryConnection(
      id: id,
      githubRepositoryId: repositoryId,
      fullName: fullName,
      url: url,
      owner: owner,
      name: name,
      description: json['description'],
      defaultBranch: json['default_branch'],
      primaryLanguage: json['primary_language'],
      repositoryCreatedAt: repositoryCreatedAt,
      repositoryUpdatedAt: repositoryUpdatedAt,
      repositoryPushedAt: repositoryPushedAt,
      isPrivate: isPrivate,
      stars: stars,
      forks: forks,
      connectedAt: connectedAt,
      lastSyncedAt: lastSyncedAt,
      cachedSummary: cachedSummary,
    );
  }
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}

class GitHubLanguage {
  const GitHubLanguage({
    required this.name,
    required this.bytes,
    required this.percentage,
  });

  final String name;
  final int bytes;
  final double percentage;

  factory GitHubLanguage.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final bytes = json['bytes'];
    final percentage = json['percentage'];
    if (name is! String || bytes is! int || (percentage is! num)) {
      throw const DevInsightApiException(
        'The GitHub language data was invalid.',
      );
    }
    return GitHubLanguage(
      name: name,
      bytes: bytes,
      percentage: percentage.toDouble(),
    );
  }
}

class GitHubActivity {
  const GitHubActivity({
    required this.type,
    required this.title,
    required this.author,
    required this.url,
    required this.labels,
    this.date,
    this.createdAt,
    this.closedAt,
    this.mergedAt,
    this.number,
    this.state,
  });

  final String type;
  final String title;
  final String author;
  final String url;
  final List<String> labels;
  final DateTime? date;
  final DateTime? createdAt;
  final DateTime? closedAt;
  final DateTime? mergedAt;
  final int? number;
  final String? state;

  factory GitHubActivity.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final title = json['title'];
    final author = json['author'];
    final url = json['url'];
    final date = json['date'] == null
        ? null
        : DateTime.tryParse('${json['date']}');
    final createdAt = _optionalDate(json['created_at']);
    final closedAt = _optionalDate(json['closed_at']);
    final mergedAt = _optionalDate(json['merged_at']);
    final labels = json['labels'] ?? const <Object>[];
    if (type is! String ||
        title is! String ||
        author is! String ||
        url is! String ||
        labels is! List ||
        labels.any((label) => label is! String) ||
        (json['date'] != null && date == null) ||
        (json['created_at'] != null && createdAt == null) ||
        (json['closed_at'] != null && closedAt == null) ||
        (json['merged_at'] != null && mergedAt == null) ||
        (json['number'] != null && json['number'] is! int) ||
        (json['state'] != null && json['state'] is! String)) {
      throw const DevInsightApiException(
        'The GitHub activity response was invalid.',
      );
    }
    return GitHubActivity(
      type: type,
      title: title,
      author: author,
      url: url,
      labels: List<String>.from(labels),
      date: date,
      createdAt: createdAt,
      closedAt: closedAt,
      mergedAt: mergedAt,
      number: json['number'],
      state: json['state'],
    );
  }
}

class GitHubWeeklyCommit {
  const GitHubWeeklyCommit({required this.weekStart, required this.commits});

  final DateTime weekStart;
  final int? commits;

  factory GitHubWeeklyCommit.fromJson(Map<String, dynamic> json) {
    final weekStart = DateTime.tryParse('${json['week_start'] ?? ''}');
    final commits = json['commits'];
    if (weekStart == null || (commits != null && commits is! int)) {
      throw const DevInsightApiException(
        'The weekly repository activity data was invalid.',
      );
    }
    return GitHubWeeklyCommit(weekStart: weekStart, commits: commits as int?);
  }
}

class GitHubWeeklyActivity {
  const GitHubWeeklyActivity({
    required this.availability,
    required this.isComplete,
    required this.weeks,
    required this.weekBoundary,
    this.totalCommits,
    this.branch,
    this.periodStart,
    this.periodEnd,
  });

  final String availability;
  final bool isComplete;
  final List<GitHubWeeklyCommit> weeks;
  final int? totalCommits;
  final String? branch;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String weekBoundary;

  factory GitHubWeeklyActivity.fromJson(Map<String, dynamic> json) {
    final availability = json['availability'];
    final complete = json['is_complete'];
    final rawWeeks = json['weeks'];
    final total = json['total_commits'];
    final boundary = json['week_boundary'];
    final start = _optionalDate(json['period_start']);
    final end = _optionalDate(json['period_end']);
    if (availability is! String ||
        complete is! bool ||
        rawWeeks is! List ||
        (total != null && total is! int) ||
        boundary is! String ||
        (json['period_start'] != null && start == null) ||
        (json['period_end'] != null && end == null) ||
        (json['branch'] != null && json['branch'] is! String)) {
      throw const DevInsightApiException(
        'The weekly repository activity data was invalid.',
      );
    }
    try {
      return GitHubWeeklyActivity(
        availability: availability,
        isComplete: complete,
        weeks: rawWeeks
            .map(
              (item) => GitHubWeeklyCommit.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        totalCommits: total,
        branch: json['branch'],
        periodStart: start,
        periodEnd: end,
        weekBoundary: boundary,
      );
    } on TypeError {
      throw const DevInsightApiException(
        'The weekly repository activity data was invalid.',
      );
    }
  }
}

class GitHubCiSignals {
  const GitHubCiSignals({
    required this.availability,
    required this.state,
    this.passed,
    this.failed,
    this.pending,
    this.lastCompletedAt,
    this.url,
  });

  final String availability;
  final String state;
  final int? passed;
  final int? failed;
  final int? pending;
  final DateTime? lastCompletedAt;
  final String? url;

  factory GitHubCiSignals.fromJson(Map<String, dynamic> json) {
    final availability = json['availability'];
    final state = json['state'];
    final passed = json['passed'];
    final failed = json['failed'];
    final pending = json['pending'];
    final completed = _optionalDate(json['last_completed_at']);
    if (availability is! String ||
        state is! String ||
        (passed != null && passed is! int) ||
        (failed != null && failed is! int) ||
        (pending != null && pending is! int) ||
        (json['last_completed_at'] != null && completed == null) ||
        (json['url'] != null && json['url'] is! String)) {
      throw const DevInsightApiException('The CI status data was invalid.');
    }
    return GitHubCiSignals(
      availability: availability,
      state: state,
      passed: passed,
      failed: failed,
      pending: pending,
      lastCompletedAt: completed,
      url: json['url'],
    );
  }
}

class GitHubRepositoryHealth {
  const GitHubRepositoryHealth({
    required this.recentActivityStatus,
    required this.ciState,
    this.lastPushAt,
    this.latestCommitAt,
    this.openIssues,
    this.closedIssues30d,
    this.openPullRequests,
    this.oldestOpenPullRequestPresent = false,
    this.oldestOpenPullRequestAgeDays,
    this.oldestOpenPullRequestAvailability,
    this.oldestOpenPullRequestUrl,
    this.oldestOpenPullRequestTitle,
    this.lastUpdatedAt,
    this.ciCompletedAt,
  });

  final String recentActivityStatus;
  final String ciState;
  final DateTime? lastPushAt;
  final DateTime? latestCommitAt;
  final int? openIssues;
  final int? closedIssues30d;
  final int? openPullRequests;
  final bool oldestOpenPullRequestPresent;
  final int? oldestOpenPullRequestAgeDays;
  final String? oldestOpenPullRequestAvailability;
  final String? oldestOpenPullRequestUrl;
  final String? oldestOpenPullRequestTitle;
  final DateTime? lastUpdatedAt;
  final DateTime? ciCompletedAt;

  factory GitHubRepositoryHealth.fromJson(Map<String, dynamic> json) {
    final oldest = json['oldest_open_pull_request'];
    if (oldest != null && oldest is! Map<String, dynamic>) {
      throw const DevInsightApiException(
        'The repository health data was invalid.',
      );
    }
    final oldestAvailability = oldest is Map<String, dynamic>
        ? oldest['availability']
        : null;
    final oldestRecord = oldest is Map<String, dynamic>
        ? oldest['pull_request']
        : null;
    if (oldestRecord != null && oldestRecord is! Map<String, dynamic>) {
      throw const DevInsightApiException(
        'The repository health data was invalid.',
      );
    }
    final oldestPull = oldestRecord is Map<String, dynamic>
        ? oldestRecord
        : null;
    final openIssues = json['open_issues'];
    final closedIssues = json['recently_closed_issues_30d'];
    final openPulls = json['open_pull_requests'];
    final oldestAge = oldestPull?['age_days'];
    if ((openIssues != null && openIssues is! int) ||
        (closedIssues != null && closedIssues is! int) ||
        (openPulls != null && openPulls is! int) ||
        (oldestAvailability != null && oldestAvailability is! String) ||
        (oldestAge != null && oldestAge is! int) ||
        (oldestPull?['url'] != null && oldestPull?['url'] is! String) ||
        (oldestPull?['title'] != null && oldestPull?['title'] is! String)) {
      throw const DevInsightApiException(
        'The repository health data was invalid.',
      );
    }
    return GitHubRepositoryHealth(
      recentActivityStatus: json['recent_activity_status'] is String
          ? json['recent_activity_status'] as String
          : 'not_measured',
      ciState: json['ci_state'] is String
          ? json['ci_state'] as String
          : 'not_measured',
      lastPushAt: _optionalDate(json['last_push_at']),
      latestCommitAt: _optionalDate(json['latest_commit_at']),
      openIssues: openIssues,
      closedIssues30d: closedIssues,
      openPullRequests: openPulls,
      oldestOpenPullRequestPresent: oldestPull != null,
      oldestOpenPullRequestAgeDays: oldestAge,
      oldestOpenPullRequestAvailability: oldestAvailability,
      oldestOpenPullRequestUrl: oldestPull?['url'],
      oldestOpenPullRequestTitle: oldestPull?['title'],
      lastUpdatedAt: _optionalDate(json['repository_updated_at']),
      ciCompletedAt: _optionalDate(json['ci_completed_at']),
    );
  }
}

class GitHubQualitySignals {
  const GitHubQualitySignals({
    required this.ci,
    required this.defaultBranch,
    this.readmePresent,
    this.licensePresent,
    this.testsDetected,
    this.latestCommitSha,
    this.latestCommitUrl,
  });

  final GitHubCiSignals ci;
  final String? defaultBranch;
  final bool? readmePresent;
  final bool? licensePresent;
  final bool? testsDetected;
  final String? latestCommitSha;
  final String? latestCommitUrl;

  factory GitHubQualitySignals.fromJson(Map<String, dynamic> json) {
    final ci = json['ci'];
    final rawLatestCommit = json['latest_commit'];
    final latestCommit = rawLatestCommit is Map<String, dynamic>
        ? rawLatestCommit
        : null;
    if (ci is! Map<String, dynamic> ||
        (rawLatestCommit != null && latestCommit == null) ||
        (json['default_branch'] != null && json['default_branch'] is! String) ||
        (latestCommit?['sha'] != null && latestCommit?['sha'] is! String) ||
        (latestCommit?['url'] != null && latestCommit?['url'] is! String) ||
        (json['readme_present'] != null && json['readme_present'] is! bool) ||
        (json['license_present'] != null && json['license_present'] is! bool) ||
        (json['tests_detected'] != null && json['tests_detected'] is! bool)) {
      throw const DevInsightApiException(
        'The repository quality signals were invalid.',
      );
    }
    return GitHubQualitySignals(
      ci: GitHubCiSignals.fromJson(ci),
      defaultBranch: json['default_branch'],
      readmePresent: json['readme_present'],
      licensePresent: json['license_present'],
      testsDetected: json['tests_detected'],
      latestCommitSha: latestCommit?['sha'],
      latestCommitUrl: latestCommit?['url'],
    );
  }
}

class GitHubRepositoryOverview {
  const GitHubRepositoryOverview({
    required this.connection,
    required this.languages,
    required this.recentActivity,
    required this.isStale,
    this.weeklyActivity,
    this.repositoryHealth,
    this.qualitySignals,
    this.openPullRequests,
    this.resolvedIssues30d,
    this.throttled = false,
  });

  final GitHubRepositoryConnection connection;
  final List<GitHubLanguage> languages;
  final List<GitHubActivity> recentActivity;
  final int? openPullRequests;
  final int? resolvedIssues30d;
  final bool isStale;
  final bool throttled;
  final GitHubWeeklyActivity? weeklyActivity;
  final GitHubRepositoryHealth? repositoryHealth;
  final GitHubQualitySignals? qualitySignals;

  factory GitHubRepositoryOverview.fromJson(
    Map<String, dynamic> json, {
    bool throttled = false,
  }) {
    final connectionData = json['connection'];
    final summary = json['summary'];
    final isStale = json['is_stale'];
    if (connectionData is! Map<String, dynamic> ||
        summary is! Map<String, dynamic> ||
        isStale is! bool ||
        (summary['open_pull_requests'] != null &&
            summary['open_pull_requests'] is! int) ||
        (summary['resolved_issues_30d'] != null &&
            summary['resolved_issues_30d'] is! int) ||
        summary['languages'] is! List ||
        summary['recent_activity'] is! List ||
        (summary['weekly_activity'] != null &&
            summary['weekly_activity'] is! Map<String, dynamic>) ||
        (summary['repository_health'] != null &&
            summary['repository_health'] is! Map<String, dynamic>) ||
        (summary['quality_signals'] != null &&
            summary['quality_signals'] is! Map<String, dynamic>)) {
      throw const DevInsightApiException(
        'The GitHub repository overview was invalid.',
      );
    }
    final weeklyActivity = summary['weekly_activity'];
    final repositoryHealth = summary['repository_health'];
    final qualitySignals = summary['quality_signals'];
    try {
      return GitHubRepositoryOverview(
        connection: GitHubRepositoryConnection.fromJson(connectionData),
        languages: (summary['languages'] as List)
            .map(
              (item) => GitHubLanguage.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        recentActivity: (summary['recent_activity'] as List)
            .map(
              (item) => GitHubActivity.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        openPullRequests: summary['open_pull_requests'],
        resolvedIssues30d: summary['resolved_issues_30d'],
        isStale: isStale,
        throttled: throttled,
        weeklyActivity: weeklyActivity == null
            ? null
            : GitHubWeeklyActivity.fromJson(weeklyActivity),
        repositoryHealth: repositoryHealth == null
            ? null
            : GitHubRepositoryHealth.fromJson(repositoryHealth),
        qualitySignals: qualitySignals == null
            ? null
            : GitHubQualitySignals.fromJson(qualitySignals),
      );
    } on TypeError {
      throw const DevInsightApiException(
        'The GitHub repository overview was invalid.',
      );
    }
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

  Future<GitHubRepositoryConnection> connectGitHubRepository(
    String accessToken,
    String repositoryUrl,
  ) async {
    final response = await _request(
      'POST',
      '/api/v1/github/connections',
      accessToken: accessToken,
      body: {'repository_url': repositoryUrl},
      failureMessage:
          'DevInsight could not connect this repository. Please try again.',
      timeout: const Duration(seconds: 60),
      statusMessages: const {
        404: 'This public GitHub repository could not be found.',
        422:
            'Enter a valid public GitHub repository URL. Private repositories are not supported.',
        429: 'GitHub is rate limiting requests. Please try again later.',
        502: 'GitHub is temporarily unavailable. Please try again.',
      },
    );
    return GitHubRepositoryConnection.fromJson(_decodeObject(response));
  }

  Future<List<GitHubRepositoryConnection>> getGitHubConnections(
    String accessToken,
  ) async {
    final response = await _request(
      'GET',
      '/api/v1/github/connections',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not load your connected repositories. Please retry.',
    );
    try {
      final body = jsonDecode(response.body);
      if (body is! List) throw const FormatException();
      return body
          .map(
            (item) => GitHubRepositoryConnection.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on FormatException {
      throw const DevInsightApiException(
        'The connected repositories response was invalid.',
      );
    } on TypeError {
      throw const DevInsightApiException(
        'The connected repositories response was invalid.',
      );
    }
  }

  Future<GitHubRepositoryOverview> getGitHubOverview(
    String accessToken,
    String connectionId,
  ) async {
    final response = await _request(
      'GET',
      '/api/v1/github/connections/${Uri.encodeComponent(connectionId)}/overview',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not load repository information. Please retry.',
    );
    return GitHubRepositoryOverview.fromJson(_decodeObject(response));
  }

  Future<void> disconnectGitHubRepository(
    String accessToken,
    String connectionId,
  ) async {
    await _request(
      'DELETE',
      '/api/v1/github/connections/${Uri.encodeComponent(connectionId)}',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not disconnect this repository. Please try again.',
      statusMessages: const {
        404: 'This repository connection was not found. Refresh and try again.',
      },
    );
  }

  Future<GitHubRepositoryOverview> refreshGitHubRepository(
    String accessToken,
    String connectionId,
  ) async {
    final response = await _request(
      'POST',
      '/api/v1/github/connections/${Uri.encodeComponent(connectionId)}/refresh',
      accessToken: accessToken,
      failureMessage:
          'DevInsight could not refresh this repository. Please try again.',
      timeout: const Duration(seconds: 60),
      statusMessages: const {
        404: 'This repository connection could not be found.',
        429: 'GitHub is rate limiting requests. Please try again later.',
        502:
            'GitHub is temporarily unavailable. Your cached data is still available.',
      },
    );
    final body = _decodeObject(response);
    return GitHubRepositoryOverview.fromJson(
      body,
      throttled: body['throttled'] == true,
    );
  }

  Future<http.Response> _request(
    String method,
    String path, {
    required String accessToken,
    required String failureMessage,
    Duration timeout = const Duration(seconds: 15),
    Map<String, Object?>? body,
    Map<int, String> statusMessages = const {},
  }) async {
    try {
      final request = http.Request(method, Uri.parse(baseUrl).resolve(path))
        ..headers.addAll({
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401) {
        throw const DevInsightApiException('Your session has expired.');
      }
      if (response.statusCode == 409) {
        throw DevInsightApiException(_conflictMessage(response.body));
      }
      if (response.statusCode == 422) {
        throw DevInsightApiException(
          statusMessages[422] ??
              'Some submitted details are invalid. Review them and try again.',
        );
      }
      if (statusMessages.containsKey(response.statusCode)) {
        throw DevInsightApiException(statusMessages[response.statusCode]!);
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
