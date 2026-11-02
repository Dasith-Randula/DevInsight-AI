import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../Login/Widgets/charming_auth_background.dart';
import '../../../Login/Widgets/modern_auth_card.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  void _navigateToLanding() {
    Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
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
        backgroundColor:
            isError ? const Color(0xFFEF4444) : AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CharmingAuthBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Center Content: Modern Auth Card
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 48,
                    ),
                    child: ModernAuthCard(
                      initialMode: AuthMode.signUp,
                      onModeChanged: (mode) {
                        if (mode == AuthMode.logIn) {
                          // User clicked 'Log In' in the segmented switcher
                        }
                      },
                      onSignUp: (firstName, lastName, email, password) {
                        _showNotice('Welcome $firstName $lastName! Account created.');
                        Future.delayed(const Duration(milliseconds: 900), _navigateToLogin);
                      },
                      onLogIn: (email, password) {
                        _showNotice('Signing in as $email...');
                      },
                      onForgotPassword: () {
                        _showNotice('Password reset link sent to your email.');
                      },
                      onGoogleAuth: () => _showNotice('Connecting with Google...'),
                      onFacebookAuth: () => _showNotice('Connecting with Facebook...'),
                      onAppleAuth: () => _showNotice('Connecting with Apple...'),
                      onGithubAuth: () => _showNotice('Connecting with GitHub...'),
                    ),
                  ),
                ),
              ),

              // 2. Back to Home Button (Placed on top of the stack so clicks are never intercepted)
              Positioned(
                top: 20,
                left: 24,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _navigateToLanding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 17,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Home',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF475569),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

