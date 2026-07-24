import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/game_mode.dart';
import '../providers/game_provider.dart';
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
              _TopBar(
                title: '新しいモンスターをつくる',
                onBack: () => Navigator.maybePop(context),
                stageChip: isTowerStage
                    ? 'STAGE ${game.cpuStage} / ${GameConstants.maxCpuStages}'
                    : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Field(
                          label: 'モンスター名',
                          counter:
                              '${_nameController.text.length} / 20',
                          child: _CardInput(
                            controller: _nameController,
                            hint: '例: フレイムドラゴン',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? '名前を入力してください'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _Field(
                          label: 'チート能力',
                          counter:
                              '${_abilityController.text.length} / 20',
                          child: _CardInput(
                            controller: _abilityController,
                            hint: '例: 全てを焼き尽くす炎',
                            multiline: true,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? '特殊能力を入力してください'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _TipRow(
                          icon: '💡',
                          title: 'どんな能力でもOK',
                          subtitle: 'AIが勝敗を判断します',
                        ),
                        const SizedBox(height: 10),
                        const _TipRow(
                          icon: '🎲',
                          title: '攻撃・守備はランダム',
                          subtitle: '1〜100の間で自動抽選',
                        ),
                        if (isTowerStage) ...[
                          const SizedBox(height: 16),
                          const _TowerWarning(),
                        ],
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'モンスターを召喚',
                          icon: Icons.auto_awesome,
                          variant: CmButtonVariant.yellow,
                          fontSize: 17,
                          letterSpacing: 1.2,
                          padding: const EdgeInsets.symmetric(vertical: 18),
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

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final String? stageChip;
  const _TopBar({required this.title, this.onBack, this.stageChip});

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
          if (stageChip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                stageChip!,
                style: const TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.yellowDeep,
                  letterSpacing: 1.5,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String counter;
  final Widget child;
  const _Field({
    required this.label,
    required this.counter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                counter,
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CardInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool multiline;
  final String? Function(String?)? validator;

  const _CardInput({
    required this.controller,
    required this.hint,
    this.multiline = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: multiline ? 12 : 4),
      child: TextFormField(
        controller: controller,
        maxLength: 20,
        maxLines: multiline ? 4 : 1,
        minLines: multiline ? 3 : 1,
        validator: validator,
        style: const TextStyle(
          fontFamily: AppFonts.gothic,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.inkSoft.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          counterText: '',
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(vertical: multiline ? 4 : 12),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _TipRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
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
      ),
    );
  }
}

class _TowerWarning extends StatelessWidget {
  const _TowerWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Text('⚠', style: TextStyle(fontSize: 20, color: AppColors.red)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '相手はあなたの前の能力を研究しています',
              style: TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
