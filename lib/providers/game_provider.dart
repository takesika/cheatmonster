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

  int cpuStage = 0;
  List<String> playerAbilityHistory = [];

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

  int opponentPvpWins = 0;
  int opponentPvpTotalMatches = 0;

  int onlineBattleCount = 0;

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

    if (cpuStage == 0) {
      cpuStage = 1;
    }

    isGeneratingImage = true;
    isGeneratingCpuImage = true;
    notifyListeners();

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

  Future<void> setOpponentMonster(
    Monster monster, {
    int pvpWins = 0,
    int pvpTotalMatches = 0,
  }) async {
    cpuMonster = monster;
    opponentPvpWins = pvpWins;
    opponentPvpTotalMatches = pvpTotalMatches;

    if (cpuMonster!.imageBytes != null) {
      isGeneratingCpuImage = false;
      notifyListeners();
      return;
    }

    // fallback: opponent didn't upload an image — generate locally
    isGeneratingCpuImage = true;
    notifyListeners();

    try {
      final imageBytes = await _imageService.generateMonsterImage(
          cpuMonster!.name, cpuMonster!.specialAbility);
      if (imageBytes != null) {
        cpuMonster = cpuMonster!.copyWith(imageBytes: imageBytes);
      }
    } catch (_) {
    } finally {
      isGeneratingCpuImage = false;
      notifyListeners();
    }
  }

  Future<void> submitMonster() async {
    if (roomCode == null || playerNumber == null || playerMonster == null) return;
    await _roomService.submitMonster(
      roomCode!,
      playerNumber!,
      playerMonster!,
      pvpWins: pvpWins,
      pvpTotalMatches: pvpTotalMatches,
      imageBytes: playerMonster!.imageBytes,
    );
  }

  Future<void> deleteRoom() async {
    if (roomCode != null) {
      await _roomService.deleteRoom(roomCode!);
    }
  }

  Future<void> startOnlineBattle() async {
    if (playerMonster == null || cpuMonster == null) return;
    if (!await canBattle()) return;

    await _battleLimitService.recordBattle();
    remainingBattles = await _battleLimitService.getRemainingBattles();

    onlineBattleCount++;
    isBattling = true;
    notifyListeners();

    try {
      if (playerNumber == 1) {
        battleResult = await _geminiService.judgeBattle(
          playerMonster!,
          cpuMonster!,
          isOnline: true,
        );
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
      battleResult = _createFallbackResult();
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
    } finally {
      isGeneratingImage = false;
      notifyListeners();
    }
  }

  Future<void> _generateCpuMonsterAndImage() async {
    try {
      cpuMonster = await _cpuService.generate(
        stage: cpuStage,
        counterAbilities: playerAbilityHistory,
      );
      notifyListeners();

      final imageBytes = await _imageService.generateMonsterImage(
          cpuMonster!.name, cpuMonster!.specialAbility);
      if (imageBytes != null) {
        cpuMonster = cpuMonster!.copyWith(imageBytes: imageBytes);
      }
    } catch (_) {
    } finally {
      isGeneratingCpuImage = false;
      notifyListeners();
    }
  }

  void _resetBattleState() {
    playerMonster = null;
    cpuMonster = null;
    battleResult = null;
    isGeneratingImage = false;
    isGeneratingCpuImage = false;
    isBattling = false;
  }

  BattleResult _createFallbackResult() {
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
    return BattleResult(outcome: outcome, narration: '通信エラーが発生しましたが、力比べで決着がつきました！');
  }

  Future<void> setContinue() async {
    if (roomCode != null && playerNumber != null) {
      await _roomService.setContinue(roomCode!, playerNumber!);
    }
  }

  Future<void> setQuit() async {
    if (roomCode != null && playerNumber != null) {
      await _roomService.setQuit(roomCode!, playerNumber!);
    }
  }

  Stream<String> listenForContinueStatus() {
    return _roomService.listenForContinueStatus(roomCode!, playerNumber!);
  }

  Future<void> resetRoomForNextBattle() async {
    if (roomCode != null) {
      await _roomService.resetForNextBattle(roomCode!);
    }
  }

  Future<void> startBattle() async {
    if (playerMonster == null || cpuMonster == null) return;
    if (!await canBattle()) return;

    isBattling = true;
    notifyListeners();

    if (cpuStage <= 1) {
      await _battleLimitService.recordBattle();
      remainingBattles = await _battleLimitService.getRemainingBattles();
    }

    try {
      battleResult =
          await _geminiService.judgeBattle(playerMonster!, cpuMonster!);
    } catch (_) {
      battleResult = _createFallbackResult();
    } finally {
      isBattling = false;
      notifyListeners();
    }
  }

  void resetForNextCpuStage() {
    playerAbilityHistory.add(playerMonster!.specialAbility);
    cpuStage++;
    _resetBattleState();
    notifyListeners();
  }

  void resetForNextBattle() {
    _resetBattleState();
    isWaitingForOpponent = false;
    opponentPvpWins = 0;
    opponentPvpTotalMatches = 0;
    notifyListeners();
  }

  void reset() {
    _resetBattleState();
    gameMode = GameMode.cpu;
    cpuStage = 0;
    playerAbilityHistory = [];
    roomCode = null;
    playerNumber = null;
    isWaitingForOpponent = false;
    onlineBattleCount = 0;
    opponentPvpWins = 0;
    opponentPvpTotalMatches = 0;
    notifyListeners();
  }
}
