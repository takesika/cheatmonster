import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../services/room_service.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _roomService = RoomService();
  final _codeController = TextEditingController();

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

      _timeoutTimer = Timer(const Duration(seconds: GameConstants.timeoutSeconds), () {
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

      _statusSubscription =
          _roomService.listenForStatus(code).listen((status) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = AppScale.of(context);

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: min(32, screenWidth * 0.08)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.ruby.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.ruby),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.ruby,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_mode == null) _buildModeSelection(scale),
                  if (_mode == 'create') _buildCreateMode(scale),
                  if (_mode == 'join')
                    _buildJoinMode(scale, screenWidth),
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _goBack,
                    icon: const Icon(Icons.arrow_back),
                    label:
                        Text(_mode == null ? 'ホームへ戻る' : '戻る'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
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

  Widget _buildModeSelection(double scale) {
    return Column(
      children: [
        Icon(
          Icons.people,
          size: 64 * scale,
          color: AppColors.gold,
        ),
        const SizedBox(height: 16),
        Text(
          'オンライン対戦',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: '部屋を作る',
          onTap: _createRoom,
          padding: EdgeInsets.symmetric(
              horizontal: 48 * scale, vertical: 18),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: '部屋に入る',
          onTap: () => setState(() {
            _mode = 'join';
            _errorMessage = null;
          }),
          padding: EdgeInsets.symmetric(
              horizontal: 48 * scale, vertical: 18),
        ),
      ],
    );
  }

  Widget _buildCreateMode(double scale) {
    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(color: AppColors.gold),
          SizedBox(height: 16),
          Text(
            '部屋を作成中...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text(
          'ルームコード',
          style: TextStyle(
            color: AppColors.textSecondary,
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
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _roomCode ?? '',
                  style: TextStyle(
                    fontSize: 36 * scale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    letterSpacing: 8 * scale,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.copy,
                    color: AppColors.gold, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: AppColors.gold),
        const SizedBox(height: 16),
        const Text(
          '待機中... 相手の参加を待っています',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinMode(double scale, double screenWidth) {
    return Column(
      children: [
        const Text(
          'ルームコードを入力',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: screenWidth * 0.6,
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28 * scale,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              letterSpacing: 8 * scale,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'XXXXXX',
              hintStyle: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 28 * scale,
                fontFamily: 'Courier',
                letterSpacing: 8 * scale,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.gold, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator(
                color: AppColors.gold)
            : GradientButton(
                label: '参加する',
                onTap: _joinRoom,
                padding: EdgeInsets.symmetric(
                    horizontal: 48 * scale, vertical: 18),
              ),
      ],
    );
  }
}
