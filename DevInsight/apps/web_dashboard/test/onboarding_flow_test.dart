import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/onboarding/presentation/pages/onboarding_flow_page.dart';

void main() {
  testWidgets('resumes saved step and preserves values while going back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authService = _SavedStateAuthService(
      OnboardingState(
        profile: const OnboardingProfileData(
          id: 'user-id',
          fullName: 'Test User',
          username: 'testuser',
          organization: 'DevInsight',
          jobTitle: 'Engineer',
          role: 'developer',
          onboardingStep: 3,
          onboardingCompleted: false,
        ),
        nextStep: 'complete',
        interests: const ['AI Recommendations'],
        emailEnabled: true,
        pushEnabled: false,
        notificationTopics: const ['Project Updates'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingFlowPage(
          initialEmail: 'test@example.com',
          authService: authService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stay Informed, Your Way'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Make DevInsight Work for You'), findsOneWidget);
    expect(
      find.text('1 selected · select as many as you like'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text("Let's Set Up Your Profile"), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.first.controller?.text, 'Test User');
    expect(fields.elementAt(1).controller?.text, 'testuser');
    expect(fields.elementAt(2).controller?.text, 'test@example.com');
  });
}

class _SavedStateAuthService extends AuthService {
  _SavedStateAuthService(this.state);

  final OnboardingState state;

  @override
  Future<OnboardingState> fetchOnboardingState() async => state;
}
