import 'dart:async';

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

  String? _mode; // null | 'create' | 'join'
  String? _roomCode;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<String>? _statusSubscription;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GameProvider>().loadPvpRecord();
    });
  }

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
              _TopBar(title: '友達と戦う', onBack: _isLoading ? null : _goBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        _ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 14),
                      ],
                      if (_mode == null) ...[
                        _CreateCard(onTap: _createRoom),
                        const SizedBox(height: 18),
                        const _OrDivider(),
                        const SizedBox(height: 18),
                        _JoinEntryCard(
                          onTap: () => setState(() {
                            _mode = 'join';
                            _errorMessage = null;
                          }),
                        ),
                        Consumer<GameProvider>(
                          builder: (context, game, _) {
                            if (game.pvpTotalMatches <= 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: _PvpRecord(
                                wins: game.pvpWins,
                                plays: game.pvpTotalMatches,
                              ),
                            );
                          },
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

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const _TopBar({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 18, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left,
                color: AppColors.ink, size: 26),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFonts.gothic,
          color: AppColors.red,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  const _CardTitleRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.groups,
              color: Color(0xFF1A1400), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitleRow(
            title: '部屋をつくる',
            subtitle: 'コードを友達に共有しよう',
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: '部屋をつくる',
            variant: CmButtonVariant.yellow,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(vertical: 14),
            fullWidth: true,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _JoinEntryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code,
                    color: AppColors.ink, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '部屋に入る',
                      style: TextStyle(
                        fontFamily: AppFonts.gothic,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'コードを入力して参加',
                      style: TextStyle(
                        fontFamily: AppFonts.gothic,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: '部屋に入る',
            variant: CmButtonVariant.ghost,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(vertical: 14),
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
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitleRow(
            title: '部屋をつくった',
            subtitle: 'コードを友達に共有しよう',
          ),
          const SizedBox(height: 16),
          if (loading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.yellow),
              ),
            ),
          ] else ...[
            _CodeDisplay(code: code ?? '', onCopy: onCopy),
            const SizedBox(height: 16),
            const _WaitingIndicator(text: '相手の参加を待っています...'),
          ],
        ],
      ),
    );
  }
}

class _CodeDisplay extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  const _CodeDisplay({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'コード',
              style: TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.copy, size: 16, color: AppColors.inkMid),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingIndicator extends StatelessWidget {
  final String text;
  const _WaitingIndicator({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.yellow,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontFamily: AppFonts.gothic,
            color: AppColors.inkMid,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'または',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              color: AppColors.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
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
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '部屋に入る',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          _CodeBoxes(controller: controller, autoFocus: true),
          const SizedBox(height: 16),
          loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  ),
                )
              : GradientButton(
                  label: '参加する',
                  variant: CmButtonVariant.yellow,
                  fontSize: 15,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
            children: List.generate(6, (i) {
              final ch = code[i].trim();
              final filled = i < widget.controller.text.length;
              final isCursor = i == widget.controller.text.length;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: filled || isCursor
                              ? AppColors.ink
                              : AppColors.line,
                          blurRadius: 0,
                          spreadRadius: filled || isCursor ? 1.6 : 1.2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ch,
                      style: TextStyle(
                        fontFamily: AppFonts.gothic,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: filled ? AppColors.ink : AppColors.inkSoft,
                      ),
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
      child: Column(
        children: [
          const Text(
            'オンライン戦績',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 10,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: '勝利', value: '$wins'),
              Container(width: 1, height: 22, color: AppColors.line),
              _Stat(label: '対戦', value: '$plays'),
              Container(width: 1, height: 22, color: AppColors.line),
              _Stat(label: '勝率', value: rate),
            ],
          ),
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

