import 'package:flutter/material.dart';

import '../config/theme.dart';

enum CmButtonVariant {
  yellow,
  ink,
  ghost,
  // legacy aliases — mapped to closest new variant
  gold,
  crimson,
  goldOutline,
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final CmButtonVariant variant;
  final double fontSize;
  final double letterSpacing;
  final EdgeInsetsGeometry padding;
  final bool fullWidth;
  final IconData? icon;

  // legacy params kept for backwards-compat (no-op)
  final List<Color>? gradientColors;
  final Color? shadowColor;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = CmButtonVariant.yellow,
    this.fontSize = 16,
    this.letterSpacing = 1.2,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.fullWidth = false,
    this.icon,
    this.gradientColors,
    this.shadowColor,
  });

  CmButtonVariant get _resolved {
    switch (variant) {
      case CmButtonVariant.gold:
        return CmButtonVariant.yellow;
      case CmButtonVariant.crimson:
        return CmButtonVariant.ink;
      case CmButtonVariant.goldOutline:
        return CmButtonVariant.ghost;
      default:
        return variant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final resolved = _resolved;

    final BoxDecoration deco;
    final Color textColor;

    switch (resolved) {
      case CmButtonVariant.yellow:
        deco = BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        );
        textColor = const Color(0xFF1A1400);
        break;
      case CmButtonVariant.ink:
        deco = BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(16),
        );
        textColor = Colors.white;
        break;
      case CmButtonVariant.ghost:
        deco = BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1.5),
        );
        textColor = AppColors.ink;
        break;
      default:
        deco = BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(16),
        );
        textColor = AppColors.ink;
    }

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: textColor, size: fontSize + 2),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.gothic,
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );

    final core = Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        decoration: deco,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(padding: padding, child: content),
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: core) : core;
  }
}
