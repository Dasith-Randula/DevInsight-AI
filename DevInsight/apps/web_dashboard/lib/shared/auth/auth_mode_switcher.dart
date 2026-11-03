import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../widgets/liquid_glass_card.dart';

class AuthModeSwitcher extends StatelessWidget {
  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  const AuthModeSwitcher({
    super.key,
    required this.isSignUp,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      borderRadius: 26,
      variant: LiquidGlassVariant.subtle,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = (constraints.maxWidth - 8) / 2;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    left: isSignUp ? tabWidth : 0,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.secondaryBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _Tab(
                        label: 'Log In',
                        isActive: !isSignUp,
                        onTap: () => onChanged(false),
                      ),
                      _Tab(
                        label: 'Sign Up',
                        isActive: isSignUp,
                        onTap: () => onChanged(true),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: isActive ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isActive ? null : onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? Colors.white : AppColors.slateText,
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
