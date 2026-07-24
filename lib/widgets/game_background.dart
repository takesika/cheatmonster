import 'dart:math';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class GameBackground extends StatelessWidget {
  final Widget child;

  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bg, AppColors.bgDeep],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _NightSkyPainter())),
          child,
        ],
      ),
    );
  }
}

class _NightSkyPainter extends CustomPainter {
  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = Random(42);
    return List.generate(70, (_) {
      return _Star(
        rng.nextDouble(),
        rng.nextDouble(),
        0.4 + rng.nextDouble() * 1.0,
        0.15 + rng.nextDouble() * 0.30,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final topGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.starlight.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width / 2, 0),
        width: size.width * 1.3,
        height: size.height * 0.8,
      ));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.8),
      topGlow,
    );

    final goldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height),
        width: size.width * 1.0,
        height: size.height * 0.8,
      ));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6),
      goldGlow,
    );

    final starPaint = Paint();
    for (final s in _stars) {
      starPaint.color = Colors.white.withOpacity(s.opacity);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NightSkyPainter oldDelegate) => false;
}

class _Star {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  const _Star(this.x, this.y, this.radius, this.opacity);
}
