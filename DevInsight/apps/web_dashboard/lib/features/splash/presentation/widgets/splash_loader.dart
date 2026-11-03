import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Premium progress bar for the splash connection check.
class SplashLoader extends StatelessWidget {
  const SplashLoader({
    super.key,
    required this.progress,
    this.width = 220,
    this.height = 7,
  });

  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height + 8,
        child: Align(
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  ColoredBox(
                    color: AppColors.loaderTrack.withValues(alpha: 0.75),
                    child: const SizedBox.expand(),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clampedProgress,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.secondaryBlue,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
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
}
