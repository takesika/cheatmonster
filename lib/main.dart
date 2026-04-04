import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/game_provider.dart';
import 'screens/battle_screen.dart';
import 'screens/home_screen.dart';
import 'screens/summon_result_screen.dart';
import 'screens/summon_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
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
          '/summon': (_) => const SummonScreen(),
          '/summon-result': (_) => const SummonResultScreen(),
          '/battle': (_) => const BattleScreen(),
        },
      ),
    );
  }
}
