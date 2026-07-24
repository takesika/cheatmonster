import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../models/battle_result.dart';
import '../models/monster.dart';

class RoomService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;
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
  /// imageBytes が渡された場合は Firebase Storage にアップロードし、URL も RTDB に書く
  Future<void> submitMonster(
    String roomCode,
    int playerNum,
    Monster monster, {
    int pvpWins = 0,
    int pvpTotalMatches = 0,
    Uint8List? imageBytes,
  }) async {
    String? imageUrl;
    if (imageBytes != null) {
      try {
        final ref = _storage.ref('rooms/$roomCode/player$playerNum.png');
        await ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/png'),
        );
        imageUrl = await ref.getDownloadURL();
      } catch (_) {
        // upload failed — fall through with null URL; opponent regenerates
      }
    }

    await _db.child('rooms/$roomCode/player$playerNum').set({
      ...monster.toJson(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'ready': true,
      'pvpWins': pvpWins,
      'pvpTotalMatches': pvpTotalMatches,
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

  /// 相手プレイヤーのモンスターデータと戦績を取得
  /// imageUrl が含まれている場合は画像もダウンロードして imageBytes をセット
  Future<({Monster monster, int pvpWins, int pvpTotalMatches})?>
      getOpponentMonster(
    String roomCode,
    int myPlayerNum,
  ) async {
    final opponentNum = myPlayerNum == 1 ? 2 : 1;
    final snapshot =
        await _db.child('rooms/$roomCode/player$opponentNum').get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final pvpWins = (data['pvpWins'] as num?)?.toInt() ?? 0;
    final pvpTotalMatches = (data['pvpTotalMatches'] as num?)?.toInt() ?? 0;
    final imageUrl = data['imageUrl'] as String?;

    Uint8List? imageBytes;
    if (imageUrl != null) {
      try {
        final res = await http.get(Uri.parse(imageUrl));
        if (res.statusCode == 200) {
          imageBytes = res.bodyBytes;
        }
      } catch (_) {
        // download failed — caller can fall back to regeneration
      }
    }

    data.remove('ready');
    data.remove('pvpWins');
    data.remove('pvpTotalMatches');
    data.remove('imageUrl');
    return (
      monster: Monster.fromJson(data).copyWith(imageBytes: imageBytes),
      pvpWins: pvpWins,
      pvpTotalMatches: pvpTotalMatches,
    );
  }

  /// 「続行」フラグをセット
  Future<void> setContinue(String roomCode, int playerNum) async {
    await _db.child('rooms/$roomCode/player${playerNum}_continue').set(true);
  }

  /// 「終わる」フラグをセット
  Future<void> setQuit(String roomCode, int playerNum) async {
    await _db.child('rooms/$roomCode/player${playerNum}_quit').set(true);
  }

  /// 相手の続行/終了選択を監視するStream
  /// "continue" = 相手が続行、"quit" = 相手が終了
  Stream<String> listenForContinueStatus(String roomCode, int playerNum) {
    final opponentNum = playerNum == 1 ? 2 : 1;
    return _db.child('rooms/$roomCode').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return 'waiting';
      final data = Map<String, dynamic>.from(value as Map);
      if (data['player${opponentNum}_quit'] == true) return 'quit';
      if (data['player${opponentNum}_continue'] == true) return 'continue';
      return 'waiting';
    });
  }

  /// 次のバトルのためにプレイヤー・結果データをリセット
  /// アップロード済み画像も削除
  Future<void> resetForNextBattle(String roomCode) async {
    await Future.wait([
      _db.child('rooms/$roomCode/player1').remove(),
      _db.child('rooms/$roomCode/player2').remove(),
      _db.child('rooms/$roomCode/result').remove(),
      _db.child('rooms/$roomCode/player1_continue').remove(),
      _db.child('rooms/$roomCode/player2_continue').remove(),
      _db.child('rooms/$roomCode/player1_quit').remove(),
      _db.child('rooms/$roomCode/player2_quit').remove(),
      _deleteStorageImage(roomCode, 1),
      _deleteStorageImage(roomCode, 2),
    ]);
    await _db.child('rooms/$roomCode/status').set('ready');
  }

  /// 部屋データと関連画像を削除
  Future<void> deleteRoom(String roomCode) async {
    await Future.wait([
      _db.child('rooms/$roomCode').remove(),
      _deleteStorageImage(roomCode, 1),
      _deleteStorageImage(roomCode, 2),
    ]);
  }

  Future<void> _deleteStorageImage(String roomCode, int playerNum) async {
    try {
      await _storage.ref('rooms/$roomCode/player$playerNum.png').delete();
    } catch (_) {
      // already deleted or never uploaded — ignore
    }
  }

  /// 部屋の status 変更を監視
  Stream<String> listenForStatus(String roomCode) {
    return _db.child('rooms/$roomCode/status').onValue.map(
          (event) => (event.snapshot.value as String?) ?? 'unknown',
        );
  }
}
