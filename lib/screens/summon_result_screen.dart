import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/monster_card.dart';

class SummonResultScreen extends StatefulWidget {
  const SummonResultScreen({super.key});

  @override
  State<SummonResultScreen> createState() => _SummonResultScreenState();
}

class _SummonResultScreenState extends State<SummonResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  bool _showCard = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Start card reveal after a short delay (summoning effect)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showCard = true);
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
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
              final monster = game.playerMonster;
              if (monster == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_showCard) ...[
                    // Summoning effect
                    const SizedBox(height: 80),
                    _buildSummoningEffect(),
                  ] else ...[
                    const SizedBox(height: 40),
                    Text(
                      '召喚成功！',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.deepPurpleAccent,
                              ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnim.value,
                          child: Opacity(
                            opacity: _opacityAnim.value,
                            child: MonsterCard(
                              monster: monster,
                              isLoading: game.isGeneratingImage,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    if (!game.isGeneratingImage)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/battle');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('バトルへ！'),
                      )
                    else
                      const Text(
                        '画像を生成中...',
                        style: TextStyle(color: Colors.white38),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummoningEffect() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.5 + value * 0.5,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withOpacity(0.6 * value),
                        blurRadius: 40 * value,
                        spreadRadius: 20 * value,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          '召喚中...',
          style: TextStyle(
            color: Colors.deepPurpleAccent,
            fontSize: 18,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
