import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/battle_result.dart';
import '../models/champion.dart';
import '../models/game_mode.dart';
import '../models/history_entry.dart';
import '../models/monster.dart';
import '../services/analytics_service.dart';
import '../services/battle_limit_service.dart';
import '../services/champion_service.dart';
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
  final _championService = ChampionService();
  final _rng = Random();

  int remainingBattles = 5;
  int pvpTotalMatches = 0;
  int pvpWins = 0;

  bool isGeneratingCpuImage = false;

  int opponentPvpWins = 0;
  int opponentPvpTotalMatches = 0;

  int onlineBattleCount = 0;

  // Throne mode state.
  Champion? currentChampion;
  bool isLoadingChampion = false;
  bool throneCrowned = false;
  bool throneOutdated = false;
  String? throneErrorMessage;

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
    AnalyticsService.monsterSummoned(mode: gameMode.name);

    if (gameMode == GameMode.online) {
      await createPlayerMonsterOnline(name, specialAbility);
      return;
    }

    if (gameMode == GameMode.throne) {
      // The champion is the opponent — no CPU generation needed.
      cpuMonster = currentChampion?.monster;
      isGeneratingImage = true;
      notifyListeners();
      await _generatePlayerImage(name, specialAbility);
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
    AnalyticsService.battleFinished(
      mode: 'online',
      outcome: battleResult?.outcome.name ?? 'unknown',
    );
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

  BattleResult _invertOutcome(BattleResult result) {
    BattleOutcome inverted;
    switch (result.outcome) {
      case BattleOutcome.win:
        inverted = BattleOutcome.lose;
        break;
      case BattleOutcome.lose:
        inverted = BattleOutcome.win;
        break;
      case BattleOutcome.draw:
        inverted = BattleOutcome.draw;
        break;
    }
    return BattleResult(outcome: inverted, narration: result.narration);
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
    AnalyticsService.battleFinished(
      mode: 'cpu',
      outcome: battleResult?.outcome.name ?? 'unknown',
    );
  }

  // ── Throne mode ──

  Future<void> loadChampion() async {
    final previous = currentChampion;
    isLoadingChampion = true;
    throneErrorMessage = null;
    notifyListeners();

    Champion? fetched;
    try {
      fetched = await _championService.fetchChampion();
    } catch (_) {
      throneErrorMessage = '王者情報の取得に失敗しました';
      isLoadingChampion = false;
      notifyListeners();
      return;
    }

    if (fetched == null) {
      currentChampion = null;
      isLoadingChampion = false;
      notifyListeners();
      return;
    }

    // Images are not stored in RTDB. Prefer the previously-held bytes when
    // the fetched champion is the same monster (avoids a flicker to the
    // placeholder icon, then a different regenerated image).
    final sameAsPrevious = previous != null &&
        previous.monster.imageBytes != null &&
        previous.monster.name == fetched.monster.name &&
        previous.monster.specialAbility == fetched.monster.specialAbility;
    if (sameAsPrevious) {
      currentChampion = Champion(
        monster:
            fetched.monster.copyWith(imageBytes: previous.monster.imageBytes),
        updatedAt: fetched.updatedAt,
        defenseCount: fetched.defenseCount,
      );
      isLoadingChampion = false;
      notifyListeners();
      return;
    }

    // The fetched champion already carries its image either as bytes
    // (legacy base64-in-RTDB) or as a Storage URL (new). Commit as-is.
    // Only fall back to a local generation if neither is present — legacy
    // champions written before we started persisting the image.
    currentChampion = fetched;
    isLoadingChampion = false;
    notifyListeners();

    if (fetched.monster.imageBytes != null) return;
    if (fetched.monster.imageUrl != null &&
        fetched.monster.imageUrl!.isNotEmpty) return;

    try {
      final bytes = await _imageService.generateMonsterImage(
        fetched.monster.name,
        fetched.monster.specialAbility,
      );
      if (bytes != null && currentChampion == fetched) {
        currentChampion = Champion(
          monster: fetched.monster.copyWith(imageBytes: bytes),
          updatedAt: fetched.updatedAt,
        );
        notifyListeners();
      }
    } catch (_) {
      // Ignore — placeholder icon will be shown.
    }
  }

  /// Crown the challenger as the first champion (no battle needed).
  /// Returns true on success.
  Future<bool> crownAsFirstChampion() async {
    if (playerMonster == null) return false;
    final crownOutcome = await _championService.crown(
      challenger: playerMonster!,
      expectedPreviousUpdatedAt: 0,
    );
    final result = crownOutcome.result;
    if (result == CrownResult.crowned) {
      throneCrowned = true;
      currentChampion = Champion(
        monster: playerMonster!,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _championService.recordCrown(HistoryEntry(
        winner: playerMonster!,
        defeatedName: '',
        defeatedAbility: '',
        narration: '初代王者が誕生した。',
        crownedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      notifyListeners();
      return true;
    } else if (result == CrownResult.outdated) {
      throneOutdated = true;
      throneErrorMessage = '初代王者は既に決まりました';
      await loadChampion();
      notifyListeners();
      return false;
    } else {
      throneErrorMessage = '王者データの保存に失敗しました';
      notifyListeners();
      return false;
    }
  }

  Future<void> startThroneBattle() async {
    if (playerMonster == null) return;
    if (currentChampion == null) return;
    if (!await canBattle()) {
      throneErrorMessage = '本日の召喚権を使い切りました';
      notifyListeners();
      return;
    }

    // Fetch fresh champion to reject stale duplicate-ability challenges early.
    Champion? fresh;
    try {
      fresh = await _championService.fetchChampion();
    } catch (_) {
      throneErrorMessage = '王者情報の取得に失敗しました';
      notifyListeners();
      return;
    }
    if (fresh == null) {
      throneErrorMessage = '王者情報が見つかりません';
      notifyListeners();
      return;
    }
    if (fresh.monster.specialAbility == playerMonster!.specialAbility) {
      throneErrorMessage = '同じチート能力では挑戦できません';
      notifyListeners();
      return;
    }
    // Use the fresh champion for judging so the fight matches what's on the
    // throne right now (avoids race with the caller's initial snapshot).
    currentChampion = fresh;
    cpuMonster = fresh.monster;

    isBattling = true;
    notifyListeners();

    await _battleLimitService.recordBattle();
    remainingBattles = await _battleLimitService.getRemainingBattles();

    // Randomize which monster is passed as first so any positional bias in
    // the LLM averages out — combined with neutral role labels, the throne
    // battle is judged purely on stats + special ability.
    final swap = _rng.nextBool();
    try {
      final raw = await _geminiService.judgeBattle(
        swap ? fresh.monster : playerMonster!,
        swap ? playerMonster! : fresh.monster,
        neutralRoles: true,
      );
      battleResult = swap ? _invertOutcome(raw) : raw;
    } catch (_) {
      battleResult = _createFallbackResult();
    }

    // On win, try to crown. Draws and losses leave the throne unchanged
    // but bump the champion's defense counter as a stat.
    if (battleResult!.outcome == BattleOutcome.win) {
      final crownOutcome = await _championService.crown(
        challenger: playerMonster!,
        expectedPreviousUpdatedAt: fresh.updatedAt,
      );
      final result = crownOutcome.result;
      if (result == CrownResult.crowned) {
        throneCrowned = true;
        AnalyticsService.crownWon();
        // Reflect the new champion locally so any UI that reads
        // currentChampion after the battle sees the winner immediately.
        currentChampion = Champion(
          monster: playerMonster!,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          defenseCount: 0,
        );
        // Prefer the defenseCount read at crown time — it captures
        // defenses recorded between our battle-start fetch and now.
        await _championService.recordCrown(HistoryEntry(
          winner: playerMonster!,
          defeatedName: fresh.monster.name,
          defeatedAbility: fresh.monster.specialAbility,
          defeatedDefenseCount: crownOutcome.previousDefenseCount,
          narration: battleResult!.narration,
          crownedAt: DateTime.now().millisecondsSinceEpoch,
        ));
      } else if (result == CrownResult.outdated) {
        throneOutdated = true;
        throneErrorMessage = '判定中に王者が交代しました';
        await _battleLimitService.refundBattle();
        remainingBattles = await _battleLimitService.getRemainingBattles();
        await loadChampion();
      } else {
        throneErrorMessage = '王者データの更新に失敗しました';
        await _battleLimitService.refundBattle();
        remainingBattles = await _battleLimitService.getRemainingBattles();
      }
    } else {
      // Champion successfully defended their throne.
      await _championService.recordDefense(expectedUpdatedAt: fresh.updatedAt);
      currentChampion = Champion(
        monster: fresh.monster,
        updatedAt: fresh.updatedAt,
        defenseCount: fresh.defenseCount + 1,
      );
    }

    isBattling = false;
    notifyListeners();
    AnalyticsService.battleFinished(
      mode: 'throne',
      outcome: battleResult?.outcome.name ?? 'unknown',
    );
  }

  void resetThroneFlags() {
    throneCrowned = false;
    throneOutdated = false;
    throneErrorMessage = null;
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
    throneCrowned = false;
    throneOutdated = false;
    throneErrorMessage = null;
    notifyListeners();
  }
}
