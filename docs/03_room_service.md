# 03: RoomService 実装

## 依存: 01（Firebase セットアップ完了後）
## 並列グループ: C
## 並列実行可能: 04 と同時実行可

## やること

### 新規ファイル: `lib/services/room_service.dart`

Firebase Realtime DB の部屋管理サービスを実装する。

### メソッド一覧

#### `Future<String> createRoom()`
- 6桁の英数字コードをランダム生成（大文字A-Z + 0-9）
- 重複チェック（既に存在するコードなら再生成）
- RTDBに部屋データ作成:
  ```
  rooms/{code}/status: "waiting"
  rooms/{code}/createdAt: ServerValue.timestamp
  ```
- コードを返却

#### `Future<bool> joinRoom(String code)`
- 部屋の存在確認
- status が "waiting" か検証
- player2 のエントリを作成
- status を "ready" に更新
- 成功/失敗を返却

#### `Future<void> submitMonster(String roomCode, int playerNum, Monster monster)`
- `rooms/{code}/player{num}/` にモンスターデータ書き込み（toJson）
- `rooms/{code}/player{num}/ready` を true に設定

#### `Stream<bool> listenForOpponent(String roomCode, int playerNum)`
- 相手プレイヤーの `ready` フィールドを監視
- true になったら通知

#### `Stream<Map<String, dynamic>?> listenForResult(String roomCode)`
- `rooms/{code}/result` を監視
- ジャッジ結果が書き込まれたら通知

#### `Future<void> submitResult(String roomCode, BattleResult result, int winnerPlayerNum)`
- `rooms/{code}/result/` にジャッジ結果書き込み
- outcome: "player1_win" | "player2_win" | "draw"
- narration: バトル描写テキスト
- status を "done" に更新

#### `Future<Monster?> getOpponentMonster(String roomCode, int myPlayerNum)`
- 相手プレイヤーのモンスターデータを取得
- `Monster.fromJson()` で変換して返却

#### `Future<void> deleteRoom(String roomCode)`
- 部屋データを削除

#### `Stream<String> listenForStatus(String roomCode)`
- 部屋のstatus変更を監視（待機→準備完了等の遷移検知用）

## 完了条件
- 全メソッドが実装されている
- 部屋の作成→参加→モンスター送信→結果送信の一連の流れがコード上成立する
- `flutter analyze` エラーなし
