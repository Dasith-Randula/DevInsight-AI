import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_dashboard/core/config/app_config.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/auth/presentation/pages/auth_destination_page.dart';
import 'package:web_dashboard/features/onboarding/presentation/pages/onboarding_flow_page.dart';

class AuthNavigation {
  const AuthNavigation._();

  static const authenticatedRoute = '/auth';

  static Future<void> replaceFromProfile(
    BuildContext context,
    CurrentUserProfile profile,
  ) async {
    await replaceFromDestination(
      context,
      profile.nextStep,
      profile: profile,
      fullName: profile.fullName,
      email: profile.email,
    );
  }

  static Future<void> replaceFromDestination(
    BuildContext context,
    String nextStep, {
    CurrentUserProfile? profile,
    String? fullName,
    String? email,
  }) async {
    final Widget destination;
    switch (nextStep) {
      case 'profile':
        destination = _onboardingPage(fullName, email, 0);
      case 'preferences':
        destination = _onboardingPage(fullName, email, 1);
      case 'notifications':
        destination = _onboardingPage(fullName, email, 2);
      case 'complete':
        destination = _onboardingPage(fullName, email, 2);
      case 'developer_home':
        destination = AuthDestinationPage(
          title: 'Developer Home',
          description:
              'Your account is signed in. Your personalized DevInsight workspace is ready.',
          profile:
              profile ??
              CurrentUserProfile(
                id: '',
                nextStep: 'developer_home',
                fullName: fullName ?? 'Developer',
                email: email,
                role: 'Developer',
              ),
        );
      case 'manager_home':
        destination = AuthDestinationPage(
          title: 'Project Manager Home',
          description:
              'Your account is signed in. Your project workspace is ready for review and delivery planning.',
          profile:
              profile ??
              CurrentUserProfile(
                id: '',
                nextStep: 'manager_home',
                fullName: fullName ?? 'Project Manager',
                email: email,
                role: 'Project Manager',
              ),
        );
      default:
        throw const DevInsightApiException(
          'DevInsight returned an unsupported account destination.',
        );
    }

    if (!context.mounted) return;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Navigator.of(context).pushAndRemoveUntil<void>(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: authenticatedRoute),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: Duration(milliseconds: reducedMotion ? 180 : 550),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final progress = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: progress,
            child: reducedMotion
                ? child
                : SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.012),
                      end: Offset.zero,
                    ).animate(progress),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.992,
                        end: 1,
                      ).animate(progress),
                      child: child,
                    ),
                  ),
          );
        },
      ),
      (route) => false,
    );
  }

  static OnboardingFlowPage _onboardingPage(
    String? fullName,
    String? email,
    int step,
  ) {
    final user = AppConfig.hasSupabaseConfig
        ? Supabase.instance.client.auth.currentUser
        : null;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final metadataName = [
      metadata['first_name'],
      metadata['last_name'],
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return OnboardingFlowPage(
      initialName: fullName ?? metadataName,
      initialEmail: email ?? user?.email ?? '',
      initialStep: step,
    );
  }
}
