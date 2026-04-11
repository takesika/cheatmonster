import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import '../models/battle_result.dart';
import '../models/monster.dart';

class RoomService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  static const _codeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _codeLength = 6;

  /// 6桁の英数字ルームコードをランダム生成し、RTDBに部屋を作成
  Future<String> createRoom() async {
    final random = Random();
    String code;

    while (true) {
      code = List.generate(
        _codeLength,
        (_) => _codeChars[random.nextInt(_codeChars.length)],
      ).join();

      final snapshot = await _db.child('rooms/$code').get();
      if (!snapshot.exists) break;
    }

    await _db.child('rooms/$code').set({
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
    });

    return code;
  }

  /// 部屋に参加（status が "waiting" の場合のみ）
  Future<bool> joinRoom(String code) async {
    final snapshot = await _db.child('rooms/$code').get();
    if (!snapshot.exists) return false;

    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null || data['status'] != 'waiting') return false;

    await _db.child('rooms/$code').update({
      'player2': true,
      'status': 'ready',
    });

    return true;
  }

  /// モンスターデータを送信し、ready フラグを立てる
  Future<void> submitMonster(
    String roomCode,
    int playerNum,
    Monster monster,
  ) async {
    await _db.child('rooms/$roomCode/player$playerNum').set({
      ...monster.toJson(),
      'ready': true,
    });
  }

  /// 相手プレイヤーの ready フラグを監視
  Stream<bool> listenForOpponent(String roomCode, int playerNum) {
    final opponentNum = playerNum == 1 ? 2 : 1;
    return _db
        .child('rooms/$roomCode/player$opponentNum/ready')
        .onValue
        .map((event) => event.snapshot.value == true);
  }

  /// ジャッジ結果の書き込みを監視
  Stream<Map<String, dynamic>?> listenForResult(String roomCode) {
    return _db.child('rooms/$roomCode/result').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return Map<String, dynamic>.from(value as Map);
    });
  }

  /// ジャッジ結果を書き込み、status を "done" に更新
  Future<void> submitResult(
    String roomCode,
    BattleResult result,
    int winnerPlayerNum,
  ) async {
    String outcome;
    if (result.outcome == BattleOutcome.draw) {
      outcome = 'draw';
    } else if (winnerPlayerNum == 1) {
      outcome = 'player1_win';
    } else {
      outcome = 'player2_win';
    }

    await _db.child('rooms/$roomCode/result').set({
      'outcome': outcome,
      'narration': result.narration,
    });
    await _db.child('rooms/$roomCode/status').set('done');
  }

  /// 相手プレイヤーのモンスターデータを取得
  Future<Monster?> getOpponentMonster(
    String roomCode,
    int myPlayerNum,
  ) async {
    final opponentNum = myPlayerNum == 1 ? 2 : 1;
    final snapshot =
        await _db.child('rooms/$roomCode/player$opponentNum').get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    data.remove('ready');
    return Monster.fromJson(data);
  }

  /// 部屋データを削除
  Future<void> deleteRoom(String roomCode) async {
    await _db.child('rooms/$roomCode').remove();
  }

  /// 部屋の status 変更を監視
  Stream<String> listenForStatus(String roomCode) {
    return _db.child('rooms/$roomCode/status').onValue.map(
          (event) => (event.snapshot.value as String?) ?? 'unknown',
        );
  }
}
