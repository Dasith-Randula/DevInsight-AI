// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/auth/auth_page_shell.dart';
import '../../signup/presentation/pages/signup_page.dart';
import '../Widgets/modern_auth_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  void _navigateToLanding() {
    Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
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
      onNavigateHome: _navigateToLanding,
      child: ModernAuthCard(
        initialMode: AuthMode.logIn,
        onModeChanged: (mode) {
          if (mode == AuthMode.signUp) {
            Navigator.of(context).pushReplacement(_pageRoute(const SignUpPage()));
          }
        },
        onLogIn: (email, password) {
          _showNotice('Signing in as $email…');
        },
        onSignUp: (firstName, lastName, email, password) {
          _showNotice('Account created for $firstName $lastName! Please sign in.');
        },
        onForgotPassword: () {
          _showNotice('Password reset link sent to your email.');
        },
        onGoogleAuth: () => _showNotice('Google sign-in not yet configured.', isError: false),
        onFacebookAuth: () => _showNotice('Facebook sign-in not yet configured.', isError: false),
        onAppleAuth: () => _showNotice('Apple sign-in not yet configured.', isError: false),
        onGithubAuth: () => _showNotice('GitHub sign-in not yet configured.', isError: false),
      ),
    );
  }
}
