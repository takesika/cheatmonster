import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/battle_result.dart';
import '../models/game_mode.dart';
import '../models/monster.dart';
import '../services/battle_limit_service.dart';
import '../services/cpu_opponent_service.dart';
import '../services/gemini_service.dart';
import '../services/pvp_record_service.dart';
import '../services/replicate_service.dart';
import '../services/room_service.dart';

class GameProvider extends ChangeNotifier {
  Monster? playerMonster;
  Monster? cpuMonster;
  BattleResult? battleResult;
  bool isGeneratingImage = false;
  bool isBattling = false;

  GameMode gameMode = GameMode.cpu;
  String? roomCode;
  int? playerNumber;
  bool isWaitingForOpponent = false;

  final _geminiService = GeminiService();
  final _imageService = ImageGenerationService();
  final _cpuService = CpuOpponentService();
  final _battleLimitService = BattleLimitService();
  final _pvpRecordService = PvpRecordService();
  final _roomService = RoomService();
  final _rng = Random();

  int remainingBattles = 5;
  int pvpTotalMatches = 0;
  int pvpWins = 0;

  bool isGeneratingCpuImage = false;

  Future<void> loadRemainingBattles() async {
    remainingBattles = await _battleLimitService.getRemainingBattles();
    notifyListeners();
  }

  Future<bool> canBattle() => _battleLimitService.canBattle();

  Future<void> loadPvpRecord() async {
    pvpTotalMatches = await _pvpRecordService.getTotalMatches();
    pvpWins = await _pvpRecordService.getWins();
    notifyListeners();
  }

  void setGameMode(GameMode mode) {
    gameMode = mode;
    notifyListeners();
  }

  void setRoomInfo(String code, int playerNum) {
    roomCode = code;
    playerNumber = playerNum;
  }

  Future<void> createPlayerMonster(String name, String specialAbility) async {
    final atk = _rng.nextInt(100) + 1;
    final def = _rng.nextInt(100) + 1;

    playerMonster = Monster(
      name: name,
      atk: atk,
      def: def,
      specialAbility: specialAbility,
    );

    if (gameMode == GameMode.online) {
      await createPlayerMonsterOnline(name, specialAbility);
      return;
    }

    isGeneratingImage = true;
    isGeneratingCpuImage = true;
    notifyListeners();

    // プレイヤー画像生成、CPU名前+能力+画像生成を全て並列
    await Future.wait([
      _generatePlayerImage(name, specialAbility),
      _generateCpuMonsterAndImage(),
    ]);
  }

  Future<void> createPlayerMonsterOnline(
      String name, String specialAbility) async {
    isGeneratingImage = true;
    notifyListeners();

    await _generatePlayerImage(name, specialAbility);
  }

  Future<void> setOpponentFromJson(Map<String, dynamic> json) async {
    cpuMonster = Monster.fromJson(json);
    isGeneratingCpuImage = true;
    notifyListeners();

    try {
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

  Future<void> submitMonster() async {
    if (roomCode == null || playerNumber == null || playerMonster == null) return;
    await _roomService.submitMonster(roomCode!, playerNumber!, playerMonster!);
  }

  Future<void> deleteRoom() async {
    if (roomCode != null) {
      await _roomService.deleteRoom(roomCode!);
    }
  }

  Future<void> startOnlineBattle() async {
    if (playerMonster == null || cpuMonster == null) return;

    isBattling = true;
    notifyListeners();

    try {
      if (playerNumber == 1) {
        battleResult = await _geminiService.judgeBattle(
          playerMonster!,
          cpuMonster!,
          isOnline: true,
        );
        // Player1がジャッジ結果をFirebaseに送信
        int winnerPlayerNum;
        if (battleResult!.outcome == BattleOutcome.win) {
          winnerPlayerNum = 1;
        } else if (battleResult!.outcome == BattleOutcome.lose) {
          winnerPlayerNum = 2;
        } else {
          winnerPlayerNum = 0;
        }
        await _roomService.submitResult(roomCode!, battleResult!, winnerPlayerNum);
      } else {
        // Player2: Firebaseからジャッジ結果を待つ
        isWaitingForOpponent = true;
        notifyListeners();
        await for (final result in _roomService.listenForResult(roomCode!)) {
          if (result != null) {
            final outcome = result['outcome'] as String;
            BattleOutcome battleOutcome;
            if (outcome == 'player1_win') {
              battleOutcome = BattleOutcome.lose;
            } else if (outcome == 'player2_win') {
              battleOutcome = BattleOutcome.win;
            } else {
              battleOutcome = BattleOutcome.draw;
            }
            battleResult = BattleResult(
              outcome: battleOutcome,
              narration: result['narration'] as String,
            );
            break;
          }
        }
      }
    } catch (_) {
      final playerTotal = playerMonster!.atk + playerMonster!.def;
      final opponentTotal = cpuMonster!.atk + cpuMonster!.def;
      BattleOutcome outcome;
      if (playerTotal > opponentTotal) {
        outcome = BattleOutcome.win;
      } else if (playerTotal < opponentTotal) {
        outcome = BattleOutcome.lose;
      } else {
        outcome = BattleOutcome.draw;
      }
      battleResult = BattleResult(
        outcome: outcome,
        narration: '通信エラーが発生しましたが、力比べで決着がつきました！',
      );
    } finally {
      if (battleResult != null) {
        await _pvpRecordService.recordMatch(battleResult!.outcome);
        await loadPvpRecord();
      }
      isBattling = false;
      isWaitingForOpponent = false;
      notifyListeners();
    }
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
    if (!await canBattle()) return;

    isBattling = true;
    notifyListeners();

    await _battleLimitService.recordBattle();
    remainingBattles = await _battleLimitService.getRemainingBattles();

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
    gameMode = GameMode.cpu;
    roomCode = null;
    playerNumber = null;
    isWaitingForOpponent = false;
    notifyListeners();
  }
}
