import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/battle_result.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
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
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
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
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 220,
                height: 220,
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
            SafeArea(
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
                                  color: const Color(0xFF1A1A3E)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFC9A84C),
                            shadows: [
                              Shadow(
                                color: const Color(0xFFC9A84C)
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
          ],
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
              CircularProgressIndicator(color: Color(0xFFC9A84C)),
              SizedBox(height: 12),
              Text('ジャッジを待機中...',
                  style: TextStyle(color: Color(0xFF5D5A72))),
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC0392B).withOpacity(0.3),
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
                if (isOnline) {
                  game.startOnlineBattle();
                } else {
                  game.startBattle();
                }
              },
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                child: Text(
                  '戦う！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        );
      case BattlePhase.battling:
        return const Column(
          children: [
            CircularProgressIndicator(color: Color(0xFFC9A84C)),
            SizedBox(height: 12),
            Text('LLMが戦闘を審判中...',
                style: TextStyle(color: Color(0xFF5D5A72))),
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
      BattleOutcome.win => const Color(0xFFC9A84C),
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
                      color: const Color(0xFFC9A84C).withOpacity(0.5),
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
              left: BorderSide(color: Color(0xFFC9A84C), width: 3),
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
                const TextStyle(color: Color(0xFF5D5A72), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFC9A84C), Color(0xFFB8943F)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC9A84C).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                child: Text(
                  'もう一度',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
