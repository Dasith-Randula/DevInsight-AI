import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/liquid_glass_card.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
// CHANGED: removed animated_aura_background import, added AppBackground
import '../widgets/app_background.dart';
import '../widgets/dashboard_preview.dart';
import '../sections/about_section.dart';
import '../sections/cta_section.dart';
import '../sections/features_section.dart';
import '../sections/how_it_works_section.dart';
import '../sections/landing_footer.dart';
import '../sections/research_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final GlobalKey featuresSectionKey;
  late final GlobalKey howItWorksSectionKey;
  late final GlobalKey researchSectionKey;
  late final GlobalKey aboutSectionKey;
  late final GlobalKey ctaSectionKey;
  late final List<GlobalKey> _sectionKeys;

  final ScrollController _scrollController = ScrollController();
  int _activeSection = 0;

  @override
  void initState() {
    super.initState();
    featuresSectionKey = GlobalKey();
    howItWorksSectionKey = GlobalKey();
    researchSectionKey = GlobalKey();
    aboutSectionKey = GlobalKey();
    ctaSectionKey = GlobalKey();
    _sectionKeys = <GlobalKey>[
      GlobalKey(),
      featuresSectionKey,
      howItWorksSectionKey,
      researchSectionKey,
      aboutSectionKey,
    ];
    _scrollController.addListener(_updateActiveSection);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateActiveSection)
      ..dispose();
    super.dispose();
  }

  void _updateActiveSection() {
    for (var i = _sectionKeys.length - 1; i >= 1; i--) {
      final context = _sectionKeys[i].currentContext;
      final renderObject = context?.findRenderObject();
      if (renderObject is RenderBox &&
          renderObject.localToGlobal(Offset.zero).dy <= 120) {
        if (_activeSection != i) setState(() => _activeSection = i);
        return;
      }
    }
    if (_activeSection != 0) setState(() => _activeSection = 0);
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // CHANGED: AppBackground replaces the old Stack + AnimatedAuraBackground.
      // The background stays fixed while the CustomScrollView scrolls on top.
      body: AppBackground(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _NavbarDelegate(
                activeSection: _activeSection,
                onNavigate: (index) => _scrollTo(_sectionKeys[index]),
                themeController: widget.themeController,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _HeroSection(),
                  FeaturesSection(key: featuresSectionKey),
                  HowItWorksSection(key: howItWorksSectionKey),
                  ResearchSection(
                    key: researchSectionKey,
                    onLearnMore: () => _scrollTo(aboutSectionKey),
                  ),
                  AboutSection(key: aboutSectionKey),
                  CtaSection(
                    key: ctaSectionKey,
                    onGetStarted: () =>
                        Navigator.of(context).pushNamed('/login'),
                    onSignIn: () => Navigator.of(context).pushNamed('/login'),
                  ),
                  LandingFooter(
                    onFeatures: () => _scrollTo(featuresSectionKey),
                    onHowItWorks: () => _scrollTo(howItWorksSectionKey),
                    onResearch: () => _scrollTo(researchSectionKey),
                    onAbout: () => _scrollTo(aboutSectionKey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navbar
// ---------------------------------------------------------------------------

class _NavbarDelegate extends SliverPersistentHeaderDelegate {
  const _NavbarDelegate({
    required this.activeSection,
    required this.onNavigate,
    this.themeController,
  });

  final int activeSection;
  final ValueChanged<int> onNavigate;
  final ThemeController? themeController;

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            // CHANGED: transparent at the top (like the Figma), frosted white
            // once the page is scrolled under the navbar.
            color: (isDark ? const Color(0xFF101C32) : Colors.white).withValues(
              alpha: overlapsContent ? 0.72 : 0.0,
            ),
            border: overlapsContent
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF304562)
                          : const Color(0x88FFFFFF),
                      width: 1,
                    ),
                  )
                : null,
            boxShadow: overlapsContent
                ? [
                    const BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            height: 72,
            child: SafeArea(
              bottom: false,
              child: _LandingNav(
                activeSection: activeSection,
                onNavigate: onNavigate,
                themeController: themeController,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_NavbarDelegate oldDelegate) =>
      oldDelegate.activeSection != activeSection;
}

class _LandingNav extends StatelessWidget {
  const _LandingNav({
    required this.activeSection,
    required this.onNavigate,
    this.themeController,
  });

  final int activeSection;
  final ValueChanged<int> onNavigate;
  final ThemeController? themeController;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width > 1400 ? 64 : 32,
            ),
            child: Row(
              children: [
                _Wordmark(onTap: () => onNavigate(0)),
                const Spacer(),
                if (!isMobile) ...[
                  _NavText('Features', 1, activeSection, () => onNavigate(1)),
                  _NavText(
                    'How It Works',
                    2,
                    activeSection,
                    () => onNavigate(2),
                  ),
                  _NavText('Research', 3, activeSection, () => onNavigate(3)),
                  _NavText('About Us', 4, activeSection, () => onNavigate(4)),
                  const SizedBox(width: 42),
                  _NavText(
                    'Sign in',
                    -1,
                    activeSection,
                    () => Navigator.of(context).pushNamed('/login'),
                  ),
                  const SizedBox(width: 18),
                ] else
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.menu_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                if (themeController != null) ...[
                  const SizedBox(width: 10),
                  ThemeToggleButton(controller: themeController!),
                ],
                _ActionButton(
                  label: 'Get Started',
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Image.asset(AppAssets.devInsightLogo, width: 42, height: 42),
        const SizedBox(width: 9),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Dev',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'Insight',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: row),
      );
    }
    return row;
  }
}

class _NavText extends StatelessWidget {
  const _NavText(this.text, this.index, this.active, this.onPressed);
  final String text;
  final int index;
  final int active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: index == active ? AppColors.primaryBlue : AppColors.slateText,
          fontSize: 15,
          fontWeight: index == active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Hero section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 1000;
    final horizontal = MediaQuery.sizeOf(context).width > 1400 ? 64.0 : 32.0;
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 60, horizontal, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: LiquidGlassCard(
              borderRadius: 32,
              variant: LiquidGlassVariant.standard,
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              child: isMobile
                  ? Column(
                      children: [
                        const _HeroCopy(),
                        const SizedBox(height: 44),
                        const _PreviewArea(),
                      ],
                    )
                  : const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 10, child: _HeroCopy()),
                        SizedBox(width: 40),
                        Expanded(flex: 10, child: _PreviewArea()),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headingSize = width < 1100 ? 45.0 : 58.0;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow pill badge
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'AI-POWERED PLATFORM',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 38),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: headingSize,
                height: 1.08,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
              children: [
                const TextSpan(text: 'AI-Powered Intelligence\nfor '),
                TextSpan(
                  text: 'Smarter Software\nProjects',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF0664F2), Color(0xFF14A8EF)],
                      ).createShader(const Rect.fromLTWH(0, 0, 700, 0)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 610),
            child: const Text(
              'DevInsight helps development teams predict risks, prioritize issues, and deliver successful software projects.',
              style: TextStyle(
                color: AppColors.slateText,
                fontSize: 18,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _ActionButton(
                label: 'Get Started  →',
                onPressed: () => Navigator.of(context).pushNamed('/login'),
              ),
              _GhostButton(
                label: 'Sign in',
                onPressed: () => Navigator.of(context).pushNamed('/login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewArea extends StatefulWidget {
  const _PreviewArea();

  @override
  State<_PreviewArea> createState() => _PreviewAreaState();
}

class _PreviewAreaState extends State<_PreviewArea> {
  int _activeTab = 0; // 0 = Live Dashboard, 1 = AI Synergy

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Segmented Switcher Pill
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    title: 'Live Dashboard',
                    icon: Icons.dashboard_customize_outlined,
                    isActive: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0),
                  ),
                  _buildTabButton(
                    title: 'AI Synergy Core',
                    icon: Icons.auto_awesome_rounded,
                    isActive: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _activeTab == 0
                    ? const DashboardPreview(key: ValueKey('dashboard'))
                    : _buildAiTouchPreview(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTouchPreview() {
    return Container(
      key: const ValueKey('ai_touch'),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0664F2).withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.landingAiTouch,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Human Intuition × Machine Learning',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Engineering Co-Pilot Online',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0664F2).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0664F2)),
                  ),
                  child: Text(
                    'DevInsight Core',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF93C5FD),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0664F2), Color(0xFF4B7FFF)],
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryBlue.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}
