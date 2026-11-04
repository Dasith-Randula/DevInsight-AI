import 'package:flutter/material.dart';

/// Clean, simple white background for authentication pages (Login, SignUp).
class CharmingAuthBackground extends StatelessWidget {
  final Widget child;

  const CharmingAuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Colors.white, child: child);
  }
}
