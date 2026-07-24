import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/arcane_circle.dart';
import '../widgets/fleur_divider.dart';
import '../widgets/game_background.dart';

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
    context.read<GameProvider>().loadPvpRecord();
  }

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              final remaining = game.remainingBattles;
              const total = 5;
              final canPlay = remaining > 0;

              return Stack(
                children: [
                  // arcane circle centered behind everything
                  const Positioned.fill(
                    child: Center(
                      child: ArcaneCircle(size: 380, opacity: 0.13),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12 * scale),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Column(
                                  children: [
                                    const FleurDivider(),
                                    SizedBox(height: 18 * scale),
                                    _EngravedTitle(scale: scale),
                                    SizedBox(height: 10 * scale),
                                    const FleurDivider(small: true),
                                  ],
                                ),
                                SizedBox(height: 32 * scale),
                                _ModeCard(
                                  label: 'CPU対戦',
                                  enabled: canPlay,
                                  onTap: canPlay
                                      ? () {
                                          game.reset();
                                          Navigator.pushNamed(
                                              context, '/summon');
                                        }
                                      : null,
                                ),
                                SizedBox(height: 12 * scale),
                                _ModeCard(
                                  label: 'オンライン対戦',
                                  enabled: true,
                                  onTap: () {
                                    game.reset();
                                    game.setGameMode(GameMode.online);
                                    Navigator.pushNamed(context, '/room');
                                  },
                                ),
                                SizedBox(height: 18 * scale),
                                _DailySigils(remaining: remaining, total: total),
                                if (game.pvpTotalMatches > 0) ...[
                                  SizedBox(height: 10 * scale),
                                  _PvpRecord(
                                    wins: game.pvpWins,
                                    plays: game.pvpTotalMatches,
                                  ),
                                ],
                                if (!canPlay) ...[
                                  SizedBox(height: 10 * scale),
                                  const Center(
                                    child: Text(
                                      '明日また挑戦できます',
                                      style: TextStyle(
                                        fontFamily: AppFonts.mincho,
                                        color: AppColors.inkSoft,
                                        letterSpacing: 2,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
}

class _EngravedTitle extends StatelessWidget {
  final double scale;
  const _EngravedTitle({required this.scale});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldLight,
          AppColors.gold,
          AppColors.goldDeep,
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect),
      child: Text(
        'CHEAT\nMONSTERS',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.cinzel,
          fontWeight: FontWeight.w800,
          fontSize: 38 * scale,
          height: 1.0,
          letterSpacing: 5,
          color: Colors.white,
          shadows: const [
            Shadow(color: Color(0x66000000), offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}

class _DailySigils extends StatelessWidget {
  final int remaining;
  final int total;
  const _DailySigils({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: AppColors.goldDeep, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          const Text(
            '本日の召喚権',
            style: TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.gold,
              fontSize: 11,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final on = i < remaining;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _Sigil(on: on),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Sigil extends StatelessWidget {
  final bool on;
  const _Sigil({required this.on});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: on
            ? const RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [
                  AppColors.goldLight,
                  AppColors.gold,
                  AppColors.goldDeep,
                ],
                stops: [0.0, 0.6, 1.0],
              )
            : null,
        color: on ? null : Colors.white.withOpacity(0.04),
        border: on
            ? null
            : Border.all(color: AppColors.goldDeep, width: 1, style: BorderStyle.solid),
        boxShadow: on
            ? [
                BoxShadow(
                  color: AppColors.goldGlow.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: on ? 1.0 : 0.6,
        child: Text(
          on ? '✦' : '',
          style: TextStyle(
            fontFamily: AppFonts.cinzel,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: on ? const Color(0xFF3D2C14) : AppColors.goldDeep,
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const _ModeCard({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gold.withOpacity(0.18),
                  AppColors.gold.withOpacity(0.06),
                  AppColors.goldDeep.withOpacity(0.10),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.gold, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldDeep.withOpacity(0.5),
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: AppColors.goldGlow.withOpacity(0.12),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AppFonts.mincho,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.goldLight, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PvpRecord extends StatelessWidget {
  final int wins;
  final int plays;
  const _PvpRecord({required this.wins, required this.plays});

  @override
  Widget build(BuildContext context) {
    final rate = plays > 0 ? '${(wins / plays * 100).round()}%' : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border.all(
          color: AppColors.goldDeep,
          width: 0.5,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: '勝利', value: '$wins'),
          Container(
              width: 1,
              height: 22,
              color: AppColors.goldDeep.withOpacity(0.4)),
          _Stat(label: '対戦', value: '$plays'),
          Container(
              width: 1,
              height: 22,
              color: AppColors.goldDeep.withOpacity(0.4)),
          _Stat(label: '勝率', value: rate),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: AppFonts.mincho,
              fontSize: 10,
              color: AppColors.gold,
              letterSpacing: 4,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              fontFamily: AppFonts.cinzel,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.goldLight,
            )),
      ],
    );
  }
}

