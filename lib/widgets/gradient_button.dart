import 'package:flutter/material.dart';

import '../config/theme.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color> gradientColors;
  final Color shadowColor;
  final double fontSize;
  final double letterSpacing;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.gradientColors = const [AppColors.gold, AppColors.goldDark],
    this.shadowColor = AppColors.gold,
    this.fontSize = 20,
    this.letterSpacing = 2,
    this.padding = const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradientColors),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: letterSpacing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
