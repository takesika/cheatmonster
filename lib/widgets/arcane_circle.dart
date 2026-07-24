import 'dart:math';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class ArcaneCircle extends StatefulWidget {
  final double size;
  final double opacity;

  const ArcaneCircle({super.key, this.size = 280, this.opacity = 0.18});

  @override
  State<ArcaneCircle> createState() => _ArcaneCircleState();
}

class _ArcaneCircleState extends State<ArcaneCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 80),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Transform.rotate(
                angle: _controller.value * 2 * pi,
                child: CustomPaint(painter: _ArcaneCirclePainter()),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArcaneCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final stroke = Paint()
      ..color = AppColors.goldGlow
      ..style = PaintingStyle.stroke;

    stroke
      ..strokeWidth = r * 0.005
      ..color = AppColors.goldGlow.withOpacity(0.9);
    canvas.drawCircle(c, r * 0.95, stroke);

    stroke.strokeWidth = r * 0.003;
    _drawDashedCircle(canvas, c, r * 0.85, stroke, 4, 8);

    stroke.strokeWidth = r * 0.005;
    canvas.drawCircle(c, r * 0.70, stroke);

    stroke.strokeWidth = r * 0.003;
    canvas.drawCircle(c, r * 0.55, stroke);

    // pentagram (5-point star)
    stroke.strokeWidth = r * 0.006;
    final path = Path();
    final pr = r * 0.65;
    for (int i = 0; i < 5; i++) {
      final a = -pi / 2 + (i * 4 * pi / 5);
      final p = Offset(c.dx + cos(a) * pr, c.dy + sin(a) * pr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, stroke);

    // runes around
    const runes = ['ᚠ', 'ᚱ', 'ᚦ', 'ᛟ', 'ᛉ', 'ᛊ', 'ᚷ', 'ᚺ', 'ᛏ', 'ᛁ', 'ᛒ', 'ᛗ'];
    final textStyle = TextStyle(
      color: AppColors.goldGlow,
      fontSize: r * 0.06,
      fontFamily: AppFonts.cinzel,
    );
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      final p = Offset(c.dx + cos(a) * r * 0.90, c.dy + sin(a) * r * 0.90);
      final tp = TextPainter(
        text: TextSpan(text: runes[i], style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset c, double r, Paint paint,
      double dash, double gap) {
    final circumference = 2 * pi * r;
    final dashAngle = (dash / circumference) * 2 * pi;
    final gapAngle = (gap / circumference) * 2 * pi;
    double a = 0;
    while (a < 2 * pi) {
      final rect = Rect.fromCircle(center: c, radius: r);
      final p = Path()..addArc(rect, a, dashAngle);
      canvas.drawPath(p, paint);
      a += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ArcaneCirclePainter oldDelegate) => false;
}
