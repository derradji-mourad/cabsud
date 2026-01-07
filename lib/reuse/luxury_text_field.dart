import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabsudapp/reuse/theme.dart';

class LuxuryTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;

  const LuxuryTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          inputFormatters: inputFormatters,
          // FIXED: Explicit white text color for input
          style: const TextStyle(
            color: AppTheme.softWhite, // White text while typing
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          // FIXED: Cursor color
          cursorColor: AppTheme.primaryGold,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: prefixIcon,
            // These are inherited from theme but explicit for clarity
            labelStyle: TextStyle(
              color: AppTheme.offWhite.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            floatingLabelStyle: const TextStyle(
              color: AppTheme.primaryGold,
              fontSize: 14,
            ),
            hintStyle: TextStyle(
              color: AppTheme.offWhite.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
