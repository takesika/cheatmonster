import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../services/room_service.dart';
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

    // 60秒タイムアウト
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      _opponentSubscription?.cancel();
      _roomService.deleteRoom(roomCode);
      if (mounted) {
        setState(() => _timedOut = true);
      }
    });

    // 相手の ready を監視
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

    final opponent =
        await _roomService.getOpponentMonster(roomCode, playerNum);
    if (opponent != null && mounted) {
      await game.setOpponentFromJson(opponent.toJson());
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _timedOut ? _buildTimeoutView() : _buildWaitingView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
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
        const CircularProgressIndicator(color: Color(0xFFFFB300)),
        const SizedBox(height: 16),
        const Text(
          '相手の召喚を待っています...',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeoutView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.timer_off,
          size: 64,
          color: Color(0xFF999999),
        ),
        const SizedBox(height: 16),
        const Text(
          '相手が離脱しました',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: _goHome,
          icon: const Icon(Icons.home),
          label: const Text('ホームへ戻る'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2196F3),
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
