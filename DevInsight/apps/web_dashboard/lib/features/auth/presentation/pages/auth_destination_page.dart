import 'package:flutter/material.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/features/developer/presentation/pages/developer_home_page.dart';

class AuthDestinationPage extends StatelessWidget {
  const AuthDestinationPage({
    super.key,
    required this.title,
    required this.description,
    this.profile,
  });

  final String title;
  final String description;
  final CurrentUserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final userProfile =
        profile ??
        const CurrentUserProfile(
          id: '',
          nextStep: 'developer_home',
          fullName: 'Developer',
          role: 'Developer',
        );

    if (title.toLowerCase().contains('developer')) {
      return DeveloperHomePage(profile: userProfile);
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
