import 'dart:math';

import 'package:flutter/material.dart';

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
    final cardWidth = screenWidth * 0.8;
    final cardHeight = cardWidth * 1.4;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFFEF9),
        border: Border.all(color: const Color(0xFFC9A84C), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9A84C).withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: const Color(0xFF2B4C8C).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              monster.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Color(0xFF1A1A3E),
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
                _buildStatLarge('ATK', monster.atk, const Color(0xFFC0392B)),
                _buildStatLarge('DEF', monster.def, const Color(0xFF2B4C8C)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFC9A84C).withOpacity(0.12),
                border: Border.all(
                  color: const Color(0xFFC9A84C).withOpacity(0.3),
                ),
              ),
              child: Text(
                monster.specialAbility,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D5A72),
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

  Widget _buildStatLarge(String label, int value, Color color) {
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
            style: const TextStyle(
              fontSize: 28,
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
    final cardWidth = (screenWidth * 0.4).clamp(120.0, 200.0);
    final cardHeight = cardWidth * 1.5;
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B4C8C), Color(0xFF1A1A3E)],
        ),
        border: Border.all(color: const Color(0xFFC9A84C), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B4C8C).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFC9A84C).withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner decorative dots
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC9A84C).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC9A84C).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC9A84C).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC9A84C).withOpacity(0.4),
              ),
            ),
          ),
          // Center diamond pattern
          Center(
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFC9A84C).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 36,
                    color: Color(0xFFE8D48B),
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
    final cardWidth = (screenWidth * 0.4).clamp(120.0, 200.0);
    final cardHeight = cardWidth * 1.5;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFFEF9),
        border: Border.all(
          color: const Color(0xFFC9A84C),
          width: 2.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B4C8C).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFC9A84C).withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              monster.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Color(0xFF1A1A3E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('ATK', monster.atk, const Color(0xFFC0392B)),
                _buildStat('DEF', monster.def, const Color(0xFF2B4C8C)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFC9A84C).withOpacity(0.12),
                border: Border.all(
                  color: const Color(0xFFC9A84C).withOpacity(0.3),
                ),
              ),
              child: Text(
                monster.specialAbility,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF5D5A72),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
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

  Widget _buildStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
