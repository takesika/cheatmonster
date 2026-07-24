import 'package:flutter/material.dart';

import '../config/theme.dart';

class FleurDivider extends StatelessWidget {
  final bool small;

  const FleurDivider({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final lineW = small ? 30.0 : 60.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: lineW,
          height: 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00B89752),
                  AppColors.gold,
                  Color(0x00B89752),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '✦',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: small ? 9 : 11,
            letterSpacing: 5,
            fontFamily: AppFonts.cinzel,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: lineW,
          height: 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00B89752),
                  AppColors.gold,
                  Color(0x00B89752),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
