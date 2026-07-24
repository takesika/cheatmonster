import 'package:flutter/material.dart';

import '../config/theme.dart';

enum CmButtonVariant { gold, crimson, goldOutline }

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final CmButtonVariant variant;
  final double fontSize;
  final double letterSpacing;
  final EdgeInsetsGeometry padding;
  final bool fullWidth;

  // legacy params kept for backwards-compat (no-op when variant is set)
  final List<Color>? gradientColors;
  final Color? shadowColor;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = CmButtonVariant.gold,
    this.fontSize = 16,
    this.letterSpacing = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    this.fullWidth = false,
    this.gradientColors,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    final BoxDecoration deco;
    final Color textColor;
    final Color borderColor;

    switch (variant) {
      case CmButtonVariant.gold:
        deco = BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.goldLight,
              AppColors.gold,
              AppColors.goldDeep,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          border: Border.all(color: AppColors.goldDeep, width: 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: AppColors.goldDeep,
              offset: Offset(0, 2),
            ),
          ],
        );
        textColor = const Color(0xFF1A1428);
        borderColor = AppColors.goldDeep;
        break;
      case CmButtonVariant.crimson:
        deco = BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.sealLight,
              AppColors.seal,
              AppColors.sealDeep,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          border: Border.all(color: AppColors.sealDeep, width: 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: AppColors.sealDeep,
              offset: Offset(0, 2),
            ),
          ],
        );
        textColor = AppColors.goldLight;
        borderColor = AppColors.sealDeep;
        break;
      case CmButtonVariant.goldOutline:
        deco = BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: AppColors.gold, width: 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              spreadRadius: 0,
              blurRadius: 0,
            ),
          ],
        );
        textColor = AppColors.goldLight;
        borderColor = AppColors.gold;
        break;
    }

    final core = Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        decoration: deco,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.mincho,
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: letterSpacing,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // suppress unused warning for legacy params
    // ignore: unused_local_variable
    final _ = borderColor;

    return fullWidth ? SizedBox(width: double.infinity, child: core) : core;
  }
}
