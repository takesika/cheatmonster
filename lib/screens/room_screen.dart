import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../services/room_service.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _roomService = RoomService();
  final _codeController = TextEditingController();

  // null = mode selection, 'create' = creating, 'join' = joining
  String? _mode;
  String? _roomCode;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<String>? _statusSubscription;
  Timer? _timeoutTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _statusSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _mode = 'create';
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = await _roomService.createRoom();
      setState(() {
        _roomCode = code;
        _isLoading = false;
      });

      // 60秒タイムアウト
      _timeoutTimer = Timer(const Duration(seconds: 60), () {
        _statusSubscription?.cancel();
        _roomService.deleteRoom(code);
        if (mounted) {
          setState(() {
            _errorMessage = 'タイムアウトしました。もう一度お試しください。';
            _mode = null;
            _roomCode = null;
          });
        }
      });

      // 相手の参加を監視
      _statusSubscription = _roomService.listenForStatus(code).listen((status) {
        if (status == 'ready' && mounted) {
          _timeoutTimer?.cancel();
          _statusSubscription?.cancel();
          final game = context.read<GameProvider>();
          game.setGameMode(GameMode.online);
          game.setRoomInfo(code, 1);
          Navigator.pushReplacementNamed(context, '/summon');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ネットワークエラーが発生しました。もう一度お試しください。';
          _mode = null;
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _errorMessage = '6桁のコードを入力してください。');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _roomService.joinRoom(code);
      if (!mounted) return;

      if (success) {
        final game = context.read<GameProvider>();
        game.setGameMode(GameMode.online);
        game.setRoomInfo(code, 2);
        Navigator.pushReplacementNamed(context, '/summon');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '部屋が見つからないか、既に対戦が始まっています。';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ネットワークエラーが発生しました。もう一度お試しください。';
        });
      }
    }
  }

  void _goBack() {
    _statusSubscription?.cancel();
    _timeoutTimer?.cancel();
    if (_roomCode != null) {
      _roomService.deleteRoom(_roomCode!);
    }
    if (_mode != null) {
      setState(() {
        _mode = null;
        _roomCode = null;
        _errorMessage = null;
      });
    } else {
      Navigator.pop(context);
    }
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_mode == null) _buildModeSelection(),
                  if (_mode == 'create') _buildCreateMode(),
                  if (_mode == 'join') _buildJoinMode(),
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(_mode == null ? 'ホームへ戻る' : '戻る'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Column(
      children: [
        const Icon(
          Icons.people,
          size: 64,
          color: Color(0xFFFFB300),
        ),
        const SizedBox(height: 16),
        Text(
          'オンライン対戦',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF333333),
              ),
        ),
        const SizedBox(height: 32),
        _buildActionButton(
          label: '部屋を作る',
          onTap: _createRoom,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          label: '部屋に入る',
          onTap: () => setState(() {
            _mode = 'join';
            _errorMessage = null;
          }),
        ),
      ],
    );
  }

  Widget _buildCreateMode() {
    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          SizedBox(height: 16),
          Text(
            '部屋を作成中...',
            style: TextStyle(color: Color(0xFF666666)),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text(
          'ルームコード',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (_roomCode != null) {
              Clipboard.setData(ClipboardData(text: _roomCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('コードをコピーしました'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2196F3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _roomCode ?? '',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    letterSpacing: 8,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.copy, color: Color(0xFF2196F3), size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Color(0xFFFFB300)),
        const SizedBox(height: 16),
        const Text(
          '待機中... 相手の参加を待っています',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinMode() {
    return Column(
      children: [
        const Text(
          'ルームコードを入力',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 240,
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'XXXXXX',
              hintStyle: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 28,
                fontFamily: 'Courier',
                letterSpacing: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator(color: Color(0xFF2196F3))
            : _buildActionButton(
                label: '参加する',
                onTap: _joinRoom,
              ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
