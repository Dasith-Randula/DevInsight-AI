import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import 'auth_dot_surface.dart';

class AuthBrandPanel extends StatefulWidget {
  const AuthBrandPanel({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  State<AuthBrandPanel> createState() => _AuthBrandPanelState();
}

class _AuthBrandPanelState extends State<AuthBrandPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
    _cardFades = List.generate(3, (index) {
      final start = 0.38 + index * 0.16;
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          start,
          (start + 0.36).clamp(0.0, 1.0).toDouble(),
          curve: Curves.easeOut,
        ),
      );
    });
    _cardSlides = List.generate(3, (index) {
      final start = 0.38 + index * 0.16;
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(
            start,
            (start + 0.36).clamp(0.0, 1.0).toDouble(),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.authDeepBlue,
              AppColors.authAzureBlue,
              AppColors.authRoyalBlue,
            ],
            stops: [0, 0.52, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -150,
              right: -100,
              child: _AmbientGlow(size: 370, opacity: 0.2),
            ),
            const Positioned(
              bottom: -180,
              left: -150,
              child: _AmbientGlow(size: 390, opacity: 0.16),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.isCompact ? 22 : 42,
                widget.isCompact ? 18 : 34,
                widget.isCompact ? 22 : 38,
                widget.isCompact ? 18 : 30,
              ),
              child: widget.isCompact ? _buildBranding() : _buildFullPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBranding(),
        const SizedBox(height: 44),
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0, 0.46, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(0, 0.46, curve: Curves.easeOutCubic),
                  ),
                ),
            child: _buildHeading(),
          ),
        ),
        const SizedBox(height: 14),
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.13, 0.56, curve: Curves.easeOut),
          ),
          child: Text(
            'Predict risks, prioritize critical issues, and make confident software project decisions.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          height: 178,
          width: double.infinity,
          child: AuthDotSurface(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _featureCard(
              index: 0,
              icon: Icons.insights_rounded,
              title: 'Track Project Health',
              description: 'Get a clear view of project progress.',
            ),
            const SizedBox(width: 10),
            _featureCard(
              index: 1,
              icon: Icons.shield_outlined,
              title: 'Predict Delivery Risks',
              description: 'Identify potential delays early.',
            ),
            const SizedBox(width: 10),
            _featureCard(
              index: 2,
              icon: Icons.checklist_rounded,
              title: 'Prioritize Issues',
              description: 'Focus on what matters most.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Image.asset(
            AppAssets.devInsightBrandingLogo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Dev',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              TextSpan(
                text: 'Insight',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.authCyan,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    final style = GoogleFonts.plusJakartaSans(
      color: Colors.white,
      fontSize: 44,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.6,
      height: 1.1,
    );
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Engineering\n'),
          TextSpan(
            text: 'Intelligence',
            style: style.copyWith(color: AppColors.authCyan),
          ),
          const TextSpan(text: ', Made Smarter.'),
        ],
      ),
    );
  }

  Widget _featureCard({
    required int index,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Expanded(
      child: FadeTransition(
        opacity: _cardFades[index],
        child: SlideTransition(
          position: _cardSlides[index],
          child: _FeatureCard(
            icon: icon,
            title: title,
            description: description,
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 106,
        padding: const EdgeInsets.all(12),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _hovered ? 0.19 : 0.13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF071E78).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 19, color: AppColors.authCyan),
            const SizedBox(height: 7),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.authCyan.withValues(alpha: opacity),
                AppColors.authAzureBlue.withValues(alpha: opacity * 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
