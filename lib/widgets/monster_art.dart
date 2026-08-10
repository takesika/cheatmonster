import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class MonsterArt extends StatelessWidget {
  final Uint8List? imageBytes;
  final double radius;
  final bool loading;

  const MonsterArt({
    super.key,
    this.imageBytes,
    this.radius = 18,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 0.9,
            colors: [Color(0xFF3A2E5E), Color(0xFF1A1428)],
          ),
        ),
        child: imageBytes != null
            ? Image.memory(imageBytes!, fit: BoxFit.cover)
            : Center(
                child: loading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.yellow),
                        ),
                      )
                    : const Icon(Icons.image_outlined,
                        size: 48, color: Colors.white38),
              ),
      ),
    );
  }
}

class StatCards extends StatelessWidget {
  final int atk;
  final int def;
  final double scale;

  const StatCards({
    super.key,
    required this.atk,
    required this.def,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'ATK', value: atk, color: AppColors.atk, scale: scale)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(label: 'DEF', value: def, color: AppColors.def, scale: scale)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final double scale;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10 * scale),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 28 * scale,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class AbilityLine extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final TextAlign align;

  const AbilityLine({
    super.key,
    required this.text,
    this.size = 24,
    this.color = AppColors.ink,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '「$text」',
      textAlign: align,
      style: TextStyle(
        fontFamily: AppFonts.gothic,
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.3,
        letterSpacing: 0.5,
      ),
    );
  }
}

class BattleMonster extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool loading;
  final String name;
  final String ability;
  final bool alignRight;

  /// When true, the ability text is replaced with a masked placeholder.
  /// Used for the reigning champion in throne mode — their ability stays
  /// hidden until the throne actually changes hands.
  final bool hideAbility;

  const BattleMonster({
    super.key,
    this.imageBytes,
    this.loading = false,
    required this.name,
    required this.ability,
    required this.alignRight,
    this.hideAbility = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: MonsterArt(
            imageBytes: imageBytes,
            loading: loading,
            radius: 0,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: alignRight ? Alignment.centerRight : Alignment.centerLeft,
                end: alignRight ? Alignment.centerLeft : Alignment.centerRight,
                colors: [
                  AppColors.dark.withValues(alpha: 0.85),
                  AppColors.dark.withValues(alpha: 0.1),
                ],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
        ),
        Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Column(
                crossAxisAlignment:
                    alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    textAlign: alignRight ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontFamily: AppFonts.gothic,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hideAbility ? '「? ? ? ? ?」' : '「$ability」',
                    textAlign: alignRight ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontFamily: AppFonts.gothic,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
