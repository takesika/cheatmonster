import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_mode.dart';
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
            colors: [Color(0xFFF5F0EB), Color(0xFFE8E0F0)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -30,
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
              bottom: -40,
              right: -40,
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
                                  color: const Color(0xFFC9A84C),
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
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFC9A84C),
                                    Color(0xFFB8943F),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC9A84C)
                                        .withOpacity(0.35),
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 48, vertical: 16),
                                    child: Text(
                                      isOnline ? '準備完了！' : 'バトルへ！',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
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
                              style: TextStyle(color: Color(0xFF5D5A72)),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
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
                        color: const Color(0xFFC9A84C)
                            .withOpacity(0.5 * value),
                        blurRadius: 50 * value,
                        spreadRadius: 25 * value,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: Color(0xFFC9A84C),
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
            color: Color(0xFF2B4C8C),
            fontSize: 18,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
