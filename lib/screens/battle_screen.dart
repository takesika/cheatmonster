import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/battle_result.dart';
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
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              if (game.playerMonster == null || game.cpuMonster == null) {
                return const Center(child: CircularProgressIndicator());
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
                          ?.copyWith(color: const Color(0xFF333333)),
                    ),
                    const SizedBox(height: 8),
                    const Text('VS',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB300))),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          MonsterCard(monster: game.playerMonster!),
                          AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (context, _) {
                              final showFront = _flipAnim.value > 0.5;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(
                                      (1 - _flipAnim.value) * 3.14159),
                                child: showFront
                                    ? MonsterCard(
                                        monster: game.cpuMonster!,
                                        isLoading: game.isGeneratingCpuImage)
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFFF5252)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => game.startBattle(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                child: Text(
                  '戦う！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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
            CircularProgressIndicator(color: Color(0xFF2196F3)),
            SizedBox(height: 12),
            Text('LLMが戦闘を審判中...',
                style: TextStyle(color: Color(0xFF666666))),
          ],
        );
      case BattlePhase.result:
        return _buildResult(context, game);
    }
  }

  Widget _buildResult(BuildContext context, GameProvider game) {
    final result = game.battleResult!;
    final outcomeText = switch (result.outcome) {
      BattleOutcome.win => 'WIN!',
      BattleOutcome.lose => 'LOSE...',
      BattleOutcome.draw => 'DRAW',
    };
    final outcomeColor = switch (result.outcome) {
      BattleOutcome.win => const Color(0xFFFFB300),
      BattleOutcome.lose => Colors.blueGrey,
      BattleOutcome.draw => const Color(0xFF888888),
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
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF2196F3).withOpacity(0.1),
          ),
          child: Text(
            result.narration,
            style: const TextStyle(color: Color(0xFF555555), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                child: Text(
                  'もう一度',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
