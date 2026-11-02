import 'package:flutter/material.dart';

/// Simple, clean white background for the landing page.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: child,
    );
  }
}
