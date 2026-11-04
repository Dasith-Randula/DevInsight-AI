import 'package:flutter/material.dart';

class SplashBackground extends StatelessWidget {
  final Widget child;
  final bool isAnimating;

  const SplashBackground({
    super.key,
    required this.child,
    this.isAnimating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/icons/Splash_background.png',
          fit: BoxFit.cover,
        ),
        child,
      ],
    );
  }
}
