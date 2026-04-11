import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_mode.dart';
import '../providers/game_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GameProvider>().loadRemainingBattles();
    context.read<GameProvider>().loadPvpRecord();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F0EB), Color(0xFFE8E0F0)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative element 1: gold radial top-left
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFC9A84C).withOpacity(0.06),
                      const Color(0xFFC9A84C).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Decorative element 2: sapphire radial bottom-right
            Positioned(
              bottom: -100,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2B4C8C).withOpacity(0.05),
                      const Color(0xFF2B4C8C).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Decorative element 3: rotated square
            Positioned(
              top: 300,
              right: -40,
              child: Transform.rotate(
                angle: pi / 4,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFC9A84C).withOpacity(0.06),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Consumer<GameProvider>(
                  builder: (context, game, _) {
                    final remaining = game.remainingBattles;
                    final canPlay = remaining > 0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 56,
                          color: Color(0xFFC9A84C),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'チート\nモンスター',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: const Color(0xFF1A1A3E),
                                fontSize: 44,
                                height: 1.1,
                                letterSpacing: 3,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'チートスキルで最強モンスターを作れ！',
                          style: TextStyle(
                            color: Color(0xFF5D5A72),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFC9A84C)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 18,
                                color: canPlay
                                    ? const Color(0xFFC9A84C)
                                    : const Color(0xFFC0392B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '本日の残りバトル: $remaining / 5',
                                style: TextStyle(
                                  color: canPlay
                                      ? const Color(0xFF2B4C8C)
                                      : const Color(0xFFC0392B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Summon button
                        Opacity(
                          opacity: canPlay ? 1.0 : 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFC9A84C),
                                  Color(0xFFB8943F),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC9A84C)
                                      .withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: canPlay
                                    ? () {
                                        game.reset();
                                        Navigator.pushNamed(
                                            context, '/summon');
                                      }
                                    : null,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 52, vertical: 17),
                                  child: Text(
                                    '召喚する',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // PvP button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6C3D91),
                                Color(0xFF8B5CB5),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C3D91)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                game.reset();
                                game.setGameMode(GameMode.online);
                                Navigator.pushNamed(context, '/room');
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 52, vertical: 17),
                                child: Text(
                                  '対人対戦',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (game.pvpTotalMatches > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFC9A84C)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  size: 18,
                                  color: Color(0xFFC9A84C),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '戦績: ${game.pvpWins}勝 / ${game.pvpTotalMatches}戦',
                                  style: const TextStyle(
                                    color: Color(0xFF2B4C8C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!canPlay) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '明日またバトルできます！',
                            style: TextStyle(color: Color(0xFF5D5A72)),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
