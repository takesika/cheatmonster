import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_art.dart';

class ThroneScreen extends StatefulWidget {
  const ThroneScreen({super.key});

  @override
  State<ThroneScreen> createState() => _ThroneScreenState();
}

class _ThroneScreenState extends State<ThroneScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameProvider>();
      game.resetThroneFlags();
      game.loadChampion();
      game.loadRemainingBattles();
    });
  }

  void _startChallenge(BuildContext context, GameProvider game) {
    game.resetForNextBattle();
    game.resetThroneFlags();
    game.setGameMode(GameMode.throne);
    Navigator.pushNamed(context, '/summon');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              return Column(
                children: [
                  _TopBar(
                    title: '世界王者',
                    onBack: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: game.isLoadingChampion
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.yellow),
                          )
                        : _body(context, game),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, GameProvider game) {
    if (game.throneErrorMessage != null && game.currentChampion == null) {
      return _ErrorState(
        message: game.throneErrorMessage!,
        onRetry: () => game.loadChampion(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: IntrinsicHeight(
              child: game.currentChampion == null
                  ? _NoChampionView(
                      canChallenge: game.remainingBattles > 0,
                      onChallenge: () => _startChallenge(context, game),
                    )
                  : _ChampionView(
                      game: game,
                      onChallenge: () => _startChallenge(context, game),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const _TopBar({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 18, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left,
                color: AppColors.ink, size: 26),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ChampionView extends StatelessWidget {
  final GameProvider game;
  final VoidCallback onChallenge;
  const _ChampionView({required this.game, required this.onChallenge});

  @override
  Widget build(BuildContext context) {
    final champion = game.currentChampion!;
    final canChallenge = game.remainingBattles > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CrownHeader(label: '現在の世界王者'),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: Stack(
            children: [
              Positioned.fill(
                child: MonsterArt(
                  imageBytes: champion.monster.imageBytes,
                  radius: 20,
                ),
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
                        champion.monster.name,
                        style: TextStyle(
                          fontFamily: AppFonts.gothic,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '「${champion.monster.specialAbility}」',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppFonts.gothic,
                          fontSize: 22,
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
        ),
        const SizedBox(height: 16),
        StatCards(atk: champion.monster.atk, def: champion.monster.def),
        const Spacer(),
        if (game.throneErrorMessage != null) ...[
          _Notice(
            message: game.throneErrorMessage!,
            tone: game.throneOutdated ? _NoticeTone.warning : _NoticeTone.error,
          ),
          const SizedBox(height: 12),
        ],
        GradientButton(
          label: canChallenge ? '王座に挑戦する' : '本日の挑戦は終了',
          icon: canChallenge ? Icons.sports_kabaddi : Icons.hourglass_bottom,
          variant: canChallenge
              ? CmButtonVariant.yellow
              : CmButtonVariant.ghost,
          fontSize: 17,
          padding: const EdgeInsets.symmetric(vertical: 18),
          fullWidth: true,
          onTap: canChallenge ? onChallenge : null,
        ),
        const SizedBox(height: 8),
        Text(
          '挑戦は日次 ${game.remainingBattles} 回残り',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _NoChampionView extends StatelessWidget {
  final bool canChallenge;
  final VoidCallback onChallenge;
  const _NoChampionView({
    required this.canChallenge,
    required this.onChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellowSoft,
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_outlined,
                size: 72, color: Color(0xFF6B4E00)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'まだ王者はいない',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '最初のモンスターを召喚して\n初代王者に君臨せよ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMid,
            height: 1.6,
          ),
        ),
        const Spacer(),
        GradientButton(
          label: '初代王者になる',
          icon: Icons.auto_awesome,
          variant: CmButtonVariant.yellow,
          fontSize: 17,
          padding: const EdgeInsets.symmetric(vertical: 18),
          fullWidth: true,
          onTap: onChallenge,
        ),
        const SizedBox(height: 8),
        Text(
          canChallenge
              ? '初代王者の登録は日次の挑戦回数を消費しません'
              : '召喚権があれば通常通り挑戦できます',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _CrownHeader extends StatelessWidget {
  final String label;
  const _CrownHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events_outlined,
            size: 16, color: AppColors.yellowDeep),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.inkMid,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.emoji_events_outlined,
            size: 16, color: AppColors.yellowDeep),
      ],
    );
  }
}

enum _NoticeTone { warning, error }

class _Notice extends StatelessWidget {
  final String message;
  final _NoticeTone tone;
  const _Notice({required this.message, required this.tone});

  @override
  Widget build(BuildContext context) {
    final color = tone == _NoticeTone.warning
        ? AppColors.yellowDeep
        : AppColors.red;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.gothic,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 48, color: AppColors.inkSoft),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'もう一度読み込む',
              icon: Icons.refresh,
              variant: CmButtonVariant.ink,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
