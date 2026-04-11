# オンライン対人対戦 実装計画

## 概要
チートモンスターに Firebase Realtime DB を使った部屋コード方式のオンライン対人対戦を追加する。

## タスク一覧

| # | タスク | 依存 | 並列可能グループ |
|---|--------|------|-----------------|
| 01 | Firebase セットアップ | なし | A（手動作業） |
| 02 | モデル拡張（GameMode, Monster JSON化） | なし | B |
| 03 | RoomService 実装 | 01 | C |
| 04 | GameProvider リファクタ | 02 | C |
| 05 | ルーム画面 実装 | 03 | D |
| 06 | 待機画面 実装 | 03 | D |
| 07 | 既存画面の改修（Home, Summon, SummonResult） | 02, 04 | D |
| 08 | バトル画面のオンライン対応 | 03, 04 | D |
| 09 | GeminiService のオンライン対応 | なし | B |
| 10 | main.dart ルーティング & Firebase初期化 | 01, 05, 06 | E |
| 11 | 結合テスト & エラーハンドリング | 全タスク | F |

## 並列実行プラン

```
Phase 1 (並列グループ A+B):
  Agent A: 01 Firebase セットアップ（ユーザーの手動作業をガイド）
  Agent B: 02 モデル拡張 + 09 GeminiService改修（Firebase不要の変更）

Phase 2 (並列グループ C):
  Agent C-1: 03 RoomService 実装
  Agent C-2: 04 GameProvider リファクタ

Phase 3 (並列グループ D):
  Agent D-1: 05 ルーム画面 + 06 待機画面（新規画面）
  Agent D-2: 07 既存画面改修 + 08 バトル画面オンライン対応

Phase 4 (グループ E):
  10 main.dart 統合

Phase 5 (グループ F):
  11 結合テスト & エラーハンドリング
```
