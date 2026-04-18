import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
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
      body: GameBackground(
        child: SafeArea(
          child: SizedBox.expand(
            child: Consumer<GameProvider>(
              builder: (context, game, _) {
                final isOnline = game.gameMode == GameMode.online;
                final monster = game.playerMonster;
                if (monster == null) {
                  return const Center(
                      child: CircularProgressIndicator());
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
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
                        GradientButton(
                          label: isOnline ? '準備完了！' : 'バトルへ！',
                          fontSize: 18,
                          onTap: () async {
                            if (isOnline) {
                              try {
                                await game.submitMonster();
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'モンスターデータの送信に失敗しました'),
                                    ),
                                  );
                                }
                                return;
                              }
                              if (context.mounted) {
                                Navigator.pushNamed(
                                    context, '/waiting');
                              }
                            } else {
                              Navigator.pushNamed(
                                  context, '/battle');
                            }
                          },
                        )
                      else
                        const Text(
                          '画像を生成中...',
                          style: TextStyle(color: AppColors.textSecondary),
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
                        color: AppColors.gold
                            .withOpacity(0.5 * value),
                        blurRadius: 50 * value,
                        spreadRadius: 25 * value,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: AppColors.gold,
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
            color: AppColors.sapphire,
            fontSize: 18,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
