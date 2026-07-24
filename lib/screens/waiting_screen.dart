import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/game_provider.dart';
import '../services/room_service.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_art.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _timedOut ? _buildTimeoutView() : _buildWaitingView(),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    final game = context.watch<GameProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  '相手を待っています',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'コード ${game.roomCode ?? ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMid,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                if (game.playerMonster != null) ...[
                  AspectRatio(
                    aspectRatio: 1,
                    child: MonsterArt(
                      imageBytes: game.playerMonster!.imageBytes,
                      loading: game.isGeneratingImage,
                      radius: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.playerMonster!.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.gothic,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkMid,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AbilityLine(
                    text: game.playerMonster!.specialAbility,
                    size: 20,
                  ),
                ],
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.yellow,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '相手の召喚を待っています...',
                        style: TextStyle(
                          fontFamily: AppFonts.gothic,
                          color: AppColors.inkMid,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeoutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time_outlined,
              size: 56, color: AppColors.inkSoft),
          const SizedBox(height: 16),
          const Text(
            '相手が見つかりませんでした',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'ホームへ戻る',
            icon: Icons.home_outlined,
            variant: CmButtonVariant.ink,
            fontSize: 15,
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            onTap: _goHome,
          ),
        ],
      ),
    );
  }
}
