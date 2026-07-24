import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_art.dart';

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
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
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
                  child: CircularProgressIndicator(color: AppColors.yellow),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight - 32),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            const _SuccessTitle(),
                            const SizedBox(height: 20),
                            !_showCard
                                ? _SummoningEffect()
                                : AnimatedBuilder(
                                    animation: _animController,
                                    builder: (context, _) {
                                      return Opacity(
                                        opacity: _opacityAnim.value,
                                        child: Transform.scale(
                                          scale: _scaleAnim.value,
                                          child: _MonsterHero(
                                            imageBytes: monster.imageBytes,
                                            loading: game.isGeneratingImage,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            if (_showCard) ...[
                              const SizedBox(height: 18),
                              Text(
                                monster.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppFonts.gothic,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkMid,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AbilityLine(
                                text: monster.specialAbility,
                                size: 22,
                              ),
                              const SizedBox(height: 18),
                              StatCards(atk: monster.atk, def: monster.def),
                            ],
                            const Spacer(),
                            const SizedBox(height: 20),
                            game.isGeneratingImage
                                ? const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      '画像を生成中...',
                                      style: TextStyle(
                                        fontFamily: AppFonts.gothic,
                                        color: AppColors.inkSoft,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : GradientButton(
                                    label: isOnline ? '準備完了' : 'バトルへ',
                                    icon: isOnline
                                        ? Icons.check
                                        : Icons.sports_kabaddi,
                                    variant: CmButtonVariant.yellow,
                                    fontSize: 17,
                                    letterSpacing: 1.2,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    fullWidth: true,
                                    onTap: () =>
                                        _onContinue(context, game, isOnline),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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

class _SuccessTitle extends StatelessWidget {
  const _SuccessTitle();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(
          left: 40,
          top: -2,
          child: _Sparkle(size: 20),
        ),
        const Positioned(
          right: 40,
          top: 4,
          child: _Sparkle(size: 16, delayMs: 300),
        ),
        const Text(
          '召喚成功！',
          style: TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _Sparkle extends StatefulWidget {
  final double size;
  final int delayMs;
  const _Sparkle({required this.size, this.delayMs = 0});

  @override
  State<_Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<_Sparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Opacity(
          opacity: 0.4 + 0.6 * _ctrl.value,
          child: Transform.scale(
            scale: 0.9 + 0.25 * _ctrl.value,
            child: Text('✨', style: TextStyle(fontSize: widget.size)),
          ),
        );
      },
    );
  }
}

class _MonsterHero extends StatelessWidget {
  final dynamic imageBytes;
  final bool loading;
  const _MonsterHero({required this.imageBytes, required this.loading});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: MonsterArt(
        imageBytes: imageBytes,
        loading: loading,
        radius: 22,
      ),
    );
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
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.yellowSoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.9 + 0.2 * _ctrl.value,
                    child: Text(
                      '✨',
                      style: TextStyle(
                        fontSize: 64,
                        color: AppColors.yellowDeep
                            .withValues(alpha: 0.6 + 0.4 * _ctrl.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '召喚中...',
                    style: TextStyle(
                      fontFamily: AppFonts.gothic,
                      color: AppColors.inkMid,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
