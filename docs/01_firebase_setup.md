# 01: Firebase セットアップ

## 依存: なし
## 並列グループ: A（ユーザーの手動作業含む）

## やること

### 1. Firebase プロジェクト作成
- Firebase Console (https://console.firebase.google.com) で新規プロジェクト作成
- プロジェクト名: `cheatmonster`（または任意）

### 2. FlutterFire 設定
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<firebase-project-id>
```
- iOS を選択
- `lib/firebase_options.dart` が自動生成される
- `ios/Runner/GoogleService-Info.plist` が配置される

### 3. パッケージ追加
```bash
flutter pub add firebase_core firebase_database
```

### 4. Realtime Database の有効化
- Firebase Console → Realtime Database → データベースを作成
- ロケーション: asia-southeast1（東京に近い）
- セキュリティルール: テストモードで開始（後で修正）

### 5. セキュリティルール設定
```json
{
  "rules": {
    "rooms": {
      "$roomId": {
        ".read": true,
        ".write": true
      }
    }
  }
}
```

### 6. 動作確認
- `flutter build ios` が通ること
- Firebase の初期化ができること

## 完了条件
- `firebase_options.dart` が生成されている
- `flutter build ios` がエラーなく通る
- Firebase Console で Realtime Database が有効
