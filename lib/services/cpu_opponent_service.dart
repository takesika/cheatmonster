import 'dart:convert';
import 'dart:math';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/env.dart';
import '../models/monster.dart';

class CpuOpponentService {
  late final GenerativeModel _model;
  static final _rng = Random();

  CpuOpponentService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Env.geminiApiKey,
    );
  }

  Future<Monster> generate({int stage = 1, List<String>? counterAbilities}) async {
    final String prompt;
    if (stage >= 2 && counterAbilities != null && counterAbilities.isNotEmpty) {
      prompt = '''
カードバトルゲームのモンスターを1体考えてください。
名前はオリジナルでカッコいいカタカナ。

これはステージ${stage}の対戦相手です。
相手はこれまで以下の特殊能力を使いました:
${counterAbilities.asMap().entries.map((e) => '- ステージ${e.key + 1}: 「${e.value}」').join('\n')}
これら全ての能力に対抗できる、さらに強力なモンスターを考えてください。
全ての能力を無効化したり上回ったりする特殊能力を20文字以内で考えてください。

以下のJSON形式で返してください。JSONのみを返してください。
{"name": "モンスター名", "specialAbility": "特殊能力"}
''';
    } else {
      prompt = '''
カードバトルゲームのモンスターを1体考えてください。
名前はオリジナルでカッコいいカタカナ。
特殊能力は20文字以内で、チートレベルのぶっ壊れスキルにしてください。
毎回違うユニークな能力にしてください。
以下のJSON形式で返してください。JSONのみを返してください。
{"name": "モンスター名", "specialAbility": "特殊能力"}
''';
    }

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      return Monster(
        name: json['name'] as String,
        atk: _rng.nextInt(100) + 1,
        def: _rng.nextInt(100) + 1,
        specialAbility: json['specialAbility'] as String,
      );
    } catch (_) {
      return Monster(
        name: 'ナゾモンスター',
        atk: _rng.nextInt(100) + 1,
        def: _rng.nextInt(100) + 1,
        specialAbility: '謎の力で攻撃する',
      );
    }
  }
}
