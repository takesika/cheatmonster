import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
import '../widgets/fleur_divider.dart';
import '../widgets/game_background.dart';
import '../widgets/gradient_button.dart';

class SummonScreen extends StatefulWidget {
  const SummonScreen({super.key});

  @override
  State<SummonScreen> createState() => _SummonScreenState();
}

class _SummonScreenState extends State<SummonScreen> {
  final _nameController = TextEditingController();
  final _abilityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _abilityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final isOnline = game.gameMode == GameMode.online;
    final isTowerStage = !isOnline && game.cpuStage >= 2;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              _NavBar(
                title: '召喚',
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FleurDivider(small: true),
                        const SizedBox(height: 18),
                        const _EngravedLine('モンスター召喚'),
                        const SizedBox(height: 22),
                        _ParchmentField(
                          controller: _nameController,
                          label: 'モンスター名',
                          hint: '例: フレイムドラゴン',
                          required: true,
                          maxLength: 20,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
                        ),
                        const SizedBox(height: 14),
                        _ParchmentField(
                          controller: _abilityController,
                          label: '特殊能力',
                          hint: '例: 全てを焼き尽くす炎',
                          accent: true,
                          maxLength: 20,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '特殊能力を入力してください'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        const _BlindStats(),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            '攻撃・守備はランダム（1—100）',
                            style: TextStyle(
                              fontFamily: AppFonts.mincho,
                              color: AppColors.inkSoft,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (isTowerStage) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.seal.withOpacity(0.1),
                              border: Border.all(color: AppColors.seal),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'ステージ ${game.cpuStage} / ${GameConstants.maxCpuStages}',
                                  style: const TextStyle(
                                    fontFamily: AppFonts.mincho,
                                    color: AppColors.goldLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '⚠ 相手はあなたの能力を研究しています',
                                  style: TextStyle(
                                    fontFamily: AppFonts.mincho,
                                    color: AppColors.sealLight,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!isOnline && !isTowerStage) ...[
                          const SizedBox(height: 18),
                          const _HowToPlay(),
                        ],
                        const SizedBox(height: 32),
                        GradientButton(
                          label: '召喚する',
                          variant: CmButtonVariant.gold,
                          fontSize: 16,
                          letterSpacing: 6,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          fullWidth: true,
                          onTap: _onSummon,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSummon() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final ability = _abilityController.text.trim();
    context.read<GameProvider>().createPlayerMonster(name, ability);
    Navigator.pushNamed(context, '/summon-result');
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
  const _EngravedLine(this.text);
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

class _ParchmentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final bool accent;
  final int maxLength;
  final String? help;
  final String? Function(String?)? validator;

  const _ParchmentField({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.hint,
    this.required = false,
    this.accent = false,
    this.help,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = accent ? AppColors.seal : AppColors.gold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.mincho,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 6,
                ),
              ),
              if (required)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('*',
                      style: TextStyle(
                          color: AppColors.seal, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              Text(
                '${controller.text.length}/$maxLength',
                style: TextStyle(
                  fontFamily: AppFonts.cinzel,
                  fontSize: 9,
                  color: AppColors.inkSoft.withOpacity(0.8),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0E2C0), Color(0xFFD8C298)],
            ),
            border: Border.all(
              color: accent ? AppColors.seal : AppColors.goldDeep,
              width: accent ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: accent
                ? [
                    BoxShadow(
                      color: AppColors.seal.withOpacity(0.12),
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextFormField(
            controller: controller,
            maxLength: maxLength,
            validator: validator,
            style: TextStyle(
              fontFamily:
                  accent ? AppFonts.mincho : AppFonts.mincho,
              fontSize: accent ? 16 : 19,
              fontWeight: accent ? FontWeight.w600 : FontWeight.w700,
              color: AppColors.inkDark,
              letterSpacing: accent ? 0.5 : 1,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.inkDark.withOpacity(0.3),
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        if (help != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              help!,
              style: const TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.sealDeep,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _BlindStats extends StatelessWidget {
  const _BlindStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0DF4E8C8),
        border: Border.all(color: AppColors.goldDeep, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 70,
            child: Text(
              '戦力',
              style: TextStyle(
                fontFamily: AppFonts.mincho,
                color: AppColors.gold,
                fontSize: 11,
                letterSpacing: 4,
              ),
            ),
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BlindStat(label: 'ATK'),
                Text('×',
                    style: TextStyle(
                        fontFamily: AppFonts.cinzel,
                        color: AppColors.goldDeep,
                        fontSize: 14)),
                _BlindStat(label: 'DEF'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlindStat extends StatelessWidget {
  final String label;
  const _BlindStat({required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.mincho,
            fontSize: 11,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        const Text(
          '??',
          style: TextStyle(
            fontFamily: AppFonts.cinzel,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.goldDeep,
          ),
        ),
      ],
    );
  }
}

class _HowToPlay extends StatelessWidget {
  const _HowToPlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: const Border(
          left: BorderSide(color: AppColors.gold, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '遊び方',
            style: TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '① モンスター名と特殊能力を決めて召喚\n'
            '② 攻撃力・守備力（1—100）はランダム\n'
            '③ 相手モンスターとバトル\n'
            '④ AIがステータスと特殊能力を総合判定',
            style: TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.inkSoft,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '特殊能力の発想力が勝負を決める。',
            style: TextStyle(
              fontFamily: AppFonts.mincho,
              color: AppColors.goldLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
