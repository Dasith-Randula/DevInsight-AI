import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_dashboard/core/config/app_config.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';

class AuthIntegrationException implements Exception {
  const AuthIntegrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SignUpResult {
  const SignUpResult({required this.needsEmailConfirmation});

  final bool needsEmailConfirmation;
}

class AuthService {
  AuthService({DevInsightApi? api}) : _api = api ?? _defaultApi;

  static final _defaultApi = DevInsightApi(baseUrl: AppConfig.apiBaseUrl);

  final DevInsightApi _api;

  SupabaseClient get _supabase {
    if (!AppConfig.hasSupabaseConfig) {
      throw const AuthIntegrationException(
        'Authentication is not configured for this build.',
      );
    }
    return Supabase.instance.client;
  }

  bool get hasSession =>
      AppConfig.hasSupabaseConfig &&
      Supabase.instance.client.auth.currentSession != null;

  Future<SignUpResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _authRedirectUrl,
        data: {'first_name': firstName, 'last_name': lastName},
      );
      return SignUpResult(needsEmailConfirmation: response.session == null);
    } on AuthException catch (error) {
      throw AuthIntegrationException(_safeAuthMessage(error));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw const AuthIntegrationException(
          'Please verify your email address before signing in.',
        );
      }
    } on AuthIntegrationException {
      rethrow;
    } on AuthException catch (error) {
      throw AuthIntegrationException(_safeAuthMessage(error));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _authRedirectUrl,
      );
    } on AuthException catch (error) {
      throw AuthIntegrationException(_safeAuthMessage(error));
    }
  }

  Future<CurrentUserProfile?> restoreProfile() async {
    if (!hasSession) return null;
    return fetchCurrentProfile();
  }

  Future<CurrentUserProfile> fetchCurrentProfile() async {
    return withSession(_api.getCurrentUser);
  }

  Future<OnboardingState> fetchOnboardingState() async {
    return withSession(_api.getOnboardingState);
  }

  Future<void> saveOnboardingProfile({
    required String fullName,
    required String username,
    required String? organization,
    required String? jobTitle,
    required String role,
  }) {
    return withSession(
      (token) => _api.saveProfile(
        token,
        fullName: fullName,
        username: username,
        organization: organization,
        jobTitle: jobTitle,
        role: role,
      ),
    );
  }

  Future<void> saveOnboardingPreferences(List<String> interests) {
    return withSession((token) => _api.savePreferences(token, interests));
  }

  Future<void> saveOnboardingNotifications({
    required bool emailEnabled,
    required bool pushEnabled,
    required List<String> topics,
  }) {
    return withSession(
      (token) => _api.saveNotifications(
        token,
        emailEnabled: emailEnabled,
        pushEnabled: pushEnabled,
        topics: topics,
      ),
    );
  }

  Future<OnboardingCompletion> completeOnboarding() {
    return withSession(_api.completeOnboarding);
  }

  Future<T> withSession<T>(
    Future<T> Function(String accessToken) request,
  ) async {
    final auth = _supabase.auth;
    final session = auth.currentSession;
    if (session == null) {
      throw const AuthIntegrationException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      return await request(session.accessToken);
    } on DevInsightApiException catch (error) {
      if (error.message != 'Your session has expired.') rethrow;
    }

    Session? refreshedSession;
    try {
      refreshedSession = (await auth.refreshSession()).session;
    } on AuthException {
      refreshedSession = null;
    }
    if (refreshedSession == null) {
      await auth.signOut(scope: SignOutScope.local);
      throw const AuthIntegrationException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      return await request(refreshedSession.accessToken);
    } on DevInsightApiException catch (error) {
      if (error.message == 'Your session has expired.') {
        await auth.signOut(scope: SignOutScope.local);
        throw const AuthIntegrationException(
          'Your session has expired. Please sign in again.',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } on AuthException {
      throw const AuthIntegrationException(
        'Could not sign out. Please try again.',
      );
    }
  }

  String _safeAuthMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed')) {
      return 'Please verify your email address using the link we sent before signing in.';
    }
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'Email or password is incorrect.';
    }
    if (message.contains('already registered') ||
        message.contains('user_already_exists')) {
      return 'An account may already exist for this email. Try signing in or resetting your password.';
    }
    return 'Authentication could not be completed. Please try again.';
  }

  String? get _authRedirectUrl {
    if (AppConfig.authRedirectUrl.isNotEmpty) {
      return AppConfig.authRedirectUrl;
    }
    return kIsWeb ? Uri.base.origin : null;
  }
}
