import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';

const dashboardNavy = Color(0xFF101B33);
const dashboardBlue = Color(0xFF0056FF);
const dashboardAzure = Color(0xFF2277FF);
const dashboardCyan = Color(0xFF14C8F5);
const dashboardPaleBlue = Color(0xFFEAF3FF);
const dashboardMuted = Color(0xFF71809A);
const dashboardRule = Color(0xFFDCE7F5);

TextStyle dashboardTextStyle({
  Color? color,
  double size = 14,
  FontWeight weight = FontWeight.w500,
  double height = 1.4,
}) => GoogleFonts.plusJakartaSans(
  color: color,
  fontSize: size,
  fontWeight: weight,
  height: height,
);

class DashboardScrollReveal extends StatefulWidget {
  const DashboardScrollReveal({
    super.key,
    required this.controller,
    required this.child,
    this.delay = Duration.zero,
  });

  final ScrollController controller;
  final Widget child;
  final Duration delay;

  @override
  State<DashboardScrollReveal> createState() => _DashboardScrollRevealState();
}

class _DashboardScrollRevealState extends State<DashboardScrollReveal> {
  bool _revealed = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(covariant DashboardScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_checkVisibility);
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (_revealed || _scheduled || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final height = MediaQuery.sizeOf(context).height;
    if (top < height * .92 && bottom > 56) {
      _scheduled = true;
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _revealed = true);
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shown = _revealed || reduceMotion;
    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, .025),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class DashboardPageHeading extends StatelessWidget {
  const DashboardPageHeading({
    super.key,
    required this.controller,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
  });

  final ScrollController controller;
  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 42),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: dashboardTextStyle(
                  color: dashboardBlue,
                  size: 10,
                  weight: FontWeight.w800,
                ).copyWith(letterSpacing: 1.4),
              ),
              const SizedBox(height: 12),
              DashboardScrollReveal(
                controller: controller,
                delay: const Duration(milliseconds: 70),
                child: Text(
                  title,
                  style: dashboardTextStyle(
                    color: colors.primaryText,
                    size: compact ? 30 : 40,
                    weight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: DashboardScrollReveal(
                  controller: controller,
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    description,
                    style: dashboardTextStyle(
                      color: colors.mutedText,
                      size: 14,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
            ],
          );
          if (trailing == null) return heading;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 20),
                DashboardScrollReveal(
                  controller: controller,
                  delay: const Duration(milliseconds: 230),
                  child: trailing!,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              DashboardScrollReveal(
                controller: controller,
                delay: const Duration(milliseconds: 230),
                child: trailing!,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardSectionHeading extends StatelessWidget {
  const DashboardSectionHeading({
    super.key,
    required this.title,
    required this.description,
    this.label,
  });

  final String title;
  final String description;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: dashboardTextStyle(
              color: dashboardBlue,
              size: 10,
              weight: FontWeight.w800,
            ).copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 9),
        ],
        Text(
          title,
          style: dashboardTextStyle(
            color: colors.primaryText,
            size: 24,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: dashboardTextStyle(
            color: colors.mutedText,
            size: 12,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class DashboardMetric extends StatelessWidget {
  const DashboardMetric({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    this.color = dashboardBlue,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 138),
      padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color.withValues(alpha: .55), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: dashboardTextStyle(
              color: colors.mutedText,
              size: 9,
              weight: FontWeight.w700,
            ).copyWith(letterSpacing: .6),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: dashboardTextStyle(
              color: colors.primaryText,
              size: 24,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: dashboardTextStyle(color: colors.mutedText, size: 10),
          ),
        ],
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.divider),
          bottom: BorderSide(color: colors.divider),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: dashboardBlue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: dashboardTextStyle(
                      color: colors.primaryText,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: dashboardTextStyle(
                      color: colors.mutedText,
                      size: 12,
                      height: 1.6,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 14), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardInlineNotice extends StatelessWidget {
  const DashboardInlineNotice({
    super.key,
    required this.message,
    this.stale = false,
  });

  final String message;
  final bool stale;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 22),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? context.appTheme.surfaceSecondary
          : stale
          ? const Color(0xFFFFF7E5)
          : const Color(0xFFFFF1F0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? context.appTheme.border
            : stale
            ? const Color(0xFFF2D28A)
            : const Color(0xFFF3C1BD),
      ),
    ),
    child: Row(
      children: [
        Icon(
          stale ? Icons.cloud_off_outlined : Icons.error_outline_rounded,
          size: 18,
          color: stale ? const Color(0xFF9B6A00) : const Color(0xFFB42318),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            message,
            style: dashboardTextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.appTheme.secondaryText
                  : dashboardNavy,
              size: 10,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class DashboardDataRow extends StatelessWidget {
  const DashboardDataRow({
    super.key,
    required this.leading,
    required this.title,
    required this.detail,
    this.trailing,
    this.onTap,
    this.color = dashboardBlue,
  });

  final Widget leading;
  final String title;
  final String detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Center(
                child: IconTheme(
                  data: IconThemeData(color: color, size: 18),
                  child: leading,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: dashboardTextStyle(
                      weight: FontWeight.w700,
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: dashboardTextStyle(
                      color: dashboardMuted,
                      size: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    ),
  );
}

class DashboardStatusTag extends StatelessWidget {
  const DashboardStatusTag(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: dashboardTextStyle(color: color, size: 9, weight: FontWeight.w800),
    ),
  );
}

class DashboardAnimatedWorkflow extends StatefulWidget {
  const DashboardAnimatedWorkflow({
    super.key,
    required this.controller,
    required this.stages,
    this.accent = dashboardBlue,
  });

  final ScrollController controller;
  final List<String> stages;
  final Color accent;

  @override
  State<DashboardAnimatedWorkflow> createState() =>
      _DashboardAnimatedWorkflowState();
}

class _DashboardAnimatedWorkflowState extends State<DashboardAnimatedWorkflow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool? _reducedMotion;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void didUpdateWidget(covariant DashboardAnimatedWorkflow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateVisibility);
      widget.controller.addListener(_updateVisibility);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reducedMotion == reduced) return;
    _reducedMotion = reduced;
    _syncAnimation();
  }

  void _updateVisibility() {
    if (!mounted) return;
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return;
    final top = object.localToGlobal(Offset.zero).dy;
    final bottom = top + object.size.height;
    final visible = top < MediaQuery.sizeOf(context).height && bottom > 0;
    if (visible == _visible) return;
    _visible = visible;
    _syncAnimation();
  }

  void _syncAnimation() {
    if (_reducedMotion == true) {
      _flow
        ..stop()
        ..value = 0;
    } else if (_visible) {
      _flow.repeat();
    } else {
      _flow.stop();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateVisibility);
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < widget.stages.length * 88.0;
      return RepaintBoundary(
        child: compact
            ? CustomPaint(
                key: const ValueKey('workflow-illustration'),
                painter: _WorkflowPainter(
                  progress: _flow,
                  labels: widget.stages,
                  accent: widget.accent,
                  compact: true,
                ),
                child: SizedBox(
                  height: widget.stages.length * 52.0,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final (index, label) in widget.stages.indexed)
                        Row(
                          children: [
                            Container(
                              width: 27,
                              height: 27,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: widget.accent.withValues(alpha: .55),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: dashboardTextStyle(
                                    color: widget.accent,
                                    size: 10,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: dashboardTextStyle(
                                  size: 11,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  CustomPaint(
                    key: const ValueKey('workflow-illustration'),
                    painter: _WorkflowPainter(
                      progress: _flow,
                      labels: widget.stages,
                      accent: widget.accent,
                      compact: false,
                    ),
                    child: const SizedBox(height: 44, width: double.infinity),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final label in widget.stages)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: dashboardTextStyle(
                                  size: 10,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class DashboardContributorNetwork extends StatefulWidget {
  const DashboardContributorNetwork({
    super.key,
    required this.controller,
    required this.repositoryName,
    required this.contributors,
  });

  final ScrollController controller;
  final String repositoryName;
  final List<String> contributors;

  @override
  State<DashboardContributorNetwork> createState() =>
      _DashboardContributorNetworkState();
}

class _DashboardContributorNetworkState
    extends State<DashboardContributorNetwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  bool _visible = false;
  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(covariant DashboardContributorNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_checkVisibility);
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reducedMotion == reduced) return;
    _reducedMotion = reduced;
    _syncFlow();
  }

  void _checkVisibility() {
    if (!mounted) return;
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return;
    final top = object.localToGlobal(Offset.zero).dy;
    final visible =
        top < MediaQuery.sizeOf(context).height && top + object.size.height > 0;
    if (visible == _visible) return;
    _visible = visible;
    _syncFlow();
  }

  void _syncFlow() {
    if (_reducedMotion == true) {
      _flow
        ..stop()
        ..value = 0;
    } else if (_visible) {
      _flow.repeat();
    } else {
      _flow.stop();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      height: 260,
      width: double.infinity,
      child: CustomPaint(
        painter: _ContributorNetworkPainter(
          progress: _flow,
          repositoryName: widget.repositoryName,
          contributors: widget.contributors.take(6).toList(),
        ),
      ),
    ),
  );
}

class _ContributorNetworkPainter extends CustomPainter {
  const _ContributorNetworkPainter({
    required this.progress,
    required this.repositoryName,
    required this.contributors,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final String repositoryName;
  final List<String> contributors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = math.min(size.width * .37, 300.0);
    const radiusY = 82.0;
    final count = contributors.length;
    final points = <Offset>[];
    for (var index = 0; index < count; index++) {
      final angle = -math.pi / 2 + 2 * math.pi * index / count;
      points.add(
        Offset(
          center.dx + radiusX * math.cos(angle),
          center.dy + radiusY * math.sin(angle),
        ),
      );
    }
    final line = Paint()
      ..color = dashboardBlue.withValues(alpha: .24)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;
    final particlePaint = Paint()
      ..color = dashboardCyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      canvas.drawLine(point, center, line);
      final progressValue = (progress.value + index / math.max(1, count)) % 1;
      canvas.drawCircle(
        Offset.lerp(point, center, progressValue)!,
        3.2,
        particlePaint,
      );
      _drawNode(canvas, point, contributors[index], dashboardAzure);
    }
    _drawNode(canvas, center, repositoryName, dashboardBlue, central: true);
  }

  void _drawNode(
    Canvas canvas,
    Offset center,
    String label,
    Color color, {
    bool central = false,
  }) {
    final radius = central ? 23.0 : 17.0;
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()..color = color.withValues(alpha: .08),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = central ? 2 : 1.5,
    );
    final display = central
        ? _shortName(label)
        : label.length > 12
        ? '${label.substring(0, 11)}…'
        : label;
    final text = TextPainter(
      text: TextSpan(
        text: display,
        style: dashboardTextStyle(
          color: central ? color : dashboardNavy,
          size: central ? 8 : 8.5,
          weight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: central ? 78 : 92);
    final labelOffset = central
        ? Offset(center.dx - text.width / 2, center.dy + radius + 9)
        : Offset(center.dx - text.width / 2, center.dy + radius + 7);
    text.paint(canvas, labelOffset);
  }

  String _shortName(String value) {
    if (value.length <= 13) return value;
    return '${value.substring(0, 12)}…';
  }

  @override
  bool shouldRepaint(covariant _ContributorNetworkPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.repositoryName != repositoryName ||
      oldDelegate.contributors != contributors;
}

class _WorkflowPainter extends CustomPainter {
  const _WorkflowPainter({
    required this.progress,
    required this.labels,
    required this.accent,
    required this.compact,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<String> labels;
  final Color accent;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.length < 2) return;
    final pointPaint = Paint()..isAntiAlias = true;
    final linePaint = Paint()
      ..color = accent.withValues(alpha: .24)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final particlePaint = Paint()
      ..color = accent.withValues(alpha: .72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final points = <Offset>[];
    if (compact) {
      final step = size.height / labels.length;
      for (var index = 0; index < labels.length; index++) {
        points.add(Offset(13.5, step * (index + .5)));
      }
    } else {
      final step = size.width / labels.length;
      for (var index = 0; index < labels.length; index++) {
        points.add(Offset(step * (index + .5), size.height / 2));
      }
    }
    for (var index = 0; index < points.length - 1; index++) {
      canvas.drawLine(points[index], points[index + 1], linePaint);
    }
    final segment = progress.value * (points.length - 1);
    final segmentIndex = segment.floor().clamp(0, points.length - 2);
    final localProgress = segment - segmentIndex;
    final particle = Offset.lerp(
      points[segmentIndex],
      points[segmentIndex + 1],
      localProgress,
    )!;
    canvas.drawCircle(particle, 5, particlePaint);
    for (var index = 0; index < points.length; index++) {
      pointPaint.color = Colors.white;
      canvas.drawCircle(points[index], 8, pointPaint);
      pointPaint
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7;
      canvas.drawCircle(points[index], 7, pointPaint);
      pointPaint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant _WorkflowPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.labels != labels ||
      oldDelegate.accent != accent ||
      oldDelegate.compact != compact;
}

class DashboardLanguageBars extends StatelessWidget {
  const DashboardLanguageBars({
    super.key,
    required this.languages,
    this.limit = 6,
  });

  final List<({String name, double percentage})> languages;
  final int limit;

  static const _colors = [
    dashboardBlue,
    Color(0xFF7C3AED),
    dashboardCyan,
    Color(0xFF15A578),
    Color(0xFFF59E0B),
    Color(0xFFEF5675),
  ];

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return const DashboardEmptyState(
        icon: Icons.code_rounded,
        title: 'Language data unavailable',
        description:
            'GitHub has not returned language composition for this repository.',
      );
    }
    return Column(
      children: [
        for (final (index, language) in languages.take(limit).indexed) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.name,
                    style: dashboardTextStyle(
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${language.percentage.toStringAsFixed(1)}%',
                  style: dashboardTextStyle(
                    color: dashboardMuted,
                    size: 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: (language.percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: dashboardPaleBlue,
              valueColor: AlwaysStoppedAnimation(
                _colors[index % _colors.length],
              ),
            ),
          ),
          if (index != languages.take(limit).length - 1)
            const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class DashboardSparkline extends StatelessWidget {
  const DashboardSparkline({
    super.key,
    required this.values,
    this.color = dashboardBlue,
    this.height = 110,
  });

  final List<double?> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _SparklinePainter(values, color)),
  );
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values, this.color);

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final known = values.whereType<double>().toList();
    if (known.isEmpty || values.length < 2) return;
    final maxValue = math.max(1, known.reduce(math.max));
    final path = Path();
    var started = false;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value == null) {
        started = false;
        continue;
      }
      final point = Offset(
        size.width * index / (values.length - 1),
        size.height - (value / maxValue * (size.height - 16)) - 8,
      );
      if (started) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
        started = true;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .82)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value == null) continue;
      final point = Offset(
        size.width * index / (values.length - 1),
        size.height - (value / maxValue * (size.height - 16)) - 8,
      );
      canvas.drawCircle(point, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
