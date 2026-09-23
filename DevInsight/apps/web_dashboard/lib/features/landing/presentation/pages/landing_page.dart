import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/dashboard_preview.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 1000;
            final horizontal = constraints.maxWidth > 1400 ? 64.0 : 32.0;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 24),
                    child: Column(
                      children: [
                        _LandingNav(isMobile: isMobile),
                        const SizedBox(height: 50),
                        if (isMobile)
                          const Column(
                            children: [
                              _HeroCopy(),
                              SizedBox(height: 44),
                              _PreviewArea(),
                            ],
                          )
                        else
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 10, child: _HeroCopy()),
                              SizedBox(width: 40),
                              Expanded(flex: 10, child: _PreviewArea()),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LandingNav extends StatelessWidget {
  const _LandingNav({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Wordmark(),
        const Spacer(),
        if (!isMobile) ...[
          _NavText('Features'),
          _NavText('How It Works'),
          _NavText('Pricing'),
          _NavText('About Us'),
          const SizedBox(width: 74),
          _NavText('Sign in'),
          const SizedBox(width: 28),
        ] else
          IconButton(onPressed: () {}, icon: const Icon(Icons.menu_rounded, color: AppColors.slateText)),
        _ActionButton(label: 'Get Started', onPressed: () {}),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Image.asset(AppAssets.devInsightLogo, width: 42, height: 42),
      const SizedBox(width: 9),
      RichText(text: const TextSpan(children: [
        TextSpan(text: 'Dev', style: TextStyle(color: AppColors.black, fontSize: 23, fontWeight: FontWeight.w800)),
        TextSpan(text: 'Insight', style: TextStyle(color: AppColors.primaryBlue, fontSize: 23, fontWeight: FontWeight.w800)),
      ])),
    ]);
  }
}

class _NavText extends StatelessWidget {
  const _NavText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextButton(onPressed: () {}, child: Text(text, style: const TextStyle(color: AppColors.slateText, fontSize: 16, fontWeight: FontWeight.w600))),
      );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headingSize = width < 1100 ? 45.0 : 56.0;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DecoratedBox(
          decoration: BoxDecoration(color: const Color(0xFFE5F0FF), borderRadius: BorderRadius.circular(22)),
          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('AI-POWERED PLATFORM', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: .2))),
        ),
        const SizedBox(height: 38),
        RichText(text: TextSpan(style: TextStyle(fontSize: headingSize, height: 1.05, fontWeight: FontWeight.w800, color: AppColors.black), children: const [
          TextSpan(text: 'AI-Powered Intelligence\nfor '),
          TextSpan(text: 'Smarter Software Projects', style: TextStyle(color: AppColors.primaryBlue)),
        ])),
        const SizedBox(height: 22),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 610), child: const Text('DevInsight helps development teams predict risks, prioritize issues, and deliver successful software projects.', style: TextStyle(color: AppColors.slateText, fontSize: 18, height: 1.35, fontWeight: FontWeight.w600))),
        const SizedBox(height: 36),
        Wrap(spacing: 22, runSpacing: 12, children: [
          _ActionButton(label: 'Get Started  →', onPressed: () {}),
          OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryBlue, side: const BorderSide(color: AppColors.primaryBlue, width: 2), padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))), child: const Text('Sign in', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
        ]),
      ]),
    );
  }
}

class _PreviewArea extends StatelessWidget {
  const _PreviewArea();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: const AspectRatio(
          aspectRatio: 1.7,
          child: DashboardPreview(),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))), child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)));
}
