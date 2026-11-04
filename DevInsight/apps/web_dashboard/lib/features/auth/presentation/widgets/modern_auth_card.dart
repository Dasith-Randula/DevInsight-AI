import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/constants/app_colors.dart';
import 'package:web_dashboard/features/auth/presentation/widgets/auth_brand_panel.dart';
import 'package:web_dashboard/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:web_dashboard/features/auth/presentation/widgets/auth_text_field.dart';

// Re-export enum so Login.dart and signup_page.dart don't need changes.
enum AuthMode { signUp, logIn }

/// The main authentication card widget.
///
/// Renders a split two-column layout on desktop (≥960px) and a single-column
/// stacked layout on mobile. Uses the shared auth branding and form widgets.
///
/// All animation controllers are disposed in [State.dispose].
class ModernAuthCard extends StatefulWidget {
  final AuthMode initialMode;
  final ValueChanged<AuthMode>? onModeChanged;
  final VoidCallback? onNavigateBack;
  final void Function(String, String, String, String)? onSignUp;
  final void Function(String, String)? onLogIn;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onGoogleAuth;
  final VoidCallback? onFacebookAuth;
  final VoidCallback? onAppleAuth;
  final VoidCallback? onGithubAuth;

  const ModernAuthCard({
    super.key,
    this.initialMode = AuthMode.logIn,
    this.onModeChanged,
    this.onNavigateBack,
    this.onSignUp,
    this.onLogIn,
    this.onForgotPassword,
    this.onGoogleAuth,
    this.onFacebookAuth,
    this.onAppleAuth,
    this.onGithubAuth,
  });

  @override
  State<ModernAuthCard> createState() => _ModernAuthCardState();
}

class _ModernAuthCardState extends State<ModernAuthCard>
    with SingleTickerProviderStateMixin {
  late AuthMode _mode;

  // Form keys
  final _signUpKey = GlobalKey<FormState>();
  final _logInKey = GlobalKey<FormState>();

  // Sign-up controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPassCtrl = TextEditingController();
  final _signUpConfirmCtrl = TextEditingController();

  // Log-in controllers
  final _logInEmailCtrl = TextEditingController();
  final _logInPassCtrl = TextEditingController();

  // Visibility toggles
  bool _obscureSignUpPass = true;
  bool _obscureSignUpConfirm = true;
  bool _obscureLogInPass = true;

  bool _isForgotHovered = false;
  bool _isLoading = false;

  // Stagger animation
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _staggerFades;
  late final List<Animation<Offset>> _staggerSlides;
  bool _staggerDone = false;

  static const int _staggerItemCount =
      6; // switcher, heading, sub, fields, btn, social
  static const Duration _staggerItemDuration = Duration(milliseconds: 180);
  static const int _staggerOffsetMs = 70;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            _staggerOffsetMs * _staggerItemCount +
            _staggerItemDuration.inMilliseconds,
      ),
    );

    _staggerFades = List.generate(_staggerItemCount, (i) {
      final start =
          (_staggerOffsetMs * i) / _staggerCtrl.duration!.inMilliseconds;
      final end =
          start +
          _staggerItemDuration.inMilliseconds /
              _staggerCtrl.duration!.inMilliseconds;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });

    _staggerSlides = List.generate(_staggerItemCount, (i) {
      final start =
          (_staggerOffsetMs * i) / _staggerCtrl.duration!.inMilliseconds;
      final end =
          start +
          _staggerItemDuration.inMilliseconds /
              _staggerCtrl.duration!.inMilliseconds;
      return Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_staggerDone) {
        _staggerCtrl.forward().then((_) {
          if (mounted) setState(() => _staggerDone = true);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ModernAuthCard old) {
    super.didUpdateWidget(old);
    if (old.initialMode != widget.initialMode) {
      setState(() => _mode = widget.initialMode);
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPassCtrl.dispose();
    _signUpConfirmCtrl.dispose();
    _logInEmailCtrl.dispose();
    _logInPassCtrl.dispose();
    super.dispose();
  }

  void _switchMode(bool toSignUp) {
    final newMode = toSignUp ? AuthMode.signUp : AuthMode.logIn;
    if (_mode == newMode) return;
    setState(() => _mode = newMode);
    widget.onModeChanged?.call(newMode);
  }

  Future<void> _handleSignUp() async {
    if (_signUpKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      widget.onSignUp?.call(
        _firstNameCtrl.text.trim(),
        _lastNameCtrl.text.trim(),
        _signUpEmailCtrl.text.trim(),
        _signUpPassCtrl.text,
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogIn() async {
    if (_logInKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      widget.onLogIn?.call(_logInEmailCtrl.text.trim(), _logInPassCtrl.text);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _staggerItem(int index, Widget child) {
    if (_staggerDone) return child;
    return FadeTransition(
      opacity: _staggerFades[index],
      child: SlideTransition(position: _staggerSlides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFFDCE7F5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF173B75).withValues(alpha: 0.13),
                blurRadius: 56,
                offset: const Offset(0, 24),
              ),
              BoxShadow(
                color: const Color(0xFF173B75).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop: two columns
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 52, child: AuthBrandPanel(isCompact: false)),
          Expanded(flex: 48, child: _buildFormPanel(isCompact: false)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile / Tablet: stacked
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthBrandPanel(isCompact: true),
        _buildFormPanel(isCompact: true),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Form panel (right column or stacked below brand)
  // ---------------------------------------------------------------------------
  Widget _buildFormPanel({required bool isCompact}) {
    final hPad = isCompact ? 22.0 : 52.0;
    final vPad = isCompact ? 24.0 : 38.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: _buildBackButton()),

          SizedBox(height: isCompact ? 24 : 34),

          // 1. Heading (animates on mode change)
          _staggerItem(
            0,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Column(
                key: ValueKey<AuthMode>(_mode),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _mode == AuthMode.signUp
                        ? 'Create Your Account'
                        : 'Welcome Back',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.authText,
                      fontSize: isCompact ? 28 : 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mode == AuthMode.signUp
                        ? 'Start making smarter software project decisions.'
                        : 'Sign in to continue your DevInsight experience.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.authSecondaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 2. Form fields (staggered, with AnimatedSwitcher for mode swap)
          _staggerItem(
            1,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(anim);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _mode == AuthMode.signUp
                  ? _buildSignUpFields(
                      key: const ValueKey('signUp'),
                      isCompact: isCompact,
                    )
                  : _buildLogInFields(
                      key: const ValueKey('logIn'),
                      isCompact: isCompact,
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Primary button
          _staggerItem(
            2,
            Center(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width < 600
                    ? double.infinity
                    : 300,
                child: AuthPrimaryButton(
                  label: _mode == AuthMode.signUp
                      ? 'Create Account'
                      : 'Sign In',
                  isLoading: _isLoading,
                  onPressed: _isLoading
                      ? null
                      : (_mode == AuthMode.signUp
                            ? _handleSignUp
                            : _handleLogIn),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 4. Or divider + social buttons
          _staggerItem(3, _buildDivider()),
          const SizedBox(height: 14),
          _staggerItem(3, _buildSocialButtons()),

          const SizedBox(height: 18),

          // 5. Switch prompt
          _staggerItem(4, _buildSwitchPrompt()),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return OutlinedButton.icon(
      onPressed: widget.onNavigateBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 17),
      label: Text(
        'Back',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.authSecondaryText,
        side: const BorderSide(color: AppColors.authInputBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sign Up form fields
  // ---------------------------------------------------------------------------
  Widget _buildSignUpFields({Key? key, required bool isCompact}) {
    return Form(
      key: _signUpKey,
      child: Column(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: [
          // First / Last name row
          if (isCompact) ...[
            AuthTextField(
              controller: _firstNameCtrl,
              hintText: 'First Name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _lastNameCtrl,
              hintText: 'Last Name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter last name' : null,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    controller: _firstNameCtrl,
                    hintText: 'First Name',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter first name'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuthTextField(
                    controller: _lastNameCtrl,
                    hintText: 'Last Name',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter last name'
                        : null,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Email
          AuthTextField(
            controller: _signUpEmailCtrl,
            hintText: 'Email Address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email address';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Password
          AuthTextField(
            controller: _signUpPassCtrl,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureSignUpPass,
            textInputAction: TextInputAction.next,
            suffixIcon: _eyeButton(
              obscure: _obscureSignUpPass,
              onTap: () =>
                  setState(() => _obscureSignUpPass = !_obscureSignUpPass),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),

          const SizedBox(height: 12),

          // Confirm password
          AuthTextField(
            controller: _signUpConfirmCtrl,
            hintText: 'Confirm Password',
            prefixIcon: Icons.shield_outlined,
            obscureText: _obscureSignUpConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSignUp(),
            suffixIcon: _eyeButton(
              obscure: _obscureSignUpConfirm,
              onTap: () => setState(
                () => _obscureSignUpConfirm = !_obscureSignUpConfirm,
              ),
            ),
            validator: (v) =>
                v != _signUpPassCtrl.text ? 'Passwords do not match' : null,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Log In form fields
  // ---------------------------------------------------------------------------
  Widget _buildLogInFields({Key? key, required bool isCompact}) {
    return Form(
      key: _logInKey,
      child: Column(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email
          AuthTextField(
            controller: _logInEmailCtrl,
            hintText: 'Email Address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email address';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Password
          AuthTextField(
            controller: _logInPassCtrl,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureLogInPass,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogIn(),
            suffixIcon: _eyeButton(
              obscure: _obscureLogInPass,
              onTap: () =>
                  setState(() => _obscureLogInPass = !_obscureLogInPass),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password is required' : null,
          ),

          const SizedBox(height: 10),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isForgotHovered = true),
              onExit: (_) => setState(() => _isForgotHovered = false),
              child: GestureDetector(
                onTap: widget.onForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.authRoyalBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: _isForgotHovered
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: AppColors.authRoyalBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: eye icon button for password fields
  // ---------------------------------------------------------------------------
  Widget _eyeButton({required bool obscure, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 19,
        color: AppColors.authSecondaryText,
      ),
      tooltip: obscure ? 'Show password' : 'Hide password',
      onPressed: onTap,
      splashRadius: 18,
    );
  }

  // ---------------------------------------------------------------------------
  // Divider: "Or continue with"
  // ---------------------------------------------------------------------------
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.authInputBorder, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or continue with',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.authSecondaryText.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.authInputBorder, thickness: 1),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Social buttons row (Google, Facebook, Apple) — preserved callbacks
  // ---------------------------------------------------------------------------
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialBtn(
            icon: const _GoogleIcon(size: 18),
            label: 'Google',
            onTap: widget.onGoogleAuth,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialBtn(
            icon: const _FacebookIcon(size: 18),
            label: 'Facebook',
            onTap: widget.onFacebookAuth,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialBtn(
            icon: const _AppleIcon(size: 18),
            label: 'Apple',
            onTap: widget.onAppleAuth,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Switch prompt (bottom link)
  // ---------------------------------------------------------------------------
  Widget _buildSwitchPrompt() {
    final bool isSignUp = _mode == AuthMode.signUp;
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: isSignUp
                  ? 'Already have an account? '
                  : "Don't have an account? ",
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.authSecondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => _switchMode(!isSignUp),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    isSignUp ? 'Sign In' : 'Create Account',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.authRoyalBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.authRoyalBlue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Social button pill
// =============================================================================
class _SocialBtn extends StatefulWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const _SocialBtn({required this.icon, required this.label, this.onTap});

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.authRoyalBlue.withValues(alpha: 0.05)
                : AppColors.authBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.authRoyalBlue
                  : AppColors.authInputBorder,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.authRoyalBlue.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.authText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

// =============================================================================
// Inline vector icons (no external packages)
// =============================================================================

class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final sw = r * 0.38;
    final ar = r - sw / 2;
    final arc = Rect.fromCircle(center: c, radius: ar);

    void drawArc(Color color, double start, double sweep) => canvas.drawArc(
      arc,
      start,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    drawArc(const Color(0xFF4285F4), -0.65, 1.25);
    drawArc(const Color(0xFF34A853), 0.60, 1.55);
    drawArc(const Color(0xFFFBBC05), 2.15, 1.25);
    drawArc(const Color(0xFFEA4335), 3.40, 1.75);

    final barRect = Rect.fromLTRB(
      c.dx,
      c.dy - sw / 2,
      size.width,
      c.dy + sw / 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(sw / 4)),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _FacebookIcon extends StatelessWidget {
  final double size;
  const _FacebookIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'f',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: size * 0.7,
            fontWeight: FontWeight.bold,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  final double size;
  const _AppleIcon({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _ApplePainter());
}

class _ApplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.save();
    canvas.scale(s, s);
    final p = Path()
      ..moveTo(15.22, 6.27)
      ..cubicTo(16.03, 5.28, 16.57, 3.89, 16.42, 2.5)
      ..cubicTo(15.23, 2.55, 13.78, 3.3, 12.92, 4.3)
      ..cubicTo(12.18, 5.16, 11.53, 6.57, 11.71, 7.94)
      ..cubicTo(13.04, 8.04, 14.41, 7.25, 15.22, 6.27)
      ..close()
      ..moveTo(18.71, 14.04)
      ..cubicTo(18.74, 17.06, 21.36, 18.06, 21.43, 18.1)
      ..cubicTo(21.4, 18.23, 20.98, 19.67, 19.98, 21.13)
      ..cubicTo(19.11, 22.4, 18.21, 23.66, 16.78, 23.69)
      ..cubicTo(15.38, 23.71, 14.93, 22.86, 13.33, 22.86)
      ..cubicTo(11.73, 22.86, 11.23, 23.66, 9.9, 23.71)
      ..cubicTo(8.52, 23.76, 7.48, 22.36, 6.6, 21.09)
      ..cubicTo(4.81, 18.5, 3.44, 13.78, 5.28, 10.59)
      ..cubicTo(6.19, 9.01, 7.82, 8.01, 9.58, 7.98)
      ..cubicTo(10.93, 7.96, 12.21, 8.89, 13.04, 8.89)
      ..cubicTo(13.86, 8.89, 15.39, 7.78, 17.0, 7.95)
      ..cubicTo(17.68, 7.98, 19.57, 8.23, 20.78, 10.0)
      ..cubicTo(20.68, 10.06, 18.69, 11.22, 18.71, 14.04)
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.authText);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
