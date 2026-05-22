import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double? width;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? AppTheme.gradient
              : const LinearGradient(
                  colors: [Color(0xFF555555), Color(0xFF666666)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    )),
                  ],
                ),
        ),
      ),
    );
  }
}
