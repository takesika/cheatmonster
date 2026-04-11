# 09: GeminiService のオンライン対応

## 依存: なし（Firebase不要で実装可能）
## 並列グループ: B
## 並列実行可能: 02 と同時実行可

## やること

### 変更ファイル: `lib/services/gemini_service.dart`

### 変更内容

#### `judgeBattle()` メソッドのシグネチャ変更
```dart
// Before
Future<BattleResult> judgeBattle(Monster player, Monster cpu)

// After
Future<BattleResult> judgeBattle(Monster player, Monster opponent, {bool isOnline = false})
```

#### プロンプトの roleラベル パラメータ化
- CPU モード: `<monster role="player">` と `<monster role="cpu">`（現状のまま）
- Online モード: `<monster role="player1">` と `<monster role="player2">`
- プロンプト冒頭の説明文もオンライン時は「2人のプレイヤーのモンスターバトル」に調整

#### outcome の解釈
- CPU モード: "win" = プレイヤーの勝ち（現状のまま）
- Online モード: "win" = player1の勝ち
- BattleResult に追加情報は不要（GameProvider 側で playerNumber と組み合わせて判断）

## 完了条件
- CPU対戦が現状通り動作する
- isOnline=true の場合に適切なプロンプトが生成される
- `flutter analyze` エラーなし
