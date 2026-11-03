import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/liquid_glass_card.dart';

// ---------------------------------------------------------------------------
// Features Section
// ---------------------------------------------------------------------------

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _features = [
    (
      Icons.shield_outlined,
      'Risk Prediction',
      'Uses repository-derived information to identify potentially risky or defect-prone software files and changes.',
    ),
    (
      Icons.low_priority_rounded,
      'Project-Aware Prioritization',
      'Combines technical risk with requirements, severity, business impact, deadlines and delivery context.',
    ),
    (
      Icons.psychology_outlined,
      'Explainable AI',
      'Shows the important factors behind predictions so users can understand why a software risk was identified.',
    ),
    (
      Icons.auto_awesome_outlined,
      'AI Recommendations',
      'Transforms structured ML, project and explainability evidence into clear, grounded recommendations.',
    ),
    (
      Icons.track_changes_outlined,
      'Requirements & Context',
      'Connects software risks with important project requirements and delivery priorities.',
    ),
    (
      Icons.groups_outlined,
      'Workload & Capacity',
      'Supports team-capacity awareness when evaluating how important software risks should be handled.',
    ),
  ];

  static const _iconGradients = [
    [Color(0xFF0664F2), Color(0xFF4B8BFF)],
    [Color(0xFF7C3AED), Color(0xFFAB78FF)],
    [Color(0xFF0891B2), Color(0xFF38BDF8)],
    [Color(0xFF059669), Color(0xFF34D399)],
    [Color(0xFFD97706), Color(0xFFFBBF24)],
    [Color(0xFFDC2626), Color(0xFFF87171)],
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      background: Colors.transparent,
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'CAPABILITIES',
            title: 'Key Features',
            subtitle:
                'Intelligent tools that transform software development data into actionable project insights.',
          ),
          const SizedBox(height: 56),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  mainAxisExtent: columns == 1 ? 142 : 186,
                ),
                itemBuilder: (context, index) => _RevealCard(
                  delay: index * 60,
                  child: _FeatureCard(
                    icon: _features[index].$1,
                    title: _features[index].$2,
                    description: _features[index].$3,
                    gradientColors:
                        _iconGradients[index % _iconGradients.length],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// How It Works Section
// ---------------------------------------------------------------------------

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  static const _steps = [
    (
      Icons.code_rounded,
      'GitHub Data',
      'Commits, file changes, issues, pull requests, CI/CD results and development activity.',
    ),
    (
      Icons.tune_rounded,
      'Data Processing',
      'Repository information is cleaned, structured and transformed into usable features.',
    ),
    (
      Icons.analytics_outlined,
      'Risk Prediction',
      'Machine-learning models estimate software defect or risk likelihood.',
    ),
    (
      Icons.account_tree_outlined,
      'Project Context',
      'Requirements, severity, deadlines, business importance and workload context are added.',
    ),
    (
      Icons.lightbulb_outline_rounded,
      'Prioritization & XAI',
      'The system determines project-aware priority and explains important prediction factors.',
    ),
    (
      Icons.recommend_rounded,
      'AI Recommendation',
      'A grounded AI layer converts the evidence into understandable actions for users.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      background: Colors.transparent,
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'THE WORKFLOW',
            title: 'How DevInsight Works',
            subtitle:
                'From software-development evidence to project-aware decision support.',
          ),
          const SizedBox(height: 48),
          const _NeuralPipelineBanner(),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: wide
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (wide)
                      Expanded(
                        child: _WorkflowCard(step: i + 1, data: _steps[i]),
                      )
                    else
                      _WorkflowCard(step: i + 1, data: _steps[i]),
                    if (i < _steps.length - 1)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 8 : 0,
                          vertical: wide ? 42 : 10,
                        ),
                        child: Icon(
                          wide
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_downward_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Research Section
// ---------------------------------------------------------------------------

class ResearchSection extends StatelessWidget {
  const ResearchSection({super.key, required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      background: Colors.transparent,
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'RESEARCH ACCESS',
            title: 'Project Access',
            subtitle:
                'DevInsight is currently being developed and evaluated as an academic research prototype.',
          ),
          const SizedBox(height: 48),
          _ResearchInnovationShowcase(onLearnMore: onLearnMore),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About Section
// ---------------------------------------------------------------------------

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      background: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1040;
          final isTablet = constraints.maxWidth >= 720;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFDCE7F6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0664F2).withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(isDesktop ? 48 : (isTablet ? 36 : 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Badge & Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0664F2,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFF0664F2,
                                ).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.biotech_rounded,
                                  color: Color(0xFF0664F2),
                                  size: 15,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'COMPREHENSIVE RESEARCH PLATFORM',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF0664F2),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'About DevInsight',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF0D1B38),
                              fontSize: isTablet ? 38 : 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isTablet)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Software Intelligence v1.0',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF475569),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 36),

                // Main Content Body: Left Column Narrative + Right Column 2x2 Grid
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: _buildAboutNarrative()),
                      const SizedBox(width: 44),
                      Expanded(
                        flex: 13,
                        child: _buildAboutPillarsGrid(columns: 2),
                      ),
                    ],
                  )
                else ...[
                  _buildAboutNarrative(),
                  const SizedBox(height: 36),
                  _buildAboutPillarsGrid(columns: isTablet ? 2 : 1),
                ],

                const SizedBox(height: 44),
                const Divider(color: Color(0xFFE2EAF5), height: 1),
                const SizedBox(height: 32),

                // Bottom Metric Strip
                _buildAboutMetricsBar(isMobile: !isTablet),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutNarrative() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DevInsight is an AI-powered software engineering intelligence platform designed to transform repository and project data into high-confidence software-project decision support.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF334155),
            fontSize: 16.5,
            height: 1.65,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'By combining empirical machine-learning risk prediction with client requirements, workload constraints, and explainable AI, DevInsight helps engineering teams identify defect-prone modules and prioritize remediation effectively.',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.slateText,
            fontSize: 15.5,
            height: 1.65,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AboutCapabilityChip(
              icon: Icons.alt_route_rounded,
              label: 'Commit & PR Mining',
            ),
            _AboutCapabilityChip(
              icon: Icons.low_priority_rounded,
              label: 'Priority Alignment',
            ),
            _AboutCapabilityChip(
              icon: Icons.psychology_outlined,
              label: 'XAI Attribution',
            ),
            _AboutCapabilityChip(
              icon: Icons.speed_rounded,
              label: 'Workload Guardrails',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E4F8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bridging the critical gap between raw defect predictions and strategic software engineering delivery decisions.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1E293B),
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutPillarsGrid({required int columns}) {
    const pillars = [
      (
        icon: Icons.science_rounded,
        tag: 'DOMAIN',
        title: 'Software Engineering Intelligence',
        desc:
            'Mining repositories, commits, and developer metadata to build holistic predictive models of software quality.',
        gradient: [Color(0xFF0664F2), Color(0xFF3B82F6)],
      ),
      (
        icon: Icons.trending_up_rounded,
        tag: 'INNOVATION',
        title: 'Technical Risk → Project Priority',
        desc:
            'Translating raw defect probabilities into actionable business priorities aligned with client deliverables.',
        gradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
      ),
      (
        icon: Icons.devices_rounded,
        tag: 'ECOSYSTEM',
        title: 'Web Console + Mobile App',
        desc:
            'A full-featured management web console paired with an on-the-go developer companion mobile app.',
        gradient: [Color(0xFF0891B2), Color(0xFF06B6D4)],
      ),
      (
        icon: Icons.psychology_rounded,
        tag: 'METHODOLOGY',
        title: 'Prediction • Priority • XAI',
        desc:
            'Combining ML defect forecasting with interpretable SHAP/LIME features for grounded decision support.',
        gradient: [Color(0xFF059669), Color(0xFF10B981)],
      ),
    ];

    if (columns == 1) {
      return Column(
        children: pillars
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AboutPillarCard(
                  icon: p.icon,
                  tag: p.tag,
                  title: p.title,
                  description: p.desc,
                  gradient: p.gradient,
                ),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pillars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 180,
      ),
      itemBuilder: (context, index) {
        final p = pillars[index];
        return _AboutPillarCard(
          icon: p.icon,
          tag: p.tag,
          title: p.title,
          description: p.desc,
          gradient: p.gradient,
        );
      },
    );
  }

  Widget _buildAboutMetricsBar({required bool isMobile}) {
    const items = [
      (
        title: '4-Phase Pipeline',
        subtitle: 'Prediction • Prioritize • XAI • Action',
        icon: Icons.hub_outlined,
      ),
      (
        title: 'Dual Ecosystem',
        subtitle: 'Web Analytics + Mobile Companion',
        icon: Icons.devices_other_rounded,
      ),
      (
        title: '100% Explainable',
        subtitle: 'SHAP & LIME Root Cause Analysis',
        icon: Icons.visibility_outlined,
      ),
      (
        title: 'Academic Prototype',
        subtitle: 'Evaluated for Software Teams',
        icon: Icons.verified_outlined,
      ),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: items
            .map(
              (item) => _AboutMetricItem(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
              ),
            )
            .toList(),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _AboutMetricItem(
                  title: item.title,
                  subtitle: item.subtitle,
                  icon: item.icon,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA Section
// ---------------------------------------------------------------------------

class CtaSection extends StatelessWidget {
  const CtaSection({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      background: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;
          final isSmall = constraints.maxWidth < 500;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF060C1B),
                  Color(0xFF0B1736),
                  Color(0xFF070F24),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.60),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0664F2).withValues(alpha: 0.22),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Glowing radial background accents
                Positioned(
                  top: -80,
                  left: -80,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF38BDF8).withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  right: -80,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFA855F7).withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main CTA content
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 56,
                    vertical: isMobile ? 48 : 72,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0664F2,
                          ).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(
                              0xFF60A5FA,
                            ).withValues(alpha: 0.40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0664F2,
                              ).withValues(alpha: 0.25),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.rocket_launch_rounded,
                              color: Color(0xFF93C5FD),
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'READY TO ELEVATE YOUR REPOSITORY INTELLIGENCE?',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFBFDBFE),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Headline
                      Text(
                        'Build Smarter Software Decisions\nwith DevInsight',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: isMobile ? 28 : (isSmall ? 24 : 40),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Subtitle
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Text(
                          'Explore how repository intelligence, project context, and explainable AI empower your engineering team to ship safer, prioritize higher-value fixes, and eliminate delivery blindspots.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: isMobile ? 15 : 17,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),

                      // Action Buttons
                      Wrap(
                        spacing: 18,
                        runSpacing: 14,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _CtaElevatedButton(
                            label: 'Get Started  →',
                            onPressed: onGetStarted,
                          ),
                          _CtaDarkGlassButton(
                            label: 'Sign in to Dashboard',
                            onPressed: onSignIn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Trust Badges Grid
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      const SizedBox(height: 28),
                      const Wrap(
                        spacing: 24,
                        runSpacing: 14,
                        alignment: WrapAlignment.center,
                        children: [
                          _CtaTrustBadge(
                            icon: Icons.code_rounded,
                            text: 'Automated GitHub Sync',
                          ),
                          _CtaTrustBadge(
                            icon: Icons.psychology_outlined,
                            text: 'Explainable AI (SHAP & LIME)',
                          ),
                          _CtaTrustBadge(
                            icon: Icons.shield_outlined,
                            text: 'Real-Time Risk Scoring',
                          ),
                          _CtaTrustBadge(
                            icon: Icons.school_outlined,
                            text: 'Academic Research Prototype',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.onFeatures,
    required this.onHowItWorks,
    required this.onResearch,
    required this.onAbout,
  });

  final VoidCallback onFeatures;
  final VoidCallback onHowItWorks;
  final VoidCallback onResearch;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        // CHANGED: was Color(0xD9FAF8F2) (beige). Now soft white.
        color: Color(0xB3FFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFE2EAF5))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 22,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.devInsightLogo, width: 34, height: 34),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DevInsight',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Color(0xFF0D1B38),
                        ),
                      ),
                      Text(
                        'AI-Powered Software Engineering Intelligence',
                        style: TextStyle(
                          color: AppColors.slateText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 4,
                children: [
                  _FooterLink('Features', onFeatures),
                  _FooterLink('How It Works', onHowItWorks),
                  _FooterLink('Research', onResearch),
                  _FooterLink('About', onAbout),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared layout primitives
// ---------------------------------------------------------------------------

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.child,
    this.background = Colors.transparent,
  });

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width > 600 ? 32 : 20,
        vertical: MediaQuery.sizeOf(context).width > 600 ? 108 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Eyebrow(eyebrow),
      const SizedBox(height: 14),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF0D1B38),
          fontSize: 36,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 16),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.slateText,
            fontSize: 17,
            height: 1.55,
          ),
        ),
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.primaryBlue,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.0,
    ),
  );
}

// ---------------------------------------------------------------------------
// Feature card
// ---------------------------------------------------------------------------

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedSlide(
      offset: _hovered ? const Offset(0, -0.025) : Offset.zero,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: LiquidGlassCard(
        borderRadius: 16,
        variant: LiquidGlassVariant.standard,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          hoverColor: const Color(0xFFEAF4FF),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              border: Border.all(
                color: _hovered
                    ? AppColors.primaryBlue.withValues(alpha: 0.35)
                    : const Color(0x66E8EFF8),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientColors.first.withValues(
                          alpha: 0.28,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: Color(0xFF0D1B38),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: const TextStyle(
                          color: AppColors.slateText,
                          height: 1.45,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 500 + delay),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// Workflow card
// ---------------------------------------------------------------------------

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.step, required this.data});

  final int step;
  final (IconData, String, String) data;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 205),
    child: Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0664F2), Color(0xFF4B8BFF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Icon(data.$1, color: AppColors.primaryBlue, size: 28),
        const SizedBox(height: 10),
        Text(
          data.$2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Color(0xFF0D1B38),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data.$3,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.slateText,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// About section components
// ---------------------------------------------------------------------------

class _AboutPillarCard extends StatefulWidget {
  const _AboutPillarCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.gradient,
  });

  final IconData icon;
  final String tag;
  final String title;
  final String description;
  final List<Color> gradient;

  @override
  State<_AboutPillarCard> createState() => _AboutPillarCardState();
}

class _AboutPillarCardState extends State<_AboutPillarCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? widget.gradient[0].withValues(alpha: 0.5)
                : const Color(0xFFE2EAF5),
            width: _isHovered ? 1.5 : 1.2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.gradient[0].withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient[0].withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.gradient[0].withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.gradient[0].withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    widget.tag,
                    style: GoogleFonts.plusJakartaSans(
                      color: widget.gradient[0],
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0D1B38),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                widget.description,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.slateText,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutMetricItem extends StatelessWidget {
  const _AboutMetricItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0664F2).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0D1B38),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.slateText,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutCapabilityChip extends StatelessWidget {
  const _AboutCapabilityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF0664F2)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA components
// ---------------------------------------------------------------------------

class _CtaElevatedButton extends StatefulWidget {
  const _CtaElevatedButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_CtaElevatedButton> createState() => _CtaElevatedButtonState();
}

class _CtaElevatedButtonState extends State<_CtaElevatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0664F2), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF0664F2,
              ).withValues(alpha: _isHovered ? 0.55 : 0.35),
              blurRadius: _isHovered ? 24 : 16,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaDarkGlassButton extends StatefulWidget {
  const _CtaDarkGlassButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_CtaDarkGlassButton> createState() => _CtaDarkGlassButtonState();
}

class _CtaDarkGlassButtonState extends State<_CtaDarkGlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: _isHovered
              ? const Color(0xFF1E293B).withValues(alpha: 0.85)
              : const Color(0xFF0F172A).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                : const Color(0xFF334155),
            width: 1.2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.login_rounded,
                size: 18,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaTrustBadge extends StatelessWidget {
  const _CtaTrustBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Footer link
// ---------------------------------------------------------------------------

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(foregroundColor: AppColors.slateText),
    child: Text(label),
  );
}

// ---------------------------------------------------------------------------
// 2. Neural Pipeline Banner (Image 3: landing_neural_network.jpg)
// ---------------------------------------------------------------------------

class _NeuralPipelineBanner extends StatelessWidget {
  const _NeuralPipelineBanner();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                blurRadius: 50,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: isMobile ? 1.3 : 2.4,
                child: Image.asset(
                  AppAssets.landingNeuralNetwork,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xF2090D17),
                        const Color(0x99090D17),
                        const Color(0xD9090D17),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 22 : 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEC4899,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFFEC4899,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.hub_rounded,
                                  color: Color(0xFFF472B6),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'THE NEURAL INTELLIGENCE PIPELINE',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFF472B6),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile)
                            Text(
                              'Technical Intelligence → Project Intelligence → Decision Support',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From Raw Commits to Explainable Action',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: isMobile ? 22 : 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'DevInsight maps software complexity across multiple dimensions using deep graph models and XAI.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFCBD5E1),
                              fontSize: isMobile ? 13 : 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildStagePill(
                            '1. Predict Risk',
                            Icons.analytics_outlined,
                            const Color(0xFF38BDF8),
                          ),
                          _buildStagePill(
                            '2. Prioritize Context',
                            Icons.low_priority_rounded,
                            const Color(0xFFA855F7),
                          ),
                          _buildStagePill(
                            '3. Explain Root Causes',
                            Icons.psychology_outlined,
                            const Color(0xFFEC4899),
                          ),
                          _buildStagePill(
                            '4. Recommend Action',
                            Icons.auto_awesome_rounded,
                            const Color(0xFF34D399),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStagePill(String title, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Research Innovation Showcase (Image 4: landing_ai_brain.jpg)
// ---------------------------------------------------------------------------

class _ResearchInnovationShowcase extends StatelessWidget {
  const _ResearchInnovationShowcase({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF070B14),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: 0.14),
                blurRadius: 60,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 11, child: _buildBrainImageSide()),
                    Expanded(
                      flex: 13,
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: _buildResearchContent(),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildBrainImageSide(),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: _buildResearchContent(),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBrainImageSide() {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.landingAiBrain,
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
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.22),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFFC084FC),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explainable AI Engine',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'SHAP & LIME Root Cause Attribution',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFCBD5E1),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFA855F7).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFA855F7).withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            'ACADEMIC RESEARCH PROTOTYPE',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFC084FC),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'DevInsight Research Edition',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'DevInsight is currently being evaluated as an advanced research prototype, combining machine-learning risk predictions with real-world project requirements, developer workloads, and explainable AI models.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF94A3B8),
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _buildResearchPoint(
          'Project-Aware Prioritization',
          'Prioritizes defects affecting critical client requirements over minor issues.',
        ),
        const SizedBox(height: 12),
        _buildResearchPoint(
          'Explainable AI (XAI)',
          'Reveals specific features that caused a file or commit to be marked high-risk.',
        ),
        const SizedBox(height: 12),
        _buildResearchPoint(
          'Actionable Guidance',
          'Synthesizes model predictions into clear, grounded recommendations for engineers.',
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onLearnMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Learn About the Research  →',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFED7AA).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Academic Research Edition',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFFDBA74),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResearchPoint(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF38BDF8),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
