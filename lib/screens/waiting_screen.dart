import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/game_provider.dart';
import '../services/room_service.dart';
import '../widgets/arcane_circle.dart';
import '../widgets/fleur_divider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_card.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  final _roomService = RoomService();
  StreamSubscription<bool>? _opponentSubscription;
  Timer? _timeoutTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final game = context.read<GameProvider>();
    final roomCode = game.roomCode;
    final playerNum = game.playerNumber;
    if (roomCode == null || playerNum == null) return;

    _timeoutTimer = Timer(
      const Duration(seconds: GameConstants.timeoutSeconds),
      () {
        _opponentSubscription?.cancel();
        _roomService.deleteRoom(roomCode);
        if (mounted) setState(() => _timedOut = true);
      },
    );

    _opponentSubscription =
        _roomService.listenForOpponent(roomCode, playerNum).listen((ready) {
      if (ready && mounted) {
        _timeoutTimer?.cancel();
        _opponentSubscription?.cancel();
        _onOpponentReady();
      }
    });
  }

  Future<void> _onOpponentReady() async {
    final game = context.read<GameProvider>();
    final roomCode = game.roomCode!;
    final playerNum = game.playerNumber!;

    final result =
        await _roomService.getOpponentMonster(roomCode, playerNum);
    if (result != null && mounted) {
      await game.setOpponentMonster(
        result.monster,
        pvpWins: result.pvpWins,
        pvpTotalMatches: result.pvpTotalMatches,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/battle');
      }
    }
  }

  void _goHome() {
    final game = context.read<GameProvider>();
    if (game.roomCode != null) {
      _roomService.deleteRoom(game.roomCode!);
    }
    game.reset();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  void dispose() {
    _opponentSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _timedOut ? _buildTimeoutView() : _buildWaitingView(),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    final game = context.watch<GameProvider>();
    return Stack(
      children: [
        const Positioned.fill(
          child: Center(
            child: ArcaneCircle(size: 320, opacity: 0.18),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const FleurDivider(small: true),
                        const SizedBox(height: 14),
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.goldLight,
                              AppColors.gold,
                              AppColors.goldDeep,
                            ],
                          ).createShader(rect),
                          child: const Text(
                            '相手を待っています',
                            style: TextStyle(
                              fontFamily: AppFonts.mincho,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: game.playerMonster != null
                          ? MonsterCard(
                              monster: game.playerMonster!,
                              isLoading: game.isGeneratingImage,
                              scale: 0.85,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.goldLight,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '相手のモンスター召喚を待っています...',
                            style: TextStyle(
                              fontFamily: AppFonts.mincho,
                              color: AppColors.inkSoft,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeoutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time,
              size: 56, color: AppColors.inkSoft),
          const SizedBox(height: 16),
          const Text(
            '相手が見つかりませんでした',
            style: TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.goldLight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'ホームへ',
            variant: CmButtonVariant.gold,
            fontSize: 14,
            letterSpacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
            onTap: _goHome,
          ),
        ],
      ),
    );
  }
}
