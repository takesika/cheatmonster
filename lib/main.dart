import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'screens/battle_screen.dart';
import 'screens/home_screen.dart';
import 'screens/room_screen.dart';
import 'screens/summon_result_screen.dart';
import 'screens/summon_screen.dart';
import 'screens/waiting_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'チートモンスター',
        theme: gameTheme(),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/room': (_) => const RoomScreen(),
          '/summon': (_) => const SummonScreen(),
          '/summon-result': (_) => const SummonResultScreen(),
          '/waiting': (_) => const WaitingScreen(),
          '/battle': (_) => const BattleScreen(),
        },
      ),
    );
  }
}
