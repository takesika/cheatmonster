import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_mode.dart';
import '../providers/game_provider.dart';

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
    final isOnline =
        context.read<GameProvider>().gameMode == GameMode.online;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOnline ? 'あなたのモンスターを召喚' : 'モンスター召喚'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A3E),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F0EB), Color(0xFFE8E0F0)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFC9A84C).withOpacity(0.06),
                      const Color(0xFFC9A84C).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2B4C8C).withOpacity(0.05),
                      const Color(0xFF2B4C8C).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      const Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: Color(0xFFC9A84C),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'モンスターを生み出せ',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: const Color(0xFF1A1A3E),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
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
                                color: Color(0xFFC9A84C), width: 2),
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
                            borderSide: const BorderSide(
                                color: Color(0xFFC9A84C), width: 2),
                            borderRadius: BorderRadius.circular(12),
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
                      if (!isOnline)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                            border: const Border(
                              left: BorderSide(
                                  color: Color(0xFFC9A84C), width: 3),
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
                                      color: const Color(0xFF2B4C8C),
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
                                      color: const Color(0xFF5D5A72),
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
                                      color: const Color(0xFFC9A84C),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC9A84C), Color(0xFFB8943F)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFC9A84C).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _onSummon,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                '召喚！',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
