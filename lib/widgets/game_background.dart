import 'package:flutter/material.dart';

import '../config/theme.dart';

class GameBackground extends StatelessWidget {
  final Widget child;
  final bool dark;

  const GameBackground({super.key, required this.child, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: dark ? AppColors.dark : AppColors.bg,
      child: child,
    );
  }
}
