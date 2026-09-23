import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
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
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _translateY = Tween<double>(begin: 18, end: 0).animate(
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

class _DashboardWindow extends StatelessWidget {
  const _DashboardWindow();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          border: Border.all(color: const Color(0xFFDDE7F6)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0664F2),
              blurRadius: 32,
              offset: Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top browser-style bar
            _TopBar(),
            // Sidebar + main content
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
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar (three dots)
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2EAF5))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          _WindowDot(color: Color(0xFFAFC1DD)),
          SizedBox(width: 7),
          _WindowDot(color: Color(0xFFAFC1DD)),
          SizedBox(width: 7),
          _WindowDot(color: Color(0xFFAFC1DD)),
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
        child: const SizedBox(width: 8, height: 8),
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
      width: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2EAF5))),
      ),
      child: const Column(
        children: [
          SizedBox(height: 18),
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
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE1EDFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: null,
        icon: Icon(
          icon,
          color: active ? AppColors.primaryBlue : const Color(0xFF7890B6),
          size: 20,
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project Overview card — fixed height so graph always has room
          SizedBox(
            height: 210,
            child: _ChartCard(),
          ),
          const SizedBox(height: 10),
          // Metric cards fill remaining height
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: _RiskCard()),
                SizedBox(width: 8),
                Expanded(child: _CompletionCard()),
                SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EEF8)),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Overview',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF152846),
              ),
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
        trailing: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9D9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'High',
              style: TextStyle(
                color: Color(0xFFFF7416),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
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
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7EEF8)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Completion',
            style: TextStyle(
              color: AppColors.slateText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
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
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 0.68),
            duration: const Duration(milliseconds: 1300),
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: const Color(0xFFE0E8F5),
                color: AppColors.primaryBlue,
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
        trailing: const Icon(
          Icons.description_outlined,
          color: Color(0xFFFF7A21),
          size: 22,
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
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7EEF8)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slateText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: animationDuration,
                  builder: (context, v, _) => Text(
                    '$v$suffix',
                    style: const TextStyle(
                      color: Color(0xFF10233E),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ],
      ),
    );
  }
}
