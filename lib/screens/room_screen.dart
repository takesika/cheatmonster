import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../services/room_service.dart';
import '../widgets/fleur_divider.dart';
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

  String? _mode; // null | 'create' | 'join'
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

      _timeoutTimer =
          Timer(const Duration(seconds: GameConstants.timeoutSeconds), () {
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
      setState(() => _errorMessage = '6桁のコードを入力してください');
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
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              _NavBar(
                title: '決闘の間',
                onBack: _isLoading ? null : _goBack,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FleurDivider(small: true),
                      const SizedBox(height: 14),
                      const _EngravedLine(text: 'オンライン対戦'),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'コードを共有して友達と対戦',
                          style: TextStyle(
                            fontFamily: AppFonts.mincho,
                            color: AppColors.inkSoft,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_errorMessage != null) ...[
                        _ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 14),
                      ],
                      if (_mode == null) ...[
                        _PrimaryActionCard(
                          label: '部屋を作る',
                          subtitle: 'コードを発行して相手を待ちます',
                          buttonLabel: '作成',
                          variant: CmButtonVariant.gold,
                          onTap: _createRoom,
                        ),
                        const SizedBox(height: 18),
                        _OrDivider(),
                        const SizedBox(height: 18),
                        _PrimaryActionCard(
                          label: '部屋に入る',
                          subtitle: 'コードを入力して参加します',
                          buttonLabel: '入る',
                          variant: CmButtonVariant.goldOutline,
                          onTap: () => setState(() {
                            _mode = 'join';
                            _errorMessage = null;
                          }),
                        ),
                      ] else if (_mode == 'create') ...[
                        _CreatingCard(
                          loading: _isLoading,
                          code: _roomCode,
                          onCopy: () {
                            if (_roomCode != null) {
                              Clipboard.setData(
                                  ClipboardData(text: _roomCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('コードをコピーしました'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ] else ...[
                        _JoinCard(
                          controller: _codeController,
                          onSubmit: _joinRoom,
                          loading: _isLoading,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const _NavBar({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left,
                  color: AppColors.goldLight, size: 26),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.mincho,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 8,
              color: AppColors.goldLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngravedLine extends StatelessWidget {
  final String text;
  const _EngravedLine({required this.text});
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDeep],
      ).createShader(rect),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFonts.mincho,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 6,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.seal.withOpacity(0.12),
        border: Border.all(color: AppColors.seal),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFonts.mincho,
          color: AppColors.sealLight,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String buttonLabel;
  final CmButtonVariant variant;
  final VoidCallback onTap;
  const _PrimaryActionCard({
    required this.label,
    required this.subtitle,
    required this.buttonLabel,
    required this.variant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.goldLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.inkSoft,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: buttonLabel,
            variant: variant,
            fontSize: 14,
            letterSpacing: 4,
            padding: const EdgeInsets.symmetric(vertical: 12),
            fullWidth: true,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _CreatingCard extends StatelessWidget {
  final bool loading;
  final String? code;
  final VoidCallback onCopy;
  const _CreatingCard({
    required this.loading,
    required this.code,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          if (loading) ...[
            const CircularProgressIndicator(color: AppColors.goldLight),
            const SizedBox(height: 12),
            const Text(
              'コードを生成中...',
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.inkSoft,
                letterSpacing: 2,
              ),
            ),
          ] else ...[
            const Text(
              'ルームコード',
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.gold,
                fontSize: 11,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onCopy,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(color: AppColors.goldDeep, width: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code ?? '',
                      style: const TextStyle(
                        fontFamily: AppFonts.cinzel,
                        color: AppColors.goldLight,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy,
                        color: AppColors.gold, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '相手の参加を待っています...',
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.inkSoft,
                letterSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Container(
                height: 0.5,
                color: AppColors.goldDeep.withOpacity(0.5))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '又は',
            style: TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.gold,
              fontSize: 12,
              letterSpacing: 6,
            ),
          ),
        ),
        Expanded(
            child: Container(
                height: 0.5,
                color: AppColors.goldDeep.withOpacity(0.5))),
      ],
    );
  }
}

class _JoinCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool loading;

  const _JoinCard({
    required this.controller,
    required this.onSubmit,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'ルームコードを入力',
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.gold,
                fontSize: 12,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _CodeBoxes(
            controller: controller,
            autoFocus: true,
          ),
          const SizedBox(height: 16),
          loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.goldLight),
                )
              : GradientButton(
                  label: '参加する',
                  variant: CmButtonVariant.gold,
                  fontSize: 14,
                  letterSpacing: 4,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  fullWidth: true,
                  onTap: onSubmit,
                ),
        ],
      ),
    );
  }
}

class _CodeBoxes extends StatefulWidget {
  final TextEditingController controller;
  final bool autoFocus;
  const _CodeBoxes({required this.controller, this.autoFocus = false});

  @override
  State<_CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<_CodeBoxes> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.toUpperCase().padRight(6);
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final ch = code[i].trim();
              final isCursor = i == widget.controller.text.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 38,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF0E2C0), Color(0xFFD8C298)],
                    ),
                    border: Border.all(
                      color: isCursor ? AppColors.seal : AppColors.goldDeep,
                      width: isCursor ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isCursor
                        ? [
                            BoxShadow(
                              color: AppColors.seal.withOpacity(0.4),
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ch.isEmpty ? '' : ch,
                    style: const TextStyle(
                      fontFamily: AppFonts.cinzel,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkDark,
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                decoration: const InputDecoration(counterText: ''),
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
