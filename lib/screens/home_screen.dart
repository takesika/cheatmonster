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
          child: Center(
            child: Consumer<GameProvider>(
              builder: (context, game, _) {
                final remaining = game.remainingBattles;
                final canPlay = remaining > 0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning,
                      size: 80,
                      color: Color(0xFFFFB300),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'チート\nモンスター',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: const Color(0xFF333333),
                                fontSize: 42,
                                height: 1.2,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'チートスキルで最強モンスターを作れ！',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF666666),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '本日の残りバトル: $remaining / 5',
                      style: TextStyle(
                        color: canPlay
                            ? const Color(0xFF2196F3)
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Opacity(
                      opacity: canPlay ? 1.0 : 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF2196F3).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: canPlay
                                ? () {
                                    game.reset();
                                    Navigator.pushNamed(context, '/summon');
                                  }
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 18),
                              child: Text(
                                '召喚する',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF9C27B0).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            game.reset();
                            game.setGameMode(GameMode.online);
                            Navigator.pushNamed(context, '/room');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 48, vertical: 18),
                            child: Text(
                              '対人対戦',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!canPlay) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '明日またバトルできます！',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
