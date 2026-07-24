import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/battle_result.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/arcane_circle.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_card.dart';
import '../widgets/wax_seal.dart';

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

    Future.delayed(const Duration(milliseconds: 800), () {
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
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              if (game.playerMonster == null || game.cpuMonster == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (game.battleResult != null && _phase != BattlePhase.result) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _phase = BattlePhase.result);
                });
              }
              if (game.isBattling && _phase != BattlePhase.battling) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _phase = BattlePhase.battling);
                });
              }

              if (_phase == BattlePhase.result) {
                return _buildResultLayout(context, game);
              }
              return _buildArenaLayout(context, game);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildArenaLayout(BuildContext context, GameProvider game) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.goldLight,
                  AppColors.gold,
                  AppColors.goldDeep,
                ],
              ).createShader(rect),
              child: Text(
                game.gameMode == GameMode.cpu
                    ? 'STAGE ${game.cpuStage} / ${GameConstants.maxCpuStages}'
                    : 'BATTLE ${game.onlineBattleCount} / ${GameConstants.maxOnlineBattles}',
                style: const TextStyle(
                  fontFamily: AppFonts.cinzel,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // arena (fixed height so it can sit inside scroll view)
          SizedBox(
            height: 480,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(
                    child: Center(
                      child: ArcaneCircle(size: 320, opacity: 0.18),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(child: _TaiSymbol()),
                  ),

                  // player card top-left
                  Positioned(
                    top: 20,
                    left: 12,
                    child: _CardWithLabel(
                      label: 'YOU',
                      labelColor: AppColors.panel,
                      rotation: -0.09,
                      child: MonsterCard(
                        monster: game.playerMonster!,
                        scale: 0.78,
                        selected: true,
                      ),
                    ),
                  ),

                  // enemy card bottom-right with flip
                  Positioned(
                    bottom: 20,
                    right: 12,
                    child: AnimatedBuilder(
                      animation: _flipAnim,
                      builder: (context, _) {
                        final showFront = _flipAnim.value > 0.5;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY((1 - _flipAnim.value) * pi),
                          child: _CardWithLabel(
                            label: 'ENEMY',
                            labelColor: AppColors.seal,
                            rotation: 0.09,
                            child: showFront
                                ? MonsterCard(
                                    monster: game.cpuMonster!,
                                    scale: 0.78,
                                    isLoading: game.isGeneratingCpuImage,
                                  )
                                : MonsterCard(
                                    monster: game.cpuMonster!,
                                    scale: 0.78,
                                    showBack: true,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _bottomCta(context, game),
          ),
        ],
      ),
    );
  }

  Widget _bottomCta(BuildContext context, GameProvider game) {
    if (_phase == BattlePhase.reveal) {
      return const _OracleSpinner(text: '対戦相手が現れた...');
    }
    if (_phase == BattlePhase.battling) {
      return const _OracleSpinner(text: 'ジャッジ中...');
    }
    // ready phase
    final isOnline = game.gameMode == GameMode.online;
    final isPlayer2 = isOnline && game.playerNumber == 2;
    if (isPlayer2) {
      if (!game.isBattling && game.battleResult == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          game.startOnlineBattle();
        });
      }
      return const _OracleSpinner(text: '相手の操作を待機中...');
    }
    return GradientButton(
      label: '開戦',
      variant: CmButtonVariant.crimson,
      fontSize: 18,
      letterSpacing: 8,
      padding: const EdgeInsets.symmetric(vertical: 16),
      fullWidth: true,
      onTap: () {
        if (isOnline) {
          game.startOnlineBattle();
        } else {
          game.startBattle();
        }
      },
    );
  }

  Widget _buildResultLayout(BuildContext context, GameProvider game) {
    final result = game.battleResult!;
    final isOnline = game.gameMode == GameMode.online;
    final isCpu = game.gameMode == GameMode.cpu;
    final outcome = result.outcome;
    final isWin = outcome == BattleOutcome.win;
    final isDraw = outcome == BattleOutcome.draw;
    final outcomeLabel = isDraw ? 'DRAW' : (isWin ? 'WIN' : 'LOSE');
    final sealLabel = isDraw ? '和' : (isWin ? '勝' : '敗');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.goldLight,
                AppColors.gold,
                AppColors.goldDeep,
              ],
            ).createShader(rect),
            child: const Text(
              '結果',
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: _ParchmentResultPanel(
                outcomeLabel: outcomeLabel,
                sealLabel: sealLabel,
                player: game.playerMonster!,
                enemy: game.cpuMonster!,
                playerFaded: !isWin && !isDraw,
                enemyFaded: isWin,
                narration: result.narration,
                stageInfo: isCpu
                    ? 'STAGE ${game.cpuStage} / ${GameConstants.maxCpuStages}'
                    : isOnline
                        ? 'BATTLE ${game.onlineBattleCount} / ${GameConstants.maxOnlineBattles}'
                        : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isOnline)
            _buildOnlineButtons(context, game)
          else
            _buildCpuButtons(context, game, outcome),
        ],
      ),
    );
  }

  void _handleContinue(GameProvider game) {
    setState(() => _waitingForOpponentChoice = true);
    game.setContinue();

    _timeoutTimer = Timer(const Duration(seconds: GameConstants.timeoutSeconds),
        () {
      _continueStatusSubscription?.cancel();
      if (!mounted) return;
      _goHomeWithMessage(game, '相手の応答がありませんでした');
    });

    _continueStatusSubscription = game.listenForContinueStatus().listen(
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
          variant: CmButtonVariant.crimson,
          fontSize: 14,
          letterSpacing: 4,
          padding: const EdgeInsets.symmetric(vertical: 14),
          fullWidth: true,
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
            const Text(
              '全ステージクリア',
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.goldLight,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'ホームへ',
              variant: CmButtonVariant.gold,
              fontSize: 14,
              letterSpacing: 4,
              padding: const EdgeInsets.symmetric(vertical: 14),
              fullWidth: true,
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
    }
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: 'ホームへ',
            variant: CmButtonVariant.goldOutline,
            fontSize: 12,
            letterSpacing: 4,
            padding: const EdgeInsets.symmetric(vertical: 12),
            fullWidth: true,
            onTap: () {
              game.reset();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineButtons(BuildContext context, GameProvider game) {
    if (_waitingForOpponentChoice) {
      return const _OracleSpinner(text: '相手の選択を待っています...');
    }
    if (game.onlineBattleCount >= GameConstants.maxOnlineBattles) {
      return GradientButton(
        label: '終わる',
        variant: CmButtonVariant.gold,
        fontSize: 14,
        letterSpacing: 4,
        padding: const EdgeInsets.symmetric(vertical: 14),
        fullWidth: true,
        onTap: () => _handleQuit(game),
      );
    }
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: '終わる',
            variant: CmButtonVariant.goldOutline,
            fontSize: 12,
            letterSpacing: 4,
            padding: const EdgeInsets.symmetric(vertical: 12),
            fullWidth: true,
            onTap: () => _handleQuit(game),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GradientButton(
            label: '続行',
            variant: CmButtonVariant.crimson,
            fontSize: 14,
            letterSpacing: 4,
            padding: const EdgeInsets.symmetric(vertical: 12),
            fullWidth: true,
            onTap: () => _handleContinue(game),
          ),
        ),
      ],
    );
  }
}

class _CardWithLabel extends StatelessWidget {
  final String label;
  final Color labelColor;
  final double rotation;
  final Widget child;
  const _CardWithLabel({
    required this.label,
    required this.labelColor,
    required this.rotation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: -14,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.9),
                border: Border.all(color: AppColors.gold, width: 0.5),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.cinzel,
                  color: AppColors.goldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaiSymbol extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldLight,
          AppColors.seal,
          AppColors.sealDeep,
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(rect),
      child: Text(
        'VS',
        style: TextStyle(
          fontFamily: AppFonts.cinzel,
          fontSize: 140,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 4,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _OracleSpinner extends StatelessWidget {
  final String text;
  const _OracleSpinner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            fontFamily: AppFonts.mincho,
            color: AppColors.inkSoft,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class _ParchmentResultPanel extends StatelessWidget {
  final String outcomeLabel;
  final String sealLabel;
  final dynamic player;
  final dynamic enemy;
  final bool playerFaded;
  final bool enemyFaded;
  final String narration;
  final String? stageInfo;

  const _ParchmentResultPanel({
    required this.outcomeLabel,
    required this.sealLabel,
    required this.player,
    required this.enemy,
    required this.playerFaded,
    required this.enemyFaded,
    required this.narration,
    this.stageInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0E2C0), Color(0xFFD8C298)],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.goldDeep),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outcomeLabel,
                      style: const TextStyle(
                        fontFamily: AppFonts.cinzel,
                        color: AppColors.sealDeep,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    if (stageInfo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        stageInfo!,
                        style: const TextStyle(
                          fontFamily: AppFonts.cinzel,
                          color: AppColors.inkSoftDark,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              WaxSeal(label: sealLabel, size: 76, rotation: -0.14),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MonsterCard(monster: player, scale: 0.42, faded: playerFaded),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontFamily: AppFonts.cinzel,
                    color: AppColors.sealDeep,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              MonsterCard(monster: enemy, scale: 0.42, faded: enemyFaded),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.goldDeep, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              narration,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.inkDark,
                fontSize: 13,
                height: 1.9,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
