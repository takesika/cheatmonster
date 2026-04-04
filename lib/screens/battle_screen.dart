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

    // CPU card flip reveal after delay
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
            colors: [Color(0xFF0D001A), Color(0xFF1A0033)],
          ),
        ),
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              if (game.playerMonster == null || game.cpuMonster == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // Update phase when battle result arrives
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
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('VS',
                        style: TextStyle(
                            fontSize: 24, color: Colors.deepPurpleAccent)),
                    const SizedBox(height: 16),
                    // Cards
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Player card
                          MonsterCard(monster: game.playerMonster!),
                          // CPU card with flip animation
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
                    // Bottom area
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
        return ElevatedButton(
          onPressed: () {
            game.startBattle();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          ),
          child: const Text('戦う！', style: TextStyle(fontSize: 20)),
        );
      case BattlePhase.battling:
        return const Column(
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 12),
            Text('LLMが戦闘を審判中...',
                style: TextStyle(color: Colors.white54)),
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
      BattleOutcome.win => Colors.amber,
      BattleOutcome.lose => Colors.blueGrey,
      BattleOutcome.draw => Colors.white70,
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
            color: Colors.deepPurple.withOpacity(0.2),
          ),
          child: Text(
            result.narration,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('もう一度'),
        ),
      ],
    );
  }
}
