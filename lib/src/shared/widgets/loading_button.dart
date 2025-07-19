import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;

  const LoadingButton({
    super.key,
    required this.onPressed,
    this.child,
    this.text,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.minimumSize,
  }) : assert(child != null || text != null, 'Either child or text must be provided');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: minimumSize ?? const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isLoading ? 0 : 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : child ?? Text(text!),
      ),
    );
  }
}