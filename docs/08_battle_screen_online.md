# 08: バトル画面のオンライン対応

## 依存: 03, 04（RoomService + GameProvider リファクタ完了後）
## 並列グループ: D
## 並列実行可能: 05, 06, 07 と同時実行可

## やること

### 変更ファイル: `lib/screens/battle_screen.dart`

### 1. カードフリップ演出
- オンラインモードでも同じフリップ演出を使う
- 相手のモンスターが `isGeneratingCpuImage` の代わりに画像生成中かを表示

### 2. 「戦う！」ボタンの挙動分岐

#### CPU モード（現状のまま）
- `game.startBattle()` を呼ぶ

#### Online モード
- Player1:
  - `game.startBattle()` を呼ぶ（内部でGeminiジャッジ → Firebase送信）
- Player2:
  - 「戦う！」ボタンを表示しない、または「ジャッジを待機中...」表示
  - GameProvider がFirebaseから結果を受信するのを待つ

### 3. 結果表示の変更

#### CPU モード（現状のまま）
- WIN! / LOSE... / DRAW

#### Online モード
- 自分が勝った場合: 「WIN!」（ゴールド）
- 自分が負けた場合: 「LOSE...」（グレー）
- 引き分け: 「DRAW」
- playerNumber に応じて outcome の解釈を反転:
  - Player1: outcome=player1_win → WIN
  - Player2: outcome=player1_win → LOSE

### 4. 「もう一度」ボタン
- 両モードとも同じ（ホームに戻る）
- オンラインモード時は部屋を削除してから戻る

## 完了条件
- CPU対戦が現状通り動作する
- オンラインモードで Player1 がジャッジを実行し結果が表示される
- オンラインモードで Player2 がジャッジ結果を受信して表示される
- playerNumber に応じて WIN/LOSE が正しく表示される
