import 'package:flutter/material.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({
    super.key,
    required this.child,
    this.isAnimating = true,
  });

  final Widget child;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/Splash_background.png', fit: BoxFit.cover),
        child,
      ],
    );
  }
}
