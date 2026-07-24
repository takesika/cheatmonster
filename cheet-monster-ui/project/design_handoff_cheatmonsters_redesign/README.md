# Handoff: Cheat Monsters リデザイン（"叡智ノ写本" / Arcane Codex 世界観）

## 概要

iOS アプリ **Cheat Monsters**（カードゲーム：プレイヤーが特殊能力を文章で記入し、AI が裁定するTCG）の全画面リデザイン提案。

既存版（v1.2）の「ペールパープル × ゴールド × ネイビー」基調から、**「魔導書／審判」をメタファーとした和洋折衷の世界観**へ刷新する。

- **ブランド名のみ英語**（`Cheat Monsters`）
- **UI 本文・ラベル・ボタン・コピーは全て日本語**（漢字＋カタカナ）
- 落ち着いた**深藍 × くすみゴールド × 朱**の三色構成
- AI 判定を「神託の予言者の裁定」として世界観の核に据える

---

## このバンドルについて

このフォルダに含まれるファイルは **デザイン参照（HTMLプロトタイプ）** であって、本番コードとしてそのまま流用するものではない。実装タスクは、**既存の Cheat Monsters iOS アプリの環境（SwiftUI / UIKit など）に、これらの HTML デザインを再構築すること**。

実プロダクトの既存コードベースのパターン・命名規則・コンポーネント構成に従って実装すること。HTML/CSS/React のコードはあくまで「最終的な見た目とインタラクションの仕様書」として参照する。

---

## 忠実度（Fidelity）

**ハイファイ（Hi-Fi）**：色・タイポ・余白・サイズ・コピー全て確定値。下記「デザイントークン」の値で**ピクセルパーフェクト**に再現すること。

ただし以下は**プレースホルダー**：
- カードアートの SVG（`cm-card.jsx` 内の `flame` / `thunder` モンスター絵）→ **本番では正式なカードアートに差し替え**
- AI 判定文サンプル（「ヴォルテックスが場に〜」）→ 実際のゲムニ API 出力で置き換え
- iOS ステータスバー（時刻 9:41）→ 実機の値

---

## 画面一覧（全6画面）

実装対象画面は以下の通り。詳細レイアウトは `cm-screens.jsx` の各関数を参照。

| # | 関数名 | 画面名 | 役割 |
|---|---|---|---|
| 1 | `HomeScreen` | ホーム | ロゴ／直近召喚カード／本日の召喚権／モード選択（三層の塔・決闘の間）／戦績 |
| 2 | `SummonScreen` | 召喚（記入） | 真名・異能・戦力（攻/守は伏せ）の入力フォーム |
| 3 | `SummonResultScreen` | 召喚成功 | 召喚されたカードを大きく表示。「審判の場へ」CTA |
| 4 | `BattleReadyScreen` | 審判の場（バトル準備） | 自カードと敵カードが対峙、中央に巨大な「對」字、AI裁定者バナー、「開戦」CTA |
| 5 | `ResultScreen` | 神託の裁定（結果発表） | 判決書フォーマット。勝/敗の朱印、両カード比較、AI判定文、予言者の印 |
| 6 | `RoomScreen` | 決闘の間（対人ロビー） | 部屋を開く（合言葉発行）／部屋に入る（合言葉入力）、直近対戦相手 |

### 各画面の詳細レイアウト

- **正確なサイズ・余白・フォントサイズ・色**は全て `cm-screens.jsx` の JSX 内に inline style として記述してある。
- 画面サイズは **iPhone 15 / 14 Pro 想定で 393 × 852 px**（`PHONE_W` / `PHONE_H`、`cm-tokens.jsx`）。
- 全画面の上端には iOS ステータスバー（高さ 47px 想定）。

---

## デザイントークン

`cm-tokens.jsx` の `CM_THEMES.arcane` を参照。

### カラーパレット（メインテーマ "Arcane Codex"）

| トークン | 値 | 用途 |
|---|---|---|
| `bg` | `#0c1228` | 画面背景（深藍） |
| `bgDeep` | `#06091a` | 背景の下端グラデ終点 |
| `panel` | `#141b3a` | カード／パネル背景 |
| `panelLight` | `#1d2750` | パネルハイライト |
| `parchment` | `#ede0c0` | 羊皮紙（カード本体／判決書） |
| `parchmentDeep` | `#cfb98c` | 羊皮紙の影部 |
| `ink` | `#e8dcb8` | 暗背景上のテキスト |
| `inkDark` | `#1c1a2c` | 羊皮紙上のテキスト |
| `inkSoft` | `#9aa4c6` | 暗背景上の補助テキスト |
| `inkSoftDark` | `#5a4f3c` | 羊皮紙上の補助テキスト |
| `seal` | `#8a3a3a` | 朱（朱印・敵カード） |
| `sealDeep` | `#5a2424` | 朱の濃色 |
| `gold` | `#b89752` | くすみゴールド（メインアクセント） |
| `goldLight` | `#d4b97a` | ゴールドのハイライト |
| `goldDeep` | `#7e6228` | ゴールドの影／枠 |
| `line` | `#2e3760` | 罫線 |

サブテーマ "Cathedral Light"（`parchment`）も用意してあり Tweaks で切替可能。本番では Arcane（暗）のみ採用想定。

### タイポグラフィ

| 用途 | フォント |
|---|---|
| 本文・ラベル・タイトル全般（日本語） | `Hiragino Mincho ProN` → `Yu Mincho` → `Noto Serif JP` |
| 数字・装飾英字 | `Cinzel` → `Trajan Pro` → serif |
| 全体ベース | `EB Garamond` → `Cormorant Garamond` → `Hiragino Mincho ProN` |

**サイズスケール**（letter-spacing は `0.1em〜0.5em` で日本語の格を表現）：
- ロゴ大: 38px / weight 800
- 画面タイトル: 22–26px / weight 800
- セクションラベル: 11px（letter-spacing 0.3–0.5em）
- 本文: 13–16px / line-height 1.5–1.9
- 補助テキスト: 10–12px

### 余白・角丸

- 画面横パディング: 24px
- 角丸: **3〜4px**（極小）— 中世写本の質感を出すため大きな角丸は使わない
- ボタン縦パディング: 12〜16px

### 主要コンポーネントスタイル（`cm-tokens.jsx` の `<style>` 内に CSS で定義）

| クラス | 用途 |
|---|---|
| `.cm-night-bg` | 深藍の星空グラデ背景 |
| `.cm-parchment-bg` | 羊皮紙テクスチャ背景 |
| `.cm-engraved` | 金箔押しエングレーブ風テキスト（gradient + drop-shadow） |
| `.cm-wax-seal` | 円形の朱の封蝋シール（radial gradient + 内側破線） |
| `.cm-gold-frame` | 二重金線の額装 |
| `.cm-btn-gold` / `.cm-btn-gold-outline` | 金ボタン |
| `.cm-btn-crimson` | 朱ボタン（メインCTA） |
| `.cm-sigil` / `.cm-sigil-on` / `.cm-sigil-off` | 召喚権ピップ（朱の封蝋丸） |

---

## インタラクション・アニメーション

| 場所 | 挙動 |
|---|---|
| 全画面の魔法陣（`ArcaneCircle`） | `cm-rotate` 80秒/1周のゆっくり回転 |
| 召喚成功画面の後光 | `cm-rotate-cw` 60秒/1周のコニックグラデ回転 |
| ボタンタップ | iOS 標準の opacity ハイライト（spec 未指定） |
| 画面遷移 | iOS 標準の push/modal を想定（spec 未指定） |

> ※ 演出（召喚エフェクト・対峙アニメ・判決書がめくれる演出など）は本HTMLでは静止表示。本番ではゲームらしさを足すために 0.5–1秒の入場アニメを推奨（fade + scale + rotate）。

---

## コピー（重要：英語化禁止）

メインタイトル `Cheat Monsters` 以外、UI コピーは全て日本語（漢字＋カタカナ）。下表は新規／既存変更分の主要コピー：

| 旧 | 新 |
|---|---|
| Solo / The Tower | 一人で挑む／**三層の塔** |
| Duel Chamber | 友と挑む／**決闘の間** |
| Daily Sigils | **本日の召喚権** |
| Last Summon | **直近の召喚** |
| Summon a Beast | **召喚の儀** |
| TRUE NAME / ARCANE GIFT / Vigor | **壱・真名／弐・異能／参・戦力** |
| ATK / DEF | **攻 / 守** |
| Summoned | **召喚成功** |
| Field of Judgment | **審判の場** |
| VS | **對** |
| Oracle's Decree | **神託の裁定** |
| Arcane Oracle · Gemini 2.5 | **神託の予言者 ・ ジェミニ** |
| WIN / LOSS | **勝 / 敗** |
| HOST / JOIN | **主 / 客** |
| Recent Foes | **直近の対戦相手** |
| Sigil Code（合言葉サンプル） | **朱雀 ・ 玄武**（漢字2文字×2セット） |

**ブランドタグライン**（ロゴ下）: 「叡智ノ写本」「叡智ハ伝説ヲ鍛ウ」

---

## ファイル一覧

```
design_handoff_cheatmonsters_redesign/
├── README.md                    ← このファイル
├── cheatmonster-redesign.html   ← エントリー（design_canvas に6画面並べたもの）
├── cm-app.jsx                   ← React マウント＋design_canvas 構成
├── cm-tokens.jsx                ← デザイントークン（色・サイズ・CSS）★最重要
├── cm-screens.jsx               ← 全6画面の React コンポーネント ★最重要
├── cm-card.jsx                  ← MonsterCard コンポーネント（カード本体・カード裏面）
├── ios-frame.jsx                ← iOS デバイス枠（参照用、本番不要）
├── design-canvas.jsx            ← 6画面横並べ用ラッパー（参照用、本番不要）
└── tweaks-panel.jsx             ← デザインTweakパネル（参照用、本番不要）
```

**実装で参照すべきは主に：**
1. `cm-tokens.jsx` — 全カラー・タイポ・共通CSS
2. `cm-screens.jsx` — 全画面の正確なレイアウト
3. `cm-card.jsx` — カードコンポーネント

---

## 開く方法

ブラウザで `cheatmonster-redesign.html` を開くと6画面が横並びで表示される。各画面をクリックすると拡大表示。右下「Tweaks」パネルでテーマ切替可能。
