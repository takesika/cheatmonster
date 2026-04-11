# 04: GameProvider リファクタ

## 依存: 02（モデル拡張完了後）
## 並列グループ: C
## 並列実行可能: 03 と同時実行可

## やること

### 変更ファイル: `lib/providers/game_provider.dart`

### 1. 新規フィールド追加
```dart
GameMode gameMode = GameMode.cpu;
String? roomCode;
int? playerNumber;  // 1 or 2
bool isWaitingForOpponent = false;
```

### 2. 新規メソッド

#### `void setGameMode(GameMode mode)`
- gameMode を設定
- notifyListeners()

#### `void setRoomInfo(String code, int playerNum)`
- roomCode と playerNumber を設定

#### `Future<void> createPlayerMonsterOnline(String name, String specialAbility)`
- CPU対戦の `createPlayerMonster` と似ているが:
  - CPU生成は行わない
  - プレイヤー画像生成のみ実行
  - 完了後に RoomService.submitMonster() を呼ぶ（呼び出しは画面側でもOK）

#### `Future<void> setOpponentFromJson(Map<String, dynamic> json)`
- 相手のモンスターデータを受信してセット
- `Monster.fromJson()` で変換
- 画像生成を開始

#### `Future<void> startOnlineBattle()`
- playerNumber == 1 の場合:
  - Gemini でジャッジ
  - RoomService.submitResult() で結果をFirebaseに送信
  - battleResult にセット
- playerNumber == 2 の場合:
  - RoomService.listenForResult() で結果を待つ
  - 受信したら battleResult にセット

### 3. 既存メソッド変更

#### `createPlayerMonster()` 
- `if (gameMode == GameMode.cpu)` の場合のみ既存のCPU生成ロジックを実行
- `if (gameMode == GameMode.online)` の場合は `createPlayerMonsterOnline()` を呼ぶ

#### `reset()`
- 追加フィールド（gameMode, roomCode, playerNumber, isWaitingForOpponent）もリセット

### 4. RoomService の依存
- RoomService をフィールドとして持つ
- ただし RoomService は 03 で別途実装されるため、インターフェースだけ合わせておく
- 03 完了後に統合

## 完了条件
- GameMode による分岐が実装されている
- CPU対戦の既存フローが壊れていない
- オンライン用の新規メソッドのシグネチャが定義されている
- `flutter analyze` エラーなし
