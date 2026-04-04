import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/env.dart';
import '../models/battle_result.dart';
import '../models/monster.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Env.geminiApiKey,
    );
  }

  Future<BattleResult> judgeBattle(Monster player, Monster cpu) async {
    final prompt = '''
あなたはモンスターカードバトルの審判です。
両者のステータスと特殊能力を総合的に判断し、勝敗を決定してください。
数値だけでなく、特殊能力の内容も創造的に解釈してください。

【プレイヤーのモンスター】
名前: ${player.name}
攻撃力: ${player.atk}
守備力: ${player.def}
特殊能力: ${player.specialAbility}

【CPUのモンスター】
名前: ${cpu.name}
攻撃力: ${cpu.atk}
守備力: ${cpu.def}
特殊能力: ${cpu.specialAbility}

以下のJSON形式で回答してください。narrationは日本語で2〜3文のドラマチックな戦闘描写にしてください。
{"outcome": "win" または "lose" または "draw", "narration": "戦闘の描写"}
JSONのみを返してください。
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    // Strip markdown code fences if present
    final cleaned = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final outcomeStr = json['outcome'] as String;
      final narration = json['narration'] as String;

      BattleOutcome outcome;
      switch (outcomeStr) {
        case 'win':
          outcome = BattleOutcome.win;
          break;
        case 'lose':
          outcome = BattleOutcome.lose;
          break;
        default:
          outcome = BattleOutcome.draw;
      }

      return BattleResult(outcome: outcome, narration: narration);
    } catch (_) {
      // Fallback: simple stats comparison
      final playerTotal = player.atk + player.def;
      final cpuTotal = cpu.atk + cpu.def;
      BattleOutcome outcome;
      if (playerTotal > cpuTotal) {
        outcome = BattleOutcome.win;
      } else if (playerTotal < cpuTotal) {
        outcome = BattleOutcome.lose;
      } else {
        outcome = BattleOutcome.draw;
      }
      return BattleResult(
        outcome: outcome,
        narration: '激しい戦いの末、力の差が勝敗を分けた！',
      );
    }
  }
}
