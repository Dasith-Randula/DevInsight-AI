import 'dart:async';

import 'package:flutter/material.dart';

class LandingReveal extends StatefulWidget {
  const LandingReveal({
    super.key,
    required this.scrollController,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
  });

  final ScrollController scrollController;
  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<LandingReveal> createState() => _LandingRevealState();
}

class _LandingRevealState extends State<LandingReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    widget.scrollController.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (_started || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    if (top < viewportHeight * 0.9 && bottom > 0) {
      _started = true;
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkVisibility);
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _progress.value,
      child: Transform.translate(
        offset: Offset(0, 22 * (1 - _progress.value)),
        child: Transform.scale(
          scale: 0.985 + 0.015 * _progress.value,
          child: child,
        ),
      ),
    ),
  );
}
