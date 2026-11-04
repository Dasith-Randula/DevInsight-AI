import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';

import 'social_auth_buttons.dart';

class LoginCard extends StatefulWidget {
  final bool isCompact;
  final VoidCallback? onForgotPassword;
  final void Function(String email, String password)? onSignIn;
  final VoidCallback? onSignUp;
  final VoidCallback? onGithubSignIn;
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onMicrosoftSignIn;

  const LoginCard({
    super.key,
    this.isCompact = false,
    this.onForgotPassword,
    this.onSignIn,
    this.onSignUp,
    this.onGithubSignIn,
    this.onGoogleSignIn,
    this.onMicrosoftSignIn,
  });

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isActionHovered = false;
  bool _isForgotHovered = false;
  bool _isSignUpHovered = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      widget.onSignIn?.call(
        _emailController.text.trim(),
        _passwordController.text,
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = widget.isCompact ? 24.0 : 44.0;
    final verticalPadding = widget.isCompact ? 28.0 : 42.0;

    return Container(
      width: widget.isCompact ? double.infinity : 490,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Title & Subtitle (Clean & Faithful to Design)
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0F172A),
                fontSize: 31,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to continue to DevInsight',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 32),

            // Email or Username Input Field
            _buildInputField(
              controller: _emailController,
              hintText: 'Email or Username',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your email or username';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Password Input Field
            _buildInputField(
              controller: _passwordController,
              hintText: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),

            // Forgot Password Link (aligned right)
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isForgotHovered = true),
                onExit: (_) => setState(() => _isForgotHovered = false),
                child: GestureDetector(
                  onTap: widget.onForgotPassword,
                  child: Text(
                    'Forgot Password ?',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: _isForgotHovered
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            // Primary Action Button (Sign in) - Clean Pill with Smooth Hover
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isActionHovered = true),
              onExit: (_) => setState(() => _isActionHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _isActionHovered
                      ? AppColors.primaryBlue
                      : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primaryBlue, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(
                        alpha: _isActionHovered ? 0.30 : 0.10,
                      ),
                      blurRadius: _isActionHovered ? 18 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: _isLoading ? null : _handleSubmit,
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: _isActionHovered
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                              ),
                            )
                          : Text(
                              'Sign in',
                              style: GoogleFonts.plusJakartaSans(
                                color: _isActionHovered
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Divider: "Or continue with"
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFE2E8F0)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'Or continue with',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFE2E8F0)),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Social Buttons (GitHub, Google, Microsoft)
            SocialAuthButtons(
              onGithub: widget.onGithubSignIn,
              onGoogle: widget.onGoogleSignIn,
              onMicrosoft: widget.onMicrosoftSignIn,
            ),

            const SizedBox(height: 28),

            // Bottom Switcher Prompt: "Don't have an account ? Sign Up"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account ? ",
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1E293B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isSignUpHovered = true),
                  onExit: (_) => setState(() => _isSignUpHovered = false),
                  child: GestureDetector(
                    onTap: widget.onSignUp,
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration: _isSignUpHovered
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF0F172A),
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFBFDFF),
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 21),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
    );
  }
}
