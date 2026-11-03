import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/liquid_glass_card.dart';
import 'animated_project_graph.dart';

/// Right-side dashboard preview on the landing page hero.
///
/// Renders a fake SaaS dashboard window with:
///   - browser-style top bar
///   - icon sidebar
///   - Project Overview card with an animated line graph
///   - three metric cards (Risk Score, Completion %, Open Issues)
class DashboardPreview extends StatefulWidget {
  const DashboardPreview({super.key});

  @override
  State<DashboardPreview> createState() => _DashboardPreviewState();
}

class _DashboardPreviewState extends State<DashboardPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _translateY = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
      child: const _DashboardWindow(),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard window shell
// ---------------------------------------------------------------------------

class _DashboardWindow extends StatefulWidget {
  const _DashboardWindow();

  @override
  State<_DashboardWindow> createState() => _DashboardWindowState();
}

class _DashboardWindowState extends State<_DashboardWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          -5 * Curves.easeInOutSine.transform(_floatController.value),
        ),
        child: child,
      ),
      child: RepaintBoundary(
        child: LiquidGlassCard(
          borderRadius: 20,
          variant: LiquidGlassVariant.standard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Sidebar(),
                    Expanded(child: _MainContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar (three dots + fake URL bar)
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4EDF8))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _WindowDot(color: Color(0xFFFF5F57)),
          const SizedBox(width: 6),
          const _WindowDot(color: Color(0xFFFFBD2E)),
          const SizedBox(width: 6),
          const _WindowDot(color: Color(0xFF28C840)),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFDDE7F6)),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text(
                'devinsight.app/dashboard',
                style: TextStyle(color: Color(0xFF8EA8CC), fontSize: 9.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const SizedBox(width: 9, height: 9),
  );
}

// ---------------------------------------------------------------------------
// Left sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE4EDF8))),
      ),
      child: const Column(
        children: [
          SizedBox(height: 16),
          _SideIcon(icon: Icons.home_rounded, active: true),
          _SideIcon(icon: Icons.bar_chart_rounded),
          _SideIcon(icon: Icons.code_rounded),
          _SideIcon(icon: Icons.settings_rounded),
        ],
      ),
    );
  }
}

class _SideIcon extends StatelessWidget {
  const _SideIcon({required this.icon, this.active = false});
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, left: 6, right: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE6EFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: null,
        icon: Icon(
          icon,
          color: active ? AppColors.primaryBlue : const Color(0xFF8EA8CC),
          size: 19,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content (chart card + metric cards)
// ---------------------------------------------------------------------------

class _MainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chart card takes ~70% of available height via flex
          Expanded(flex: 7, child: _ChartCard()),
          const SizedBox(height: 8),
          // Metric cards take ~30% of available height
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: _RiskCard()),
                SizedBox(width: 7),
                Expanded(child: _CompletionCard()),
                SizedBox(width: 7),
                Expanded(child: _IssuesCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Project Overview card
// ---------------------------------------------------------------------------

class _ChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EDF8)),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Project Overview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152846),
                  ),
                ),
                Spacer(),
                _TrendBadge(),
              ],
            ),
            SizedBox(height: 5),
            // Expanded fills whatever height remains inside the 210px SizedBox
            Expanded(child: AnimatedProjectGraph()),
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_up_rounded, color: Color(0xFF059669), size: 11),
        SizedBox(width: 3),
        Text(
          '+12.4%',
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Metric cards
// ---------------------------------------------------------------------------

class _RiskCard extends StatelessWidget {
  const _RiskCard();

  @override
  Widget build(BuildContext context) => _MetricCard(
    label: 'Risk Score',
    value: 72,
    suffix: '',
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDC29A)),
      ),
      child: const Text(
        'High',
        style: TextStyle(
          color: Color(0xFFFF7416),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    animationDuration: const Duration(milliseconds: 1200),
  );
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EDF8)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Completion',
            style: TextStyle(
              color: AppColors.slateText,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 68),
            duration: const Duration(milliseconds: 1200),
            builder: (context, v, _) => Text(
              '$v%',
              style: const TextStyle(
                color: Color(0xFF10233E),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 7),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 0.68),
            duration: const Duration(milliseconds: 1300),
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: const Color(0xFFDEE9F8),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssuesCard extends StatelessWidget {
  const _IssuesCard();

  @override
  Widget build(BuildContext context) => _MetricCard(
    label: 'Open Issues',
    value: 134,
    suffix: '',
    trailing: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDC29A)),
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        color: Color(0xFFFF7416),
        size: 14,
      ),
    ),
    animationDuration: const Duration(milliseconds: 1400),
  );
}

// ---------------------------------------------------------------------------
// Generic metric card with animated counter
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.trailing,
    required this.animationDuration,
  });

  final String label;
  final int value;
  final String suffix;
  final Widget trailing;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EDF8)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slateText,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: animationDuration,
                  builder: (context, v, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$v$suffix',
                      style: const TextStyle(
                        color: Color(0xFF10233E),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ],
      ),
    );
  }
}
