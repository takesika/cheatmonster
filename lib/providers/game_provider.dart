import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/battle_result.dart';
import '../models/monster.dart';
import '../services/cpu_opponent_service.dart';
import '../services/gemini_service.dart';
import '../services/replicate_service.dart';

class GameProvider extends ChangeNotifier {
  Monster? playerMonster;
  Monster? cpuMonster;
  BattleResult? battleResult;
  bool isGeneratingImage = false;
  bool isBattling = false;

  final _geminiService = GeminiService();
  final _imageService = ImageGenerationService();
  final _cpuService = CpuOpponentService();
  final _rng = Random();

  bool isGeneratingCpuImage = false;

  Future<void> createPlayerMonster(String name, String specialAbility) async {
    final atk = _rng.nextInt(100) + 1;
    final def = _rng.nextInt(100) + 1;

    playerMonster = Monster(
      name: name,
      atk: atk,
      def: def,
      specialAbility: specialAbility,
    );

    isGeneratingImage = true;
    isGeneratingCpuImage = true;
    notifyListeners();

    // プレイヤー画像生成、CPU名前+能力+画像生成を全て並列
    await Future.wait([
      _generatePlayerImage(name, specialAbility),
      _generateCpuMonsterAndImage(),
    ]);
  }

  Future<void> _generatePlayerImage(String name, String specialAbility) async {
    try {
      final imageBytes =
          await _imageService.generateMonsterImage(name, specialAbility);
      if (imageBytes != null) {
        playerMonster = playerMonster!.copyWith(imageBytes: imageBytes);
      }
    } catch (_) {
      // Image generation failed, continue without image
    } finally {
      isGeneratingImage = false;
      notifyListeners();
    }
  }

  Future<void> _generateCpuMonsterAndImage() async {
    try {
      // まずGeminiで名前と能力を生成
      cpuMonster = await _cpuService.generate();
      notifyListeners();

      // 次に画像生成
      final imageBytes = await _imageService.generateMonsterImage(
          cpuMonster!.name, cpuMonster!.specialAbility);
      if (imageBytes != null) {
        cpuMonster = cpuMonster!.copyWith(imageBytes: imageBytes);
      }
    } catch (_) {
      // Continue without image
    } finally {
      isGeneratingCpuImage = false;
      notifyListeners();
    }
  }

  Future<void> startBattle() async {
    if (playerMonster == null || cpuMonster == null) return;

    isBattling = true;
    notifyListeners();

    try {
      battleResult =
          await _geminiService.judgeBattle(playerMonster!, cpuMonster!);
    } catch (_) {
      // Fallback to stats comparison
      final playerTotal = playerMonster!.atk + playerMonster!.def;
      final cpuTotal = cpuMonster!.atk + cpuMonster!.def;
      BattleOutcome outcome;
      if (playerTotal > cpuTotal) {
        outcome = BattleOutcome.win;
      } else if (playerTotal < cpuTotal) {
        outcome = BattleOutcome.lose;
      } else {
        outcome = BattleOutcome.draw;
      }
      battleResult = BattleResult(
        outcome: outcome,
        narration: '通信エラーが発生しましたが、力比べで決着がつきました！',
      );
    } finally {
      isBattling = false;
      notifyListeners();
    }
  }

  void reset() {
    playerMonster = null;
    cpuMonster = null;
    battleResult = null;
    isGeneratingImage = false;
    isBattling = false;
    notifyListeners();
  }
}
