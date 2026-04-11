# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## コミュニケーション

ユーザーとのやりとりは日本語で行うこと。

## Build & Run Commands

```bash
# アプリ実行
flutter run

# 静的解析
flutter analyze

# テスト実行
flutter test

# 単一テストファイル実行
flutter test test/path_to_test.dart

# iOS ビルド
flutter build ios
```

Flutter SDK requirement: ^3.5.3

## Architecture

Flutter製モンスターカードバトルゲーム。プレイヤーがモンスターを召喚し（ATK/DEF 1-100のランダム + ユーザー入力の特殊能力 max20文字）、Gemini LLMが能力を創造的に解釈してバトルを審判する。モンスターカード画像はGemini画像生成APIで生成。

### State Management

単一の `GameProvider`（ChangeNotifier + Provider）で全状態を管理。フロー:

1. **Home** → 1日のバトル上限を読み込み（5回/日、SharedPreferences）
2. **Summon** → `createPlayerMonster()` でプレイヤーモンスター + CPU対戦相手を並列生成、両方の画像生成も同時実行
3. **SummonResult** → アニメーション演出、画像生成完了を待機
4. **Battle** → CPU出現フリップアニメ → Geminiがバトル審判 → ナレーション + 結果表示

### Services

- **GeminiService** — `gemini-2.5-flash`でバトル審判。JSON `{result, narration}` を返す。API失敗時はステータス比較にフォールバック
- **ReplicateService**（実際はGemini画像API使用）— `gemini-3.1-flash-image-preview`で遊戯王風カードアート生成。base64画像バイトを返す
- **CpuOpponentService** — Geminiでランダムなカタカナ名 + 能力のCPUモンスター生成。失敗時は「ナゾモンスター」にフォールバック
- **BattleLimitService** — 1日5回制限。SharedPreferencesで管理、日付変更でリセット
- **InputSanitizer** — 改行・バッククォート・Markdown・HTMLタグ除去。20文字制限。全API呼び出し前にユーザー入力に適用

### Environment

APIキーは `flutter_dotenv` で `.env` ファイルから読み込み（pubspec.yaml の assets に登録済み）。`lib/config/env.dart`（`Env.geminiApiKey`）経由でアクセス。

### Key Patterns

- 全Gemini API呼び出しで `InputSanitizer.sanitize()` を適用（プロンプトインジェクション防止）
- 画像生成は並列で fire-and-forget — `Monster.copyWith(imageBytes:)` で完了時にモデル更新
- CPU モンスター生成と画像生成は召喚フェーズで同時実行
- 全API失敗にフォールバック動作あり（バトル→ステータス比較、画像→プレースホルダー、CPU→固定モンスター）

## Planned: Online Multiplayer

`docs/` にFirebase Realtime DBによるルームコード方式のオンライン対人対戦の実装計画あり（11タスク、依存関係グラフ・並列実行プラン付き）。`docs/00_overview.md` 参照。

## Language

UIテキスト・プロンプトは日本語。コード（変数名・コメント）は英語。
