import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/auth/auth_page_shell.dart';
import '../../../Login/Pages/Login.dart';
import '../../../Login/Widgets/modern_auth_card.dart';
import '../../../onboarding/presentation/pages/onboarding_flow_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
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

  void _showNotice(String message, {bool isError = false}) {
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: ModernAuthCard(
        initialMode: AuthMode.signUp,
        onNavigateBack: _navigateBackToLanding,
        onModeChanged: (mode) {
          if (mode == AuthMode.logIn) {
            Navigator.of(context).pushReplacement(
              _pageRoute(LoginPage(themeController: widget.themeController)),
            );
          }
        },
        onSignUp: (firstName, lastName, email, password) {
          Navigator.of(context).pushReplacement(
            _pageRoute(
              OnboardingFlowPage(
                initialName: '$firstName $lastName',
                initialEmail: email,
              ),
            ),
          );
        },
        onLogIn: (email, password) {
          _showNotice(
            'Authentication is not connected yet. No account was signed in.',
            isError: true,
          );
        },
        onForgotPassword: () {
          _showNotice('Password reset link sent to your email.');
        },
        onGoogleAuth: () => _showNotice('Google sign-in not yet configured.'),
        onFacebookAuth: () =>
            _showNotice('Facebook sign-in not yet configured.'),
        onAppleAuth: () => _showNotice('Apple sign-in not yet configured.'),
        onGithubAuth: () => _showNotice('GitHub sign-in not yet configured.'),
      ),
    );
  }
}
