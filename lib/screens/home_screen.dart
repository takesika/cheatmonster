import 'dart:math' as math;

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

  void _openThrone(BuildContext context) {
    context.read<GameProvider>().reset();
    Navigator.pushNamed(context, '/throne');
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight - 20),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TopBar(remaining: remaining, total: total),
                            SizedBox(height: 6 * scale),
                            const _Crown(size: 24, color: AppColors.yellowDeep),
                            SizedBox(height: 4 * scale),
                            _Logo(scale: scale),
                            SizedBox(height: 4 * scale),
                            const _SubTitle(),
                            SizedBox(height: 6 * scale),
                            const _Tagline(),
                            SizedBox(height: 18 * scale),
                            const _ChampionShowcase(),
                            SizedBox(height: 20 * scale),
                            _ThroneCta(onTap: () => _openThrone(context)),
                            SizedBox(height: 10 * scale),
                            _ModeButtonRow(
                              canPlay: canPlay,
                              onCpuTap: () {
                                game.reset();
                                Navigator.pushNamed(context, '/summon');
                              },
                              onOnlineTap: () {
                                game.reset();
                                game.setGameMode(GameMode.online);
                                Navigator.pushNamed(context, '/room');
                              },
                            ),
                            if (!canPlay) ...[
                              SizedBox(height: 10 * scale),
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
                            const SizedBox(height: 8),
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

class _TopBar extends StatelessWidget {
  final int remaining;
  final int total;
  const _TopBar({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _ChronicleButton(),
        _ChallengeChip(remaining: remaining, total: total),
      ],
    );
  }
}

class _ChronicleButton extends StatelessWidget {
  const _ChronicleButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => Navigator.pushNamed(context, '/chronicle'),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_outlined,
                  size: 16, color: AppColors.inkMid),
              SizedBox(width: 4),
              Text(
                'チート年表',
                style: TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkMid,
                ),
              ),
            ],
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
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.inkMid,
      ),
    );
  }
}

/// Big decorative area showing "current champion" placeholder.
/// Nothing to click — visual weight for the layout.
class _ChampionShowcase extends StatefulWidget {
  const _ChampionShowcase();

  @override
  State<_ChampionShowcase> createState() => _ChampionShowcaseState();
}

class _ChampionShowcaseState extends State<_ChampionShowcase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return CustomPaint(
                  size: const Size(220, 220),
                  painter: _HaloPainter(rotation: _ctrl.value * 2 * math.pi),
                );
              },
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(0, -0.2),
                  colors: [
                    AppColors.yellowSoft,
                    AppColors.yellow,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: _Crown(size: 72, color: Color(0xFF6B4E00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  final double rotation;
  _HaloPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final ring = Paint()
      ..color = AppColors.yellow.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r - 6, ring);
    canvas.drawCircle(center, r - 20, ring);

    // sparkles rotating around
    final sparkle = Paint()..color = AppColors.yellowDeep;
    for (int i = 0; i < 6; i++) {
      final a = rotation + i * (math.pi / 3);
      final p = Offset(center.dx + math.cos(a) * (r - 10),
          center.dy + math.sin(a) * (r - 10));
      canvas.drawCircle(p, 3, sparkle);
    }
    final sparkle2 = Paint()
      ..color = AppColors.yellowDeep.withValues(alpha: 0.5);
    for (int i = 0; i < 12; i++) {
      final a = -rotation * 0.6 + i * (math.pi / 6);
      final p = Offset(center.dx + math.cos(a) * (r - 24),
          center.dy + math.sin(a) * (r - 24));
      canvas.drawCircle(p, 1.5, sparkle2);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class _ThroneCta extends StatelessWidget {
  final VoidCallback onTap;
  const _ThroneCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Crown(size: 20, color: Color(0xFF1A1400)),
                  SizedBox(width: 8),
                  Text(
                    '王座に挑戦',
                    style: TextStyle(
                      fontFamily: AppFonts.gothic,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1400),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '世界王者を倒して王座を奪え',
                style: TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1400).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButtonRow extends StatelessWidget {
  final bool canPlay;
  final VoidCallback onCpuTap;
  final VoidCallback onOnlineTap;
  const _ModeButtonRow({
    required this.canPlay,
    required this.onCpuTap,
    required this.onOnlineTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniModeButton(
            icon: '⚔',
            label: 'CPUと戦う',
            subtitle: 'コンピュータと1対戦',
            enabled: canPlay,
            onTap: canPlay ? onCpuTap : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniModeButton(
            icon: '👥',
            label: '友達と戦う',
            subtitle: 'オンラインで対戦',
            enabled: canPlay,
            onTap: canPlay ? onOnlineTap : null,
          ),
        ),
      ],
    );
  }
}

class _MiniModeButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _MiniModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.gothic,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

