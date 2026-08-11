import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../services/report_service.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_art.dart';
import '../widgets/report_sheet.dart';

class ThroneScreen extends StatefulWidget {
  const ThroneScreen({super.key});

  @override
  State<ThroneScreen> createState() => _ThroneScreenState();
}

class _ThroneScreenState extends State<ThroneScreen> {
  final _reports = ReportService();

  @override
  void initState() {
    super.initState();
    _reports.load().then((_) {
      if (mounted) setState(() {});
    });
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

  Future<void> _reportCurrentChampion(GameProvider game) async {
    final champion = game.currentChampion;
    if (champion == null) return;
    final reason = await showReportSheet(context);
    if (reason == null) return;
    await _reports.reportChampion(
      updatedAt: champion.updatedAt,
      name: champion.monster.name,
      ability: champion.monster.specialAbility,
      reason: reason,
    );
    if (!mounted) return;
    setState(() {}); // rebuild to apply mask
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('通報を受け付けました。この王者はこの端末では非表示になります。'),
        duration: Duration(seconds: 3),
      ),
    );
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
                      blocked: _reports.isChampionBlocked(
                          game.currentChampion!.updatedAt),
                      onChallenge: () => _startChallenge(context, game),
                      onReport: () => _reportCurrentChampion(game),
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
  final bool blocked;
  final VoidCallback onChallenge;
  final VoidCallback onReport;
  const _ChampionView({
    required this.game,
    required this.blocked,
    required this.onChallenge,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final champion = game.currentChampion!;
    final canChallenge = game.remainingBattles > 0;
    final displayedName = blocked ? '(通報済のため非表示)' : champion.monster.name;

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
                child: blocked
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.inkSoft.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.visibility_off_outlined,
                              size: 56, color: AppColors.inkMid),
                        ),
                      )
                    : MonsterArt(
                        imageBytes: champion.monster.imageBytes,
                        imageUrl: champion.monster.imageUrl,
                        radius: 20,
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: AppColors.ink.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: blocked ? null : onReport,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        blocked ? Icons.flag : Icons.flag_outlined,
                        size: 18,
                        color: blocked
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                      ),
                    ),
                  ),
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
                        displayedName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppFonts.gothic,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _HiddenAbilityPill(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatCards(atk: champion.monster.atk, def: champion.monster.def),
        const SizedBox(height: 10),
        _DefenseBadge(count: champion.defenseCount),
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

/// The champion's special ability stays hidden until they are dethroned.
/// Rendered as a gold-outlined pill with a lock indicator and "? ? ?" so
/// the ability slot is unmistakably concealed on purpose.
class _HiddenAbilityPill extends StatelessWidget {
  const _HiddenAbilityPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.yellow, width: 1.2),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline,
              size: 14, color: AppColors.yellow),
          const SizedBox(width: 6),
          const Text(
            '特殊能力',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.yellow,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 12,
            color: AppColors.yellow.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            '? ? ?',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
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

class _DefenseBadge extends StatelessWidget {
  final int count;
  const _DefenseBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // outer glow
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withValues(alpha: 0.55),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // dark outer ring
            Container(
              width: 118,
              height: 118,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3A2A00),
              ),
            ),
            // gold medal
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.4),
                  colors: [
                    Color(0xFFFFF3B0),
                    AppColors.yellow,
                    AppColors.yellowDeep,
                    Color(0xFF8C6B00),
                  ],
                  stops: [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
            // laurel / inner border ring
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6B4E00).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            // content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DEFENSE',
                  style: TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6B4E00),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3A2A00),
                    height: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  '防衛',
                  style: TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B4E00),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            // top crown decoration
            Positioned(
              top: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3A2A00),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.emoji_events,
                  size: 14,
                  color: AppColors.yellow,
                ),
              ),
            ),
          ],
        ),
      ),
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
