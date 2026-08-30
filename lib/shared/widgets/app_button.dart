import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? height;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 56,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case ButtonVariant.primary:
        return _GradientButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          gradient: AppColors.primaryGradient,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          fontSize: fontSize,
        );
      case ButtonVariant.secondary:
        return _GradientButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          gradient: AppColors.accentGradient,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          fontSize: fontSize,
        );
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(AppColors.primary),
        );
      case ButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(AppColors.primary),
        );
      case ButtonVariant.danger:
        return _GradientButton(
          label: label,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          gradient: const LinearGradient(
            colors: [AppColors.error, Color(0xFFCC0000)],
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          fontSize: fontSize,
        );
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: 18, color: color),
          const SizedBox(width: 8),
        ],
        Text(label, style: AppTextStyles.buttonLarge.copyWith(color: color, fontSize: fontSize)),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: 18, color: color),
        ],
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LinearGradient gradient;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? fontSize;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.gradient,
    this.prefixIcon,
    this.suffixIcon,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800])
            : gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    Icon(prefixIcon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontSize: fontSize,
                    ),
                  ),
                  if (suffixIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(suffixIcon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
