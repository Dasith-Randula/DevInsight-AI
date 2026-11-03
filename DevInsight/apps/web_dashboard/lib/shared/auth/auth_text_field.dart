import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// Shared animated auth text field with focus-responsive border glow.
///
/// Animates border color, border width, icon color, and a subtle blue
/// glow on focus in ~200ms. Works with any [TextEditingController] and
/// optional validator.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    // Only dispose the internally created focus node.
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.14),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        autofocus: widget.autofocus,
        validator: widget.validator,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.darkText,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.primaryBlue,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.inputBg,
          hintText: widget.hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.slateText.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(
              widget.prefixIcon,
              size: 20,
              color: _isFocused
                  ? AppColors.primaryBlue
                  : AppColors.slateText.withValues(alpha: 0.75),
            ),
          ),
          suffixIcon: widget.suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: _border(AppColors.inputBorder, 1.2),
          enabledBorder: _border(AppColors.inputBorder, 1.2),
          focusedBorder: _border(AppColors.primaryBlue, 1.8),
          errorBorder: _border(AppColors.error, 1.2),
          focusedErrorBorder: _border(AppColors.error, 1.8),
          errorStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.error,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

