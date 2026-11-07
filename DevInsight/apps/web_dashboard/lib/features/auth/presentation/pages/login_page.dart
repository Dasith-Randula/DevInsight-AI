// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';
import 'package:web_dashboard/core/services/auth_service.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/theme_controller.dart';
import 'package:web_dashboard/features/auth/presentation/auth_navigation.dart';
import 'package:web_dashboard/features/auth/presentation/pages/signup_page.dart';
import 'package:web_dashboard/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:web_dashboard/features/auth/presentation/widgets/modern_auth_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Route<dynamic> _pageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  void _navigateBackToLanding() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil('/landing', (route) => false);
    }
  }

  void _showNotice(
    String message, {
    bool isError = false,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primaryBlue,
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _routeCurrentUser() async {
    try {
      final profile = await AuthService().fetchCurrentProfile();
      if (mounted) {
        await AuthNavigation.replaceFromProfile(context, profile);
      }
    } on AuthIntegrationException catch (error) {
      _showNotice(error.message, isError: true, onRetry: _routeCurrentUser);
    } on DevInsightApiException catch (error) {
      _showNotice(error.message, isError: true, onRetry: _routeCurrentUser);
    }
  }

  Future<void> _signIn(String email, String password) async {
    try {
      final authService = AuthService();
      await authService.signIn(email: email, password: password);
      await _routeCurrentUser();
    } on AuthIntegrationException catch (error) {
      _showNotice(error.message, isError: true);
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (email.isEmpty) {
      _showNotice('Enter your email address first.', isError: true);
      return;
    }
    try {
      await AuthService().sendPasswordReset(email);
      _showNotice('If the account exists, a password reset email was sent.');
    } on AuthIntegrationException catch (error) {
      _showNotice(error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: ModernAuthCard(
        initialMode: AuthMode.logIn,
        onNavigateBack: _navigateBackToLanding,
        onModeChanged: (mode) {
          if (mode == AuthMode.signUp) {
            Navigator.of(context).pushReplacement(
              _pageRoute(SignUpPage(themeController: widget.themeController)),
            );
          }
        },
        onLogIn: _signIn,
        onForgotPassword: _sendPasswordReset,
        onGoogleAuth: () =>
            _showNotice('Google sign-in not yet configured.', isError: false),
        onFacebookAuth: () =>
            _showNotice('Facebook sign-in not yet configured.', isError: false),
        onAppleAuth: () =>
            _showNotice('Apple sign-in not yet configured.', isError: false),
        onGithubAuth: () =>
            _showNotice('GitHub sign-in not yet configured.', isError: false),
      ),
    );
  }
}
