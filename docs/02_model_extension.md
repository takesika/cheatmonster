# 02: モデル拡張

## 依存: なし（Firebase不要で実装可能）
## 並列グループ: B
## 並列実行可能: 09 と同時実行可

## やること

### 1. GameMode enum 作成
**新規ファイル**: `lib/models/game_mode.dart`
```dart
enum GameMode { cpu, online }
```

### 2. Monster モデルに JSON シリアライズ追加
**変更ファイル**: `lib/models/monster.dart`

```dart
// 追加メソッド
Map<String, dynamic> toJson() => {
  'name': name,
  'atk': atk,
  'def': def,
  'specialAbility': specialAbility,
};

// 追加ファクトリ
factory Monster.fromJson(Map<String, dynamic> json) => Monster(
  name: json['name'] as String,
  atk: json['atk'] as int,
  def: json['def'] as int,
  specialAbility: json['specialAbility'] as String,
);
```

- `imageBytes` はJSON に含めない（サイズが大きすぎるため）
- 相手のモンスター画像は受信側で各自生成する

## 完了条件
- `GameMode` enum が存在する
- `Monster.toJson()` と `Monster.fromJson()` が動作する
- 既存のCPU対戦フローが壊れていない
- `flutter analyze` エラーなし
