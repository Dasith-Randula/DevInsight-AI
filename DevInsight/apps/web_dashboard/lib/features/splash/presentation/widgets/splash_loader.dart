import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Minimal, elegant loading bar for the DevInsight Midnight Aurora splash screen.
///
/// Responsive dimensions:
/// - Desktop: ~290px width, 7px height
/// - Tablet: ~250px width, 6px height
/// - Mobile: ~220px width, 6px height
///
/// Features:
/// - Fully rounded corners
/// - Dark translucent blue track (#304570)
/// - Vibrant Royal Blue to Azure Blue gradient fill with subtle leading highlight
class SplashLoader extends StatelessWidget {
  const SplashLoader({
    super.key,
    required this.progress,
    this.width = 290,
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
        height: height + 6,
        child: Align(
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  // 1. Dark translucent blue track
                  ColoredBox(
                    color: AppColors.splashLoaderTrack.withValues(alpha: 0.65),
                    child: const SizedBox.expand(),
                  ),

                  // 2. Gradient fill with soft leading glow
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clampedProgress,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(height),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.royalBlue,
                              AppColors.azureBlue,
                              AppColors.softBlueHighlight,
                            ],
                            stops: [0.0, 0.85, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.azureBlue.withValues(alpha: 0.55),
                              blurRadius: 6,
                              offset: const Offset(0, 0),
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
