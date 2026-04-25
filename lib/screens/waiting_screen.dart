import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/game_provider.dart';
import '../services/room_service.dart';
import '../widgets/game_background.dart';
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

    _timeoutTimer = Timer(const Duration(seconds: GameConstants.timeoutSeconds), () {
      _opponentSubscription?.cancel();
      _roomService.deleteRoom(roomCode);
      if (mounted) {
        setState(() => _timedOut = true);
      }
    });

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
      await game.setOpponentFromJson(
        result.monster.toJson(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = AppScale.of(context);

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: min(32, screenWidth * 0.08)),
              child: _timedOut
                  ? _buildTimeoutView(scale)
                  : _buildWaitingView(scale),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingView(double scale) {
    final game = context.watch<GameProvider>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (game.playerMonster != null)
          MonsterCard(
            monster: game.playerMonster!,
            isLoading: game.isGeneratingImage,
          ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(color: AppColors.gold),
        const SizedBox(height: 16),
        const Text(
          '相手の召喚を待っています...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeoutView(double scale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.timer_off,
          size: 64 * scale,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          '相手が離脱しました',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: _goHome,
          icon: const Icon(Icons.home),
          label: const Text('ホームへ戻る'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.sapphire,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
