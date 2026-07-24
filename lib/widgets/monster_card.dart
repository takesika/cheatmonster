import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/monster.dart';

class MonsterCard extends StatelessWidget {
  final Monster monster;
  final bool showBack;
  final bool isLoading;
  final double scale;
  final bool selected;
  final bool faded;

  const MonsterCard({
    super.key,
    required this.monster,
    this.showBack = false,
    this.isLoading = false,
    this.scale = 1.0,
    this.selected = false,
    this.faded = false,
  });

  static const double baseW = 200;
  static const double baseH = 300;

  @override
  Widget build(BuildContext context) {
    if (showBack) return _buildBack();
    return GestureDetector(
      onTap: () => _showExpandedCard(context),
      child: AnimatedScale(
        scale: selected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: AnimatedOpacity(
          opacity: faded ? 0.65 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: ColorFiltered(
            colorFilter: faded
                ? const ColorFilter.matrix(<double>[
                    0.5, 0.5, 0.5, 0, 0,
                    0.5, 0.5, 0.5, 0, 0,
                    0.5, 0.5, 0.5, 0, 0,
                    0, 0, 0, 1, 0,
                  ])
                : const ColorFilter.mode(
                    Colors.transparent, BlendMode.multiply),
            child: _buildFront(scale),
          ),
        ),
      ),
    );
  }

  void _showExpandedCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: Center(
            child: GestureDetector(
              onTap: () {},
              child: _buildFront(1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront(double s) {
    final w = baseW * s;
    final h = baseH * s;
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.all(7 * s),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.parchmentLight, AppColors.parchmentMid],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.3), width: 0.5),
      ),
      child: Stack(
        children: [
          // gold filigree multi-border (drawn via custom paint for nested look)
          Positioned.fill(
            child: CustomPaint(painter: _CardFramePainter()),
          ),
          Padding(
            padding: EdgeInsets.all(5 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 3 * s),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.goldDeep, width: 0.5),
                    ),
                  ),
                  child: Text(
                    monster.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.mincho,
                      fontSize: 12 * s,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1428),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 5 * s),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF5A3E18), width: 1.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 16 * s,
                            height: 16 * s,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.parchmentLight.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFC8364A), width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '✦',
                              style: TextStyle(
                                fontFamily: AppFonts.cinzel,
                                color: const Color(0xFFC8364A),
                                fontSize: 8 * s,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 5 * s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatBadge(label: 'ATK', value: monster.atk, accent: true, scale: s),
                    _StatBadge(label: 'DEF', value: monster.def, scale: s),
                  ],
                ),
                SizedBox(height: 4 * s),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: AppColors.parchmentLight.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.goldDeep, width: 0.5),
                  ),
                  child: Text(
                    monster.specialAbility,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.mincho,
                      fontSize: 10 * s,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF3A2C14),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (isLoading) {
      return Container(
        color: AppColors.parchmentMid,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.goldDeep,
            ),
          ),
        ),
      );
    }
    if (monster.imageBytes != null) {
      return Image.memory(
        monster.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.parchmentMid,
      child: const Center(
        child: Icon(Icons.pets, size: 44, color: AppColors.goldDeep),
      ),
    );
  }

  Widget _buildBack() {
    final w = baseW * scale;
    final h = baseH * scale;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1840), Color(0xFF0A0820)],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CardBackFramePainter()),
          ),
          Center(
            child: Container(
              width: 70 * scale,
              height: 70 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF2A2060), Color(0xFF0A0820)],
                ),
                border: Border.all(color: AppColors.gold, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '✦',
                style: TextStyle(
                  fontFamily: AppFonts.cinzel,
                  color: AppColors.goldLight,
                  fontSize: 30 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final bool accent;
  final double scale;
  const _StatBadge({
    required this.label,
    required this.value,
    this.accent = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: accent
              ? const [Color(0xFFD8485A), Color(0xFF8B1C2C)]
              : const [Color(0xFF1D2A52), Color(0xFF0D1530)],
        ),
        border: Border.all(
          color: accent ? const Color(0xFF5A0E1A) : const Color(0xFF2A3866),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.cinzel,
              fontSize: 8 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF5D68F),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: 4 * scale),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: AppFonts.cinzel,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF5D68F),
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = const Radius.circular(5);

    // gold-deep outer frame
    final p1 = Paint()
      ..color = AppColors.goldDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(outer.deflate(0.75), r), p1);

    // bright gold inner frame
    final p2 = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(outer.deflate(4.0), const Radius.circular(3)),
        p2);

    // corner fleurs
    final fleurPaint = Paint()..color = const Color(0xFF7A5520);
    const off = 6.0;
    void drawFleur(Offset c) {
      canvas.drawCircle(c, 1.2, fleurPaint);
    }

    drawFleur(Offset(off, off));
    drawFleur(Offset(size.width - off, off));
    drawFleur(Offset(off, size.height - off));
    drawFleur(Offset(size.width - off, size.height - off));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardBackFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = const Radius.circular(5);

    final p1 = Paint()
      ..color = AppColors.goldDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(outer.deflate(0.75), r), p1);

    final p2 = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(4.0), const Radius.circular(3)),
      p2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
