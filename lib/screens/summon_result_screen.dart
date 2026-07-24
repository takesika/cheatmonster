import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/arcane_circle.dart';
import '../widgets/fleur_divider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_card.dart';
import '../widgets/wax_seal.dart';

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
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    Future.delayed(const Duration(milliseconds: 700), () {
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
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              final isOnline = game.gameMode == GameMode.online;
              final monster = game.playerMonster;
              if (monster == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              return Stack(
                children: [
                  const Positioned.fill(
                    child: Center(
                      child: ArcaneCircle(size: 380, opacity: 0.22),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (rect) => const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.goldLight,
                                    AppColors.gold,
                                    AppColors.goldDeep
                                  ],
                                ).createShader(rect),
                                child: const Text(
                                  '召喚成功',
                                  style: TextStyle(
                                    fontFamily: AppFonts.mincho,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 6,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const FleurDivider(small: true),
                              const SizedBox(height: 24),
                              !_showCard
                                  ? _SummoningEffect()
                                  : AnimatedBuilder(
                                      animation: _animController,
                                      builder: (context, _) {
                                        return Opacity(
                                          opacity: _opacityAnim.value,
                                          child: Transform.scale(
                                            scale: _scaleAnim.value,
                                            child: MonsterCard(
                                              monster: monster,
                                              isLoading: game.isGeneratingImage,
                                              scale: 1.0,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              const SizedBox(height: 24),
                              game.isGeneratingImage
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 18),
                                      child: Text(
                                        '画像を生成中...',
                                        style: TextStyle(
                                          fontFamily: AppFonts.mincho,
                                          color: AppColors.inkSoft,
                                          letterSpacing: 2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : GradientButton(
                                      label: isOnline ? '準備完了' : 'バトルへ',
                                      variant: CmButtonVariant.crimson,
                                      fontSize: 16,
                                      letterSpacing: 6,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      fullWidth: true,
                                      onTap: () => _onContinue(
                                          context, game, isOnline),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue(
      BuildContext context, GameProvider game, bool isOnline) async {
    if (isOnline) {
      try {
        await game.submitMonster();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('モンスターデータの送信に失敗しました')),
          );
        }
        return;
      }
      if (context.mounted) {
        Navigator.pushNamed(context, '/waiting');
      }
    } else {
      Navigator.pushNamed(context, '/battle');
    }
  }
}

class _SummoningEffect extends StatefulWidget {
  @override
  State<_SummoningEffect> createState() => _SummoningEffectState();
}

class _SummoningEffectState extends State<_SummoningEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            return Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow.withOpacity(0.3 + 0.4 * t),
                    blurRadius: 40 + 20 * t,
                    spreadRadius: 10 + 10 * t,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 60,
                    color: AppColors.goldLight.withOpacity(0.6 + 0.4 * t),
                    fontFamily: AppFonts.cinzel,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        const Text(
          '召喚中...',
          style: TextStyle(
            fontFamily: AppFonts.mincho,
            color: AppColors.goldLight,
            fontSize: 16,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
