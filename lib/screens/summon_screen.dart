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
      appBar: AppBar(
        title: Text(isOnline ? 'あなたのモンスターを召喚' : 'モンスター召喚'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      extendBodyBehindAppBar: true,
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 375 ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 12 : 32),
                  const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'モンスターを生み出せ',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 16 : 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'モンスター名',
                      hintText: '例: フレイムドラゴン',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.pets),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLength: 20,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '名前を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _abilityController,
                    decoration: InputDecoration(
                      labelText: '特殊能力',
                      hintText: '例: 全てを焼き尽くす炎',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.auto_awesome),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 2),
                      ),
                    ),
                    maxLength: 20,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '特殊能力を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isTowerStage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Text(
                            'ステージ ${game.cpuStage} / ${GameConstants.maxCpuStages}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '⚠ 相手はあなたの能力を研究しています...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.ruby,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (!isOnline && !isTowerStage)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        border: const Border(
                          left: BorderSide(
                              color: AppColors.gold, width: 3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '遊び方',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.sapphire,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\u2460 モンスター名と特殊能力を決めて召喚!\n'
                            '\u2461 攻撃力・守備力はランダムに決定\n'
                            '\u2462 相手モンスターとバトル!\n'
                            '\u2463 AIがステータスと特殊能力を総合判断して勝ち負けを決定',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '特殊能力の内容が勝ち負けを左右する! チートスキルを考えよう',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  GradientButton(
                    label: '召喚！',
                    onTap: _onSummon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ],
              ),
            ),
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
