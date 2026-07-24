import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../services/battle_limit_service.dart';
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
              const total = BattleLimitService.maxBattlesPerDay;
              final canPlay = remaining > 0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top bar with challenge chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _ChallengeChip(
                                    remaining: remaining, total: total),
                              ],
                            ),
                            SizedBox(height: 20 * scale),

                            // Logo block
                            const _Crown(size: 26, color: AppColors.yellowDeep),
                            SizedBox(height: 6 * scale),
                            _Logo(scale: scale),
                            SizedBox(height: 6 * scale),
                            const _SubTitle(),
                            SizedBox(height: 8 * scale),
                            const _Tagline(),

                            const Spacer(),

                            // Mode buttons
                            _ModeButton(
                              icon: '⚔',
                              label: 'つくって戦う',
                              subtitle: 'モンスターを作って挑戦',
                              primary: true,
                              enabled: canPlay,
                              onTap: canPlay
                                  ? () {
                                      game.reset();
                                      Navigator.pushNamed(context, '/summon');
                                    }
                                  : null,
                            ),
                            SizedBox(height: 12 * scale),
                            _ModeButton(
                              icon: '👥',
                              label: '友達と戦う',
                              subtitle: 'オンラインで対戦',
                              primary: false,
                              enabled: canPlay,
                              onTap: canPlay
                                  ? () {
                                      game.reset();
                                      game.setGameMode(GameMode.online);
                                      Navigator.pushNamed(context, '/room');
                                    }
                                  : null,
                            ),

                            if (game.pvpTotalMatches > 0) ...[
                              SizedBox(height: 16 * scale),
                              _PvpRecord(
                                wins: game.pvpWins,
                                plays: game.pvpTotalMatches,
                              ),
                            ],

                            if (!canPlay) ...[
                              SizedBox(height: 12 * scale),
                              const Center(
                                child: Text(
                                  '明日また挑戦できます',
                                  style: TextStyle(
                                    fontFamily: AppFonts.gothic,
                                    color: AppColors.inkSoft,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 8 * scale),
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
}

class _ChallengeChip extends StatelessWidget {
  final int remaining;
  final int total;
  const _ChallengeChip({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Crown(size: 14, color: AppColors.yellowDeep),
          const SizedBox(width: 6),
          Text(
            '挑戦 $remaining/$total',
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Crown extends StatelessWidget {
  final double size;
  final Color color;
  const _Crown({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrownPainter(color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;
  _CrownPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.125, s * 0.333)
      ..lineTo(s * 0.271, s * 0.5)
      ..lineTo(s * 0.5, s * 0.208)
      ..lineTo(s * 0.729, s * 0.5)
      ..lineTo(s * 0.875, s * 0.333)
      ..lineTo(s * 0.813, s * 0.792)
      ..lineTo(s * 0.188, s * 0.792)
      ..close();
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Logo extends StatelessWidget {
  final double scale;
  const _Logo({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      'CHEAT\nMONSTERS',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.gothic,
        fontWeight: FontWeight.w900,
        fontSize: 34 * scale,
        height: 1.0,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle();
  @override
  Widget build(BuildContext context) {
    return const Text(
      'チートモンスターズ',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.gothic,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
        color: AppColors.inkMid,
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();
  @override
  Widget build(BuildContext context) {
    return const Text(
      'つくって、戦って、世界一を目指そう！',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.gothic,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.inkMid,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool primary;
  final bool enabled;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.primary,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.yellow : AppColors.card;
    final labelColor = primary ? const Color(0xFF1A1400) : AppColors.ink;
    final subColor = primary
        ? const Color(0xFF1A1400).withValues(alpha: 0.55)
        : AppColors.inkSoft;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border:
                  primary ? null : Border.all(color: AppColors.line, width: 1.5),
              boxShadow: primary
                  ? [
                      BoxShadow(
                        color: AppColors.yellow.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppFonts.gothic,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppFonts.gothic,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: labelColor, size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: '勝利', value: '$wins'),
          Container(width: 1, height: 22, color: AppColors.line),
          _Stat(label: '対戦', value: '$plays'),
          Container(width: 1, height: 22, color: AppColors.line),
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
              fontFamily: AppFonts.gothic,
              fontSize: 10,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              fontFeatures: [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}
