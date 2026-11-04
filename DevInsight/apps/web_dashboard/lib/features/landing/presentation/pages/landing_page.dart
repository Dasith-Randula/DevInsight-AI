import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/features/auth/presentation/pages/login_page.dart';
import 'package:web_dashboard/features/auth/presentation/pages/signup_page.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../sections/about_section.dart';
import '../sections/cta_section.dart';
import '../sections/features_section.dart';
import '../sections/how_it_works_section.dart';
import '../sections/landing_footer.dart';
import '../sections/research_section.dart';
import '../widgets/app_background.dart';
import '../widgets/landing_hero.dart';
import '../widgets/landing_style.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final _heroKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _researchKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _ctaKey = GlobalKey();
  late final List<GlobalKey> _sectionKeys = [
    _heroKey,
    _featuresKey,
    _howItWorksKey,
    _researchKey,
    _aboutKey,
  ];
  int _activeSection = 0;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final scrolled = _scrollController.offset > 12;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }

    var active = 0;
    for (var index = _sectionKeys.length - 1; index > 0; index--) {
      final renderObject = _sectionKeys[index].currentContext
          ?.findRenderObject();
      if (renderObject is RenderBox &&
          renderObject.localToGlobal(Offset.zero).dy <= 160) {
        active = index;
        break;
      }
    }
    if (active != _activeSection) {
      setState(() => _activeSection = active);
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  Route<void> _authRoute(Widget page, String routeName) =>
      PageRouteBuilder<void>(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: child,
            ),
      );

  void _openSignIn() {
    Navigator.of(context).push(
      _authRoute(LoginPage(themeController: widget.themeController), '/login'),
    );
  }

  void _openSignUp() {
    Navigator.of(context).push(
      _authRoute(
        SignUpPage(themeController: widget.themeController),
        '/signup',
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: LandingHero(
                    key: _heroKey,
                    height: viewportHeight < 720 ? 720 : viewportHeight,
                    onGetStarted: _openSignUp,
                    onSignIn: _openSignIn,
                  ),
                ),
                SliverToBoxAdapter(
                  child: FeaturesSection(
                    key: _featuresKey,
                    scrollController: _scrollController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: HowItWorksSection(
                    key: _howItWorksKey,
                    scrollController: _scrollController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ResearchSection(
                    key: _researchKey,
                    scrollController: _scrollController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: AboutSection(
                    key: _aboutKey,
                    scrollController: _scrollController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: CtaSection(
                    key: _ctaKey,
                    scrollController: _scrollController,
                    onGetStarted: _openSignUp,
                    onSignIn: _openSignIn,
                  ),
                ),
                SliverToBoxAdapter(
                  child: LandingFooter(
                    onFeatures: () => _scrollTo(_featuresKey),
                    onHowItWorks: () => _scrollTo(_howItWorksKey),
                    onResearch: () => _scrollTo(_researchKey),
                    onAbout: () => _scrollTo(_aboutKey),
                    onSignIn: _openSignIn,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _LandingNavbar(
                isScrolled: _isScrolled,
                activeSection: _activeSection,
                themeController: widget.themeController,
                onHome: () => _scrollTo(_heroKey),
                onFeatures: () => _scrollTo(_featuresKey),
                onHowItWorks: () => _scrollTo(_howItWorksKey),
                onResearch: () => _scrollTo(_researchKey),
                onAbout: () => _scrollTo(_aboutKey),
                onSignIn: _openSignIn,
                onGetStarted: _openSignUp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingNavbar extends StatelessWidget {
  const _LandingNavbar({
    required this.isScrolled,
    required this.activeSection,
    required this.themeController,
    required this.onHome,
    required this.onFeatures,
    required this.onHowItWorks,
    required this.onResearch,
    required this.onAbout,
    required this.onSignIn,
    required this.onGetStarted,
  });

  final bool isScrolled;
  final int activeSection;
  final ThemeController? themeController;
  final VoidCallback onHome;
  final VoidCallback onFeatures;
  final VoidCallback onHowItWorks;
  final VoidCallback onResearch;
  final VoidCallback onAbout;
  final VoidCallback onSignIn;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 1040;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isScrolled && !isDark ? LandingColors.ink : Colors.white;
    final links = <(String, int, VoidCallback)>[
      ('Features', 1, onFeatures),
      ('How It Works', 2, onHowItWorks),
      ('Research', 3, onResearch),
      ('About Us', 4, onAbout),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 16 : 0,
          sigmaY: isScrolled ? 16 : 0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 76,
          decoration: BoxDecoration(
            color: isScrolled
                ? (isDark ? const Color(0xC0101930) : const Color(0xC0FFFFFF))
                : Colors.transparent,
            border: isScrolled
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : LandingColors.border.withValues(alpha: 0.7),
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * (isMobile ? 0.035 : 0.06),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Row(
                        children: [
                          _Brand(onTap: onHome, color: foreground),
                          const Spacer(),
                          if (!isMobile)
                            TextButton(
                              onPressed: onSignIn,
                              style: TextButton.styleFrom(
                                foregroundColor: foreground,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Sign In'),
                            ),
                          if (themeController != null) ...[
                            const SizedBox(width: 16),
                            ThemeToggleButton(controller: themeController!),
                            const SizedBox(width: 16),
                          ] else
                            const SizedBox(width: 16),
                          _NavbarButton(
                            label: isMobile ? 'Start' : 'Get Started',
                            onPressed: onGetStarted,
                          ),
                          if (isMobile) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Open navigation',
                              onPressed: () => _showMobileMenu(context, links),
                              icon: Icon(Icons.menu_rounded, color: foreground),
                            ),
                          ],
                        ],
                      ),
                      if (!isMobile)
                        Positioned.fill(
                          left: 190,
                          right: 295,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final link in links)
                                  _NavLink(
                                    title: link.$1,
                                    active: activeSection == link.$2,
                                    foreground: foreground,
                                    onTap: link.$3,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileMenu(
    BuildContext context,
    List<(String, int, VoidCallback)> links,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final link in links)
                ListTile(
                  title: Text(link.$1),
                  onTap: () {
                    Navigator.pop(context);
                    link.$3();
                  },
                ),
              ListTile(
                title: const Text('Sign In'),
                onTap: () {
                  Navigator.pop(context);
                  onSignIn();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.onTap, required this.color});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(AppAssets.devInsightLogo, width: 36, height: 36),
        const SizedBox(width: 9),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Dev',
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'Insight',
                style: GoogleFonts.plusJakartaSans(
                  color: color == Colors.white
                      ? LandingColors.sky
                      : LandingColors.royalBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.title,
    required this.active,
    required this.foreground,
    required this.onTap,
  });

  final String title;
  final bool active;
  final Color foreground;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: TextButton(
      onPressed: widget.onTap,
      style: TextButton.styleFrom(
        foregroundColor: widget.foreground,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 160),
        style: GoogleFonts.plusJakartaSans(
          color: widget.active || _hovered
              ? (widget.foreground == Colors.white
                    ? LandingColors.sky
                    : LandingColors.royalBlue)
              : widget.foreground,
          fontSize: 13.5,
          fontWeight: widget.active || _hovered
              ? FontWeight.w700
              : FontWeight.w500,
        ),
        child: Text(widget.title),
      ),
    ),
  );
}

class _NavbarButton extends StatelessWidget {
  const _NavbarButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: LandingColors.royalBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      ),
    ),
    child: Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
  );
}
