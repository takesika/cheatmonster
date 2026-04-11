# 07: 既存画面の改修

## 依存: 02, 04（モデル拡張 + GameProvider リファクタ完了後）
## 並列グループ: D
## 並列実行可能: 05, 06, 08 と同時実行可

## やること

### 1. ホーム画面 (`lib/screens/home_screen.dart`)

#### 追加内容
- 「召喚する」ボタンの下に「対人対戦」ボタンを追加
- 同じスタイル（青グラデーションボタン）だが、テキストと色で差別化
- タップ時:
  - `game.reset()`
  - `game.setGameMode(GameMode.online)`
  - `Navigator.pushNamed(context, '/room')`

### 2. 召喚画面 (`lib/screens/summon_screen.dart`)

#### 変更内容
- AppBar タイトル:
  - CPU: 「モンスター召喚」（現状のまま）
  - Online: 「あなたのモンスターを召喚」
- 遊び方ボックスの表示:
  - Online モードでは非表示、またはオンライン用の説明に差し替え

### 3. 召喚結果画面 (`lib/screens/summon_result_screen.dart`)

#### 変更内容
- ボタンのテキストと遷移先:
  - CPU: 「バトルへ！」→ `/battle`（現状のまま）
  - Online: 「準備完了！」→ Firebaseにモンスター送信 → `/waiting`
- オンライン時の「準備完了！」タップ処理:
  1. RoomService.submitMonster() でモンスターデータ送信
  2. `/waiting` へ遷移

## 完了条件
- CPU対戦の既存フローが一切変わっていない
- オンラインモード時に適切なラベル・遷移先に切り替わる
- `flutter analyze` エラーなし
