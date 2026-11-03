import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../Login/Widgets/social_auth_buttons.dart';

class SignUpCard extends StatefulWidget {
  final bool isCompact;
  final void Function(
    String fullName,
    String username,
    String email,
    String password,
  )?
  onSignUp;
  final VoidCallback? onGithubSignUp;
  final VoidCallback? onGoogleSignUp;
  final VoidCallback? onMicrosoftSignUp;

  const SignUpCard({
    super.key,
    this.isCompact = false,
    this.onSignUp,
    this.onGithubSignUp,
    this.onGoogleSignUp,
    this.onMicrosoftSignUp,
  });

  @override
  State<SignUpCard> createState() => _SignUpCardState();
}

class _SignUpCardState extends State<SignUpCard> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isActionHovered = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the Terms of Service and Privacy Policy',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      widget.onSignUp?.call(
        _fullNameController.text.trim(),
        _usernameController.text.trim(),
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
    final horizontalPadding = widget.isCompact ? 22.0 : 42.0;
    final verticalPadding = widget.isCompact ? 26.0 : 40.0;

    return Container(
      width: widget.isCompact ? double.infinity : 520,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primaryBlue, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 30,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title & Subtitle (Left aligned like Figma)
            Text(
              'Sign Up',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0F172A),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your DevInsight account',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 28),

            // Row 1: Full Name & Username (2 columns on wide, stacked on compact)
            if (widget.isCompact) ...[
              _buildField(
                controller: _fullNameController,
                hintText: 'Full Name',
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter full name'
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _usernameController,
                hintText: 'Username',
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter username' : null,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _fullNameController,
                      hintText: 'Full Name',
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter full name'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildField(
                      controller: _usernameController,
                      hintText: 'Username',
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter username'
                          : null,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Row 2: Email Address (Full Width)
            _buildField(
              controller: _emailController,
              hintText: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Enter email address';
                if (!val.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Row 3: Password & Confirm Password (2 columns on wide, stacked on compact)
            if (widget.isCompact) ...[
              _buildField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 19,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (val) =>
                    (val == null || val.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 19,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (val) => val != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF64748B),
                          size: 19,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (val) => (val == null || val.length < 6)
                          ? 'Min 6 characters'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF64748B),
                          size: 19,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (val) => val != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            // Terms of Service & Privacy Policy Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _agreeToTerms,
                    activeColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    onChanged: (val) =>
                        setState(() => _agreeToTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'I agree to the ',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Terms of Service',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        ' and ',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Outlined Pill Button: Create Account (exactly as Figma)
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
                              'Create Account',
                              style: GoogleFonts.plusJakartaSans(
                                color: _isActionHovered
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

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

            const SizedBox(height: 20),

            // Social Buttons (GitHub, Google, Microsoft)
            SocialAuthButtons(
              onGithub: widget.onGithubSignUp,
              onGoogle: widget.onGoogleSignUp,
              onMicrosoft: widget.onMicrosoftSignUp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
        prefixIcon: const Icon(
          Icons.person_outline_rounded,
          color: Color(0xFF64748B),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
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
