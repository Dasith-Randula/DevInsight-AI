import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingColors {
  const LandingColors._();

  static const royalBlue = Color(0xFF0056FF);
  static const azureBlue = Color(0xFF2277FF);
  static const ink = Color(0xFF101A34);
  static const body = Color(0xFF586681);
  static const lavender = Color(0xFFE3E7FC);
  static const background = Color(0xFFF5F8FF);
  static const border = Color(0xFFDCE7FF);
  static const sky = Color(0xFF79B8FF);
}

Color landingTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFF5F8FF)
    : LandingColors.ink;

Color landingBodyColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFB7C4DC)
    : LandingColors.body;

class LandingSectionHeading extends StatelessWidget {
  const LandingSectionHeading({
    super.key,
    required this.title,
    required this.description,
    this.eyebrow,
    this.light = false,
  });

  final String title;
  final String description;
  final String? eyebrow;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : landingTextColor(context);
    final bodyColor = light
        ? Colors.white.withValues(alpha: 0.76)
        : landingBodyColor(context);
    return Column(
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: light ? LandingColors.sky : LandingColors.royalBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: titleColor,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.18,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: bodyColor,
              fontSize: 16,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class LandingSectionFrame extends StatelessWidget {
  const LandingSectionFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 92, horizontal: 24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: child,
        ),
      ),
    );
  }
}

class LandingIconCard extends StatefulWidget {
  const LandingIconCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.horizontal = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool horizontal;

  @override
  State<LandingIconCard> createState() => _LandingIconCardState();
}

class _LandingIconCardState extends State<LandingIconCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = landingTextColor(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF121D35) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered
                ? LandingColors.royalBlue.withValues(alpha: 0.3)
                : LandingColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: LandingColors.royalBlue.withValues(
                alpha: _hovered ? 0.12 : 0.055,
              ),
              blurRadius: _hovered ? 28 : 18,
              offset: Offset(0, _hovered ? 12 : 7),
            ),
          ],
        ),
        child: widget.horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBox(icon: widget.icon),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _CardCopy(
                      title: widget.title,
                      description: widget.description,
                      textColor: textColor,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBox(icon: widget.icon),
                  const SizedBox(height: 20),
                  _CardCopy(
                    title: widget.title,
                    description: widget.description,
                    textColor: textColor,
                  ),
                ],
              ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: LandingColors.royalBlue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: LandingColors.royalBlue, size: 25),
  );
}

class _CardCopy extends StatelessWidget {
  const _CardCopy({
    required this.title,
    required this.description,
    required this.textColor,
  });

  final String title;
  final String description;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        description,
        style: GoogleFonts.plusJakartaSans(
          color: landingBodyColor(context),
          fontSize: 14.5,
          height: 1.55,
        ),
      ),
    ],
  );
}

class LandingOutlineIcon extends StatelessWidget {
  const LandingOutlineIcon({super.key, required this.icon, this.size = 20});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: LandingColors.royalBlue);
}
