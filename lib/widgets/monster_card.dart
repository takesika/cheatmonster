import 'dart:math';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/monster.dart';

class MonsterCard extends StatelessWidget {
  final Monster monster;
  final bool showBack;
  final bool isLoading;

  const MonsterCard({
    super.key,
    required this.monster,
    this.showBack = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showBack) {
      return _buildCardBack(context);
    }
    return GestureDetector(
      onTap: () => _showExpandedCard(context),
      child: _buildCardFront(context),
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
              child: _buildExpandedCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = AppScale.of(context);
    final cardWidth = screenWidth * 0.8;
    final cardHeight = cardWidth * 1.4;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.cardWhite,
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.sapphire.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              monster.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatLarge('ATK', monster.atk, AppColors.ruby, scale),
                _buildStatLarge('DEF', monster.def, AppColors.sapphire, scale),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.gold.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                ),
              ),
              child: Text(
                monster.specialAbility,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatLarge(String label, int value, Color color, double scale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28 * scale,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = AppScale.of(context);
    final cardWidth = (screenWidth * 0.36).clamp(110.0, 180.0);
    final cardHeight = cardWidth * 1.5;
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sapphire, AppColors.textPrimary],
        ),
        border: Border.all(color: AppColors.gold, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.sapphire.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.gold.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          for (final pos in [
            const Alignment(-1, -1),
            const Alignment(1, -1),
            const Alignment(-1, 1),
            const Alignment(1, 1),
          ])
            Positioned(
              top: pos.y < 0 ? 12 : null,
              bottom: pos.y > 0 ? 12 : null,
              left: pos.x < 0 ? 12 : null,
              right: pos.x > 0 ? 12 : null,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.4),
                ),
              ),
            ),
          Center(
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 80 * scale,
                height: 80 * scale,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 36,
                    color: AppColors.goldLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = AppScale.of(context);
    final cardWidth = (screenWidth * 0.36).clamp(110.0, 180.0);
    final cardHeight = cardWidth * 1.5;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.cardWhite,
        border: Border.all(
          color: AppColors.gold,
          width: 2.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sapphire.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.gold.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              monster.name,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4 * scale),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(),
              ),
            ),
            SizedBox(height: 4 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('ATK', monster.atk, AppColors.ruby, scale),
                _buildStat('DEF', monster.def, AppColors.sapphire, scale),
              ],
            ),
            SizedBox(height: 3 * scale),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.gold.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                ),
              ),
              child: Text(
                monster.specialAbility,
                style: TextStyle(
                  fontSize: 9 * scale,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (isLoading) {
      return Container(
        color: const Color(0xFFF0EDE8),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (monster.imageBytes != null) {
      return Image.memory(
        monster.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFF0EDE8),
      child: const Center(
        child: Icon(Icons.pets, size: 48, color: Color(0xFFBDBDBD)),
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8 * scale,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 2 * scale),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
