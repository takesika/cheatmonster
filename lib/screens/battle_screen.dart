import 'dart:async';

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

  bool _waitingForOpponentChoice = false;
  StreamSubscription<String>? _continueStatusSubscription;
  Timer? _timeoutTimer;

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
    _continueStatusSubscription?.cancel();
    _timeoutTimer?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

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
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            fontSize: 32 * scale,
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
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            MonsterCard(
                                monster: game.playerMonster!),
                            Column(
                              children: [
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
                                if (game.gameMode == GameMode.online &&
                                    game.opponentPvpTotalMatches > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '相手戦績: ${game.opponentPvpWins}勝 / ${game.opponentPvpTotalMatches}戦',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildBottomArea(context, game, scale),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
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

  Widget _buildBottomArea(BuildContext context, GameProvider game, double scale) {
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
          fontSize: 22 * scale,
          letterSpacing: 3,
          padding: EdgeInsets.symmetric(
              horizontal: 48 * scale, vertical: 16 * scale),
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
        return _buildResult(context, game, scale);
    }
  }

  Widget _buildResult(BuildContext context, GameProvider game, double scale) {
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

    final isCpu = game.gameMode == GameMode.cpu;

    return Column(
      children: [
        if (isOnline)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${game.onlineBattleCount} / ${GameConstants.maxOnlineBattles} 戦',
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        if (isCpu)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'ステージ ${game.cpuStage} / ${GameConstants.maxCpuStages}',
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Text(
          outcomeText,
          style: TextStyle(
            fontSize: 36 * scale,
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
        if (isOnline)
          _buildOnlineButtons(context, game, scale)
        else
          _buildCpuButtons(context, game, displayOutcome),
      ],
    );
  }

  void _handleContinue(GameProvider game) {
    setState(() => _waitingForOpponentChoice = true);

    game.setContinue();

    _timeoutTimer = Timer(const Duration(seconds: GameConstants.timeoutSeconds), () {
      _continueStatusSubscription?.cancel();
      if (!mounted) return;
      _goHomeWithMessage(game, '相手の応答がありませんでした');
    });

    _continueStatusSubscription =
        game.listenForContinueStatus().listen(
      (status) async {
        if (!mounted) return;
        if (status == 'continue') {
          _continueStatusSubscription?.cancel();
          _timeoutTimer?.cancel();
          await game.resetRoomForNextBattle();
          game.resetForNextBattle();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/summon', (route) => false);
          }
        } else if (status == 'quit') {
          _continueStatusSubscription?.cancel();
          _timeoutTimer?.cancel();
          _goHomeWithMessage(game, '相手が退出しました');
        }
      },
    );
  }

  void _handleQuit(GameProvider game) async {
    await game.setQuit();
    await Future.delayed(const Duration(milliseconds: 500));
    await game.deleteRoom();
    game.reset();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _goHomeWithMessage(GameProvider game, String message) async {
    await game.deleteRoom();
    game.reset();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Widget _buildCpuButtons(
      BuildContext context, GameProvider game, BattleOutcome outcome) {
    if (outcome == BattleOutcome.win) {
      if (game.cpuStage < GameConstants.maxCpuStages) {
        return GradientButton(
          label: '次のステージへ',
          fontSize: 18,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          gradientColors: const [AppColors.gold, AppColors.goldLight],
          shadowColor: AppColors.gold,
          onTap: () {
            game.resetForNextCpuStage();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/summon', (route) => false);
            }
          },
        );
      } else {
        return Column(
          children: [
            Text(
              '全ステージクリア！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
                shadows: [
                  Shadow(
                    color: AppColors.gold.withOpacity(0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'ホームへ',
              fontSize: 18,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              gradientColors: const [AppColors.gold, AppColors.goldLight],
              shadowColor: AppColors.gold,
              onTap: () {
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
    } else {
      return GradientButton(
        label: 'ホームへ戻る',
        fontSize: 18,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        onTap: () {
          game.reset();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false);
          }
        },
      );
    }
  }

  Widget _buildOnlineButtons(
      BuildContext context, GameProvider game, double scale) {
    if (_waitingForOpponentChoice) {
      return const Column(
        children: [
          CircularProgressIndicator(color: AppColors.gold),
          SizedBox(height: 12),
          Text(
            '相手の選択を待っています...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    if (game.onlineBattleCount >= GameConstants.maxOnlineBattles) {
      return GradientButton(
        label: '終わる',
        fontSize: 18,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        onTap: () => _handleQuit(game),
      );
    }

    return Column(
      children: [
        GradientButton(
          label: '続行',
          fontSize: 18,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          onTap: () => _handleContinue(game),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _handleQuit(game),
          child: const Text(
            '終わる',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
