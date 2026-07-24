import 'package:flutter/material.dart';

import '../config/theme.dart';

class WaxSeal extends StatelessWidget {
  final String label;
  final double size;
  final double rotation;

  const WaxSeal({
    super.key,
    required this.label,
    this.size = 32,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.42;
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [
              AppColors.sealLight,
              AppColors.seal,
              AppColors.sealDeep,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C1414).withOpacity(0.45),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.18), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // inner dashed ring
            Container(
              margin: EdgeInsets.all(size * 0.1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFDCB4).withOpacity(0.5),
                  width: 0.7,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.goldLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
