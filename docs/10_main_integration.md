# 10: main.dart ルーティング & Firebase 初期化

## 依存: 01, 05, 06（Firebase セットアップ + 新規画面完了後）
## 並列グループ: E

## やること

### 変更ファイル: `lib/main.dart`

### 1. Firebase 初期化
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

### 2. ルート追加
```dart
routes: {
  '/': (_) => const HomeScreen(),
  '/summon': (_) => const SummonScreen(),
  '/summon-result': (_) => const SummonResultScreen(),
  '/battle': (_) => const BattleScreen(),
  '/room': (_) => const RoomScreen(),       // 追加
  '/waiting': (_) => const WaitingScreen(),  // 追加
},
```

### 3. import 追加
- `room_screen.dart`
- `waiting_screen.dart`
- `firebase_core`
- `firebase_options.dart`

## 完了条件
- アプリ起動時にFirebaseが初期化される
- `/room` と `/waiting` のルートが動作する
- 既存ルートが壊れていない
- `flutter analyze` エラーなし
