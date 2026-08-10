import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/battle_result.dart';
import '../models/game_mode.dart';
import '../models/monster.dart';
import '../providers/game_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_art.dart';

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
  late Animation<double> _enemyFade;

  bool _waitingForOpponentChoice = false;
  StreamSubscription<String>? _continueStatusSubscription;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _enemyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
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
      body: Consumer<GameProvider>(
        builder: (context, game, _) {
          if (game.playerMonster == null || game.cpuMonster == null) {
            return const GameBackground(
              dark: true,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.yellow),
              ),
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
            return GameBackground(
              child: SafeArea(child: _buildResultLayout(context, game)),
            );
          }
          return GameBackground(
            dark: true,
            child: SafeArea(child: _buildArenaLayout(context, game)),
          );
        },
      ),
    );
  }

  Widget _buildArenaLayout(BuildContext context, GameProvider game) {
    final stageInfo = game.gameMode == GameMode.cpu
        ? 'STAGE ${game.cpuStage} / ${GameConstants.maxCpuStages}'
        : game.gameMode == GameMode.throne
            ? '王座戦'
            : 'BATTLE ${game.onlineBattleCount + 1} / ${GameConstants.maxOnlineBattles}';

    return Column(
      children: [
        _DarkTopBar(title: stageInfo),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: _enemyFade,
                      child: BattleMonster(
                        imageBytes: game.cpuMonster!.imageBytes,
                        loading: game.isGeneratingCpuImage,
                        name: game.cpuMonster!.name,
                        ability: game.cpuMonster!.specialAbility,
                        alignRight: true,
                        hideAbility: game.gameMode == GameMode.throne,
                      ),
                    ),
                  ),
                  Expanded(
                    child: BattleMonster(
                      imageBytes: game.playerMonster!.imageBytes,
                      name: game.playerMonster!.name,
                      ability: game.playerMonster!.specialAbility,
                      alignRight: false,
                    ),
                  ),
                ],
              ),
              const Positioned.fill(
                child: Center(child: _VsBadge()),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _bottomCta(context, game),
        ),
      ],
    );
  }

  Widget _bottomCta(BuildContext context, GameProvider game) {
    if (_phase == BattlePhase.reveal) {
      return const _DarkSpinner(text: '対戦相手が現れた...');
    }
    if (_phase == BattlePhase.battling) {
      return const _DarkSpinner(text: 'AIがジャッジ中...');
    }
    final isOnline = game.gameMode == GameMode.online;
    final isThrone = game.gameMode == GameMode.throne;
    final isPlayer2 = isOnline && game.playerNumber == 2;
    if (isPlayer2) {
      if (!game.isBattling && game.battleResult == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          game.startOnlineBattle();
        });
      }
      return const _DarkSpinner(text: '相手の操作を待機中...');
    }
    return GradientButton(
      label: '開戦',
      icon: Icons.sports_kabaddi,
      variant: CmButtonVariant.yellow,
      fontSize: 17,
      letterSpacing: 2,
      padding: const EdgeInsets.symmetric(vertical: 18),
      fullWidth: true,
      onTap: () {
        if (isThrone) {
          game.startThroneBattle();
        } else if (isOnline) {
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
    final outcome = result.outcome;
    final isWin = outcome == BattleOutcome.win;
    final isDraw = outcome == BattleOutcome.draw;

    // Hero card shows: winner on win/lose, player's monster on draw
    final displayMonster = isDraw
        ? game.playerMonster!
        : (isWin ? game.playerMonster! : game.cpuMonster!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultHeader(isWin: isWin, isDraw: isDraw),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResultHeroCard(
                    monster: displayMonster,
                    // In throne mode, the champion's ability stays hidden
                    // unless the throne actually changes. On lose, the
                    // displayed monster IS the still-reigning champion.
                    hideAbility:
                        game.gameMode == GameMode.throne && !isWin && !isDraw,
                  ),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    // The narration often describes the champion's ability
                    // by name. Hide it in throne mode unless the throne
                    // actually changed (i.e., the player won).
                    final hideNarration =
                        game.gameMode == GameMode.throne && !isWin;
                    return Text(
                      hideNarration
                          ? '王者は玉座を守り抜いた。その力の正体は闇に伏せられたまま。'
                          : result.narration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.gothic,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMid,
                        fontStyle: hideNarration
                            ? FontStyle.italic
                            : FontStyle.normal,
                        height: 1.7,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  _MatchupSummary(
                    player: game.playerMonster!,
                    enemy: game.cpuMonster!,
                    playerFaded: !isWin && !isDraw,
                    enemyFaded: isWin,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (game.gameMode == GameMode.throne)
            _buildThroneButtons(context, game)
          else if (isOnline)
            _buildOnlineButtons(context, game)
          else
            _buildCpuButtons(context, game, outcome),
        ],
      ),
    );
  }

  Widget _buildThroneButtons(BuildContext context, GameProvider game) {
    final outcome = game.battleResult!.outcome;
    final crowned = game.throneCrowned;
    final outdated = game.throneOutdated;
    final label = crowned
        ? '王座に君臨した'
        : outdated
            ? '王者は交代済み'
            : outcome == BattleOutcome.win
                ? '王座への昇格に失敗'
                : outcome == BattleOutcome.draw
                    ? '引き分け — 王座は守られた'
                    : '王者に敗北した';
    final color = crowned
        ? AppColors.win
        : (outdated || outcome != BattleOutcome.win
            ? AppColors.inkMid
            : AppColors.red);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        GradientButton(
          label: '王者を見る',
          icon: Icons.emoji_events_outlined,
          variant: CmButtonVariant.yellow,
          fontSize: 15,
          padding: const EdgeInsets.symmetric(vertical: 16),
          fullWidth: true,
          onTap: () {
            game.resetForNextBattle();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/throne',
              ModalRoute.withName('/'),
            );
          },
        ),
      ],
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
          icon: Icons.arrow_forward,
          variant: CmButtonVariant.yellow,
          fontSize: 16,
          letterSpacing: 1.2,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              '🏆 全ステージクリア',
              style: TextStyle(
                fontFamily: AppFonts.gothic,
                color: AppColors.win,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            GradientButton(
              label: 'ホームへ戻る',
              icon: Icons.home_outlined,
              variant: CmButtonVariant.ink,
              fontSize: 15,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
    return GradientButton(
      label: 'ホームへ戻る',
      icon: Icons.home_outlined,
      variant: CmButtonVariant.ghost,
      fontSize: 15,
      padding: const EdgeInsets.symmetric(vertical: 16),
      fullWidth: true,
      onTap: () {
        game.reset();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      },
    );
  }

  Widget _buildOnlineButtons(BuildContext context, GameProvider game) {
    if (_waitingForOpponentChoice) {
      return const _LightSpinner(text: '相手の選択を待っています...');
    }
    if (game.onlineBattleCount >= GameConstants.maxOnlineBattles ||
        game.remainingBattles <= 0) {
      return Column(
        children: [
          if (game.remainingBattles <= 0)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '本日の召喚権を使い切りました',
                style: TextStyle(
                  fontFamily: AppFonts.gothic,
                  color: AppColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          GradientButton(
            label: '終わる',
            variant: CmButtonVariant.ink,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(vertical: 16),
            fullWidth: true,
            onTap: () => _handleQuit(game),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: '終わる',
            variant: CmButtonVariant.ghost,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(vertical: 14),
            fullWidth: true,
            onTap: () => _handleQuit(game),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GradientButton(
            label: '続行',
            icon: Icons.replay,
            variant: CmButtonVariant.yellow,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(vertical: 14),
            fullWidth: true,
            onTap: () => _handleContinue(game),
          ),
        ),
      ],
    );
  }
}

class _DarkTopBar extends StatelessWidget {
  final String title;
  const _DarkTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE27A), AppColors.yellowDeep],
      ).createShader(rect),
      child: Text(
        'VS',
        style: TextStyle(
          fontFamily: AppFonts.gothic,
          fontSize: 44,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Colors.white,
          height: 1,
          shadows: [
            Shadow(
              color: AppColors.yellowDeep.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkSpinner extends StatelessWidget {
  final String text;
  const _DarkSpinner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightSpinner extends StatelessWidget {
  final String text;
  const _LightSpinner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final bool isWin;
  final bool isDraw;
  const _ResultHeader({required this.isWin, required this.isDraw});

  @override
  Widget build(BuildContext context) {
    final label = isDraw ? '引き分け' : (isWin ? '勝利' : '敗北');
    final color = isDraw
        ? AppColors.inkMid
        : (isWin ? AppColors.win : AppColors.red);
    final subtitle = isDraw
        ? '互角の勝負でした'
        : (isWin
            ? 'あなたのモンスターが勝ちました'
            : 'あなたのモンスターは破れました');
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMid,
          ),
        ),
      ],
    );
  }
}

class _ResultHeroCard extends StatelessWidget {
  final Monster monster;
  final bool hideAbility;
  const _ResultHeroCard({required this.monster, this.hideAbility = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          Positioned.fill(
            child: MonsterArt(imageBytes: monster.imageBytes, radius: 20),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.dark.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    monster.name,
                    style: TextStyle(
                      fontFamily: AppFonts.gothic,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hideAbility ? '「? ? ? ? ?」' : '「${monster.specialAbility}」',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.gothic,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchupSummary extends StatelessWidget {
  final Monster player;
  final Monster enemy;
  final bool playerFaded;
  final bool enemyFaded;
  const _MatchupSummary({
    required this.player,
    required this.enemy,
    required this.playerFaded,
    required this.enemyFaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: _MiniStats(monster: player, faded: playerFaded, label: 'YOU')),
          Container(width: 1, height: 40, color: AppColors.line),
          Expanded(child: _MiniStats(monster: enemy, faded: enemyFaded, label: 'ENEMY')),
        ],
      ),
    );
  }
}

class _MiniStats extends StatelessWidget {
  final Monster monster;
  final bool faded;
  final String label;
  const _MiniStats({required this.monster, required this.faded, required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.45 : 1.0,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.inkSoft,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            monster.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ATK ${monster.atk} / DEF ${monster.def}',
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMid,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
