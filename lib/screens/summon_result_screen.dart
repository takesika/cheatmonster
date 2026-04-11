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
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: SizedBox.expand(
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
                    const SizedBox(height: 80),
                    _buildSummoningEffect(),
                  ] else ...[
                    const SizedBox(height: 40),
                    Text(
                      game.isGeneratingImage ? '召喚中...' : '召喚成功！',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFFFFB300),
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF2196F3).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              Navigator.pushNamed(context, '/battle');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 16),
                              child: Text(
                                'バトルへ！',
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
                      )
                    else
                      const Text(
                        '画像を生成中...',
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
                        color:
                            const Color(0xFFFFB300).withOpacity(0.6 * value),
                        blurRadius: 40 * value,
                        spreadRadius: 20 * value,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: Color(0xFFFFB300),
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
            color: Color(0xFF2196F3),
            fontSize: 18,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
