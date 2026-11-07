import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/auth/presentation/pages/auth_destination_page.dart';
import 'package:web_dashboard/features/onboarding/presentation/pages/onboarding_flow_page.dart';

class AuthNavigation {
  const AuthNavigation._();

  static Future<void> replaceFromProfile(
    BuildContext context,
    CurrentUserProfile profile,
  ) async {
    await replaceFromDestination(
      context,
      profile.nextStep,
      fullName: profile.fullName,
      email: profile.email,
    );
  }

  static Future<void> replaceFromDestination(
    BuildContext context,
    String nextStep, {
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
        destination = const AuthDestinationPage(
          title: 'Developer Home',
          description:
              'Your account is signed in. The Developer workspace is a temporary placeholder and will be added in a later step.',
        );
      case 'manager_home':
        destination = const AuthDestinationPage(
          title: 'Project Manager Home',
          description:
              'Your account is signed in. The Project Manager workspace is a temporary placeholder and will be added in a later step.',
        );
      default:
        throw const DevInsightApiException(
          'DevInsight returned an unsupported account destination.',
        );
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: child,
            ),
      ),
      (route) => false,
    );
  }

  static OnboardingFlowPage _onboardingPage(
    String? fullName,
    String? email,
    int step,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
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
