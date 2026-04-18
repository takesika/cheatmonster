import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/battle_result.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_card.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

enum BattlePhase { reveal, ready, battling, result }

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  BattlePhase _phase = BattlePhase.reveal;
  late AnimationController _revealController;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _revealController.forward().then((_) {
          if (mounted) setState(() => _phase = BattlePhase.ready);
        });
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              if (game.playerMonster == null ||
                  game.cpuMonster == null) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (game.battleResult != null &&
                  _phase != BattlePhase.result) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _phase = BattlePhase.result);
                  }
                });
              }
              if (game.isBattling &&
                  _phase != BattlePhase.battling) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _phase = BattlePhase.battling);
                  }
                });
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      _phaseTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                        shadows: [
                          Shadow(
                            color: AppColors.gold
                                .withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          MonsterCard(
                              monster: game.playerMonster!),
                          AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (context, _) {
                              final showFront =
                                  _flipAnim.value > 0.5;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(
                                      (1 - _flipAnim.value) *
                                          3.14159),
                                child: showFront
                                    ? MonsterCard(
                                        monster: game.cpuMonster!,
                                        isLoading: game
                                            .isGeneratingCpuImage)
                                    : MonsterCard(
                                        monster: game.cpuMonster!,
                                        showBack: true),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBottomArea(context, game),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String get _phaseTitle {
    switch (_phase) {
      case BattlePhase.reveal:
        return '対戦相手が現れた...';
      case BattlePhase.ready:
        return 'バトル準備完了！';
      case BattlePhase.battling:
        return 'ジャッジ中...';
      case BattlePhase.result:
        return '結果発表！';
    }
  }

  Widget _buildBottomArea(BuildContext context, GameProvider game) {
    switch (_phase) {
      case BattlePhase.reveal:
        return const SizedBox(height: 48);
      case BattlePhase.ready:
        final isOnline = game.gameMode == GameMode.online;
        final isPlayer2 = isOnline && game.playerNumber == 2;

        if (isPlayer2) {
          if (!game.isBattling && game.battleResult == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              game.startOnlineBattle();
            });
          }
          return const Column(
            children: [
              CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 12),
              Text('ジャッジを待機中...',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          );
        }

        return GradientButton(
          label: '戦う！',
          fontSize: 22,
          letterSpacing: 3,
          gradientColors: const [AppColors.ruby, Color(0xFFE74C3C)],
          shadowColor: AppColors.ruby,
          onTap: () {
            if (isOnline) {
              game.startOnlineBattle();
            } else {
              game.startBattle();
            }
          },
        );
      case BattlePhase.battling:
        return const Column(
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: 12),
            Text('LLMが戦闘を審判中...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        );
      case BattlePhase.result:
        return _buildResult(context, game);
    }
  }

  Widget _buildResult(BuildContext context, GameProvider game) {
    final result = game.battleResult!;
    final isOnline = game.gameMode == GameMode.online;

    final displayOutcome = result.outcome;

    final outcomeText = switch (displayOutcome) {
      BattleOutcome.win => 'WIN!',
      BattleOutcome.lose => 'LOSE...',
      BattleOutcome.draw => 'DRAW',
    };

    final isWin = displayOutcome == BattleOutcome.win;
    final outcomeColor = switch (displayOutcome) {
      BattleOutcome.win => AppColors.gold,
      BattleOutcome.lose => const Color(0xFF7B8794),
      BattleOutcome.draw => const Color(0xFF9E9E9E),
    };

    return Column(
      children: [
        Text(
          outcomeText,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: outcomeColor,
            letterSpacing: 4,
            shadows: isWin
                ? [
                    Shadow(
                      color: AppColors.gold.withOpacity(0.5),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            border: const Border(
              left: BorderSide(color: AppColors.gold, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            result.narration,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: 'もう一度',
          fontSize: 18,
          padding: const EdgeInsets.symmetric(
              horizontal: 40, vertical: 14),
          onTap: () async {
            if (isOnline) {
              await game.deleteRoom();
            }
            game.reset();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false);
            }
          },
        ),
      ],
    );
  }
}
