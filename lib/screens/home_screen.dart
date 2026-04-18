import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';

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
      body: GameBackground(
        child: Stack(
          children: [
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
                      color: AppColors.gold.withOpacity(0.06),
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
                          color: AppColors.gold,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'チート\nモンスター',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 44,
                                height: 1.1,
                                letterSpacing: 3,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'チートスキルで最強モンスターを作れ！',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                              color: AppColors.gold
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
                                    ? AppColors.gold
                                    : AppColors.ruby,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '本日の残りバトル: $remaining / 5',
                                style: TextStyle(
                                  color: canPlay
                                      ? AppColors.sapphire
                                      : AppColors.ruby,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Opacity(
                          opacity: canPlay ? 1.0 : 0.4,
                          child: GradientButton(
                            label: 'CPU対戦',
                            fontSize: 19,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 52, vertical: 17),
                            onTap: canPlay
                                ? () {
                                    game.reset();
                                    Navigator.pushNamed(
                                        context, '/summon');
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: '対人戦',
                          fontSize: 19,
                          gradientColors: const [
                            AppColors.amethyst,
                            AppColors.amethystLight,
                          ],
                          shadowColor: AppColors.amethyst,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 52, vertical: 17),
                          onTap: () {
                            game.reset();
                            game.setGameMode(GameMode.online);
                            Navigator.pushNamed(context, '/room');
                          },
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
                                color: AppColors.gold
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  size: 18,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '対人戦績: ${game.pvpWins}勝 / ${game.pvpTotalMatches}戦',
                                  style: const TextStyle(
                                    color: AppColors.sapphire,
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
                            style: TextStyle(color: AppColors.textSecondary),
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
