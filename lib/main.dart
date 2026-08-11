import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'screens/battle_screen.dart';
import 'screens/chronicle_screen.dart';
import 'screens/home_screen.dart';
import 'screens/room_screen.dart';
import 'screens/summon_result_screen.dart';
import 'screens/summon_screen.dart';
import 'screens/throne_screen.dart';
import 'screens/update_required_screen.dart';
import 'screens/waiting_screen.dart';
import 'services/version_gate_service.dart';

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
    // Attach Firebase Analytics to the navigator so every screen change
    // gets logged as a screen_view event. Unique-user + DAU/MAU rollups
    // are auto-collected in the Firebase Console.
    final analytics = FirebaseAnalytics.instance;
    final observer = FirebaseAnalyticsObserver(analytics: analytics);
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'チートモンスター',
        theme: gameTheme(),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [observer],
        home: const _VersionGate(),
        routes: {
          '/room': (_) => const RoomScreen(),
          '/summon': (_) => const SummonScreen(),
          '/summon-result': (_) => const SummonResultScreen(),
          '/waiting': (_) => const WaitingScreen(),
          '/battle': (_) => const BattleScreen(),
          '/throne': (_) => const ThroneScreen(),
          '/chronicle': (_) => const ChronicleScreen(),
        },
      ),
    );
  }
}

/// Runs a one-shot version check against RTDB /config/minVersion. While
/// the check is in-flight we show a lightweight splash (blank scaffold) so
/// the home doesn't briefly flash before the gate can raise. On error or
/// missing config, defaults to open.
class _VersionGate extends StatefulWidget {
  const _VersionGate();

  @override
  State<_VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<_VersionGate> {
  final _service = VersionGateService();
  bool _checking = true;
  String? _blockingMin; // non-null when we need to gate
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final results = await Future.wait([
        _service.fetchMinVersion(),
        PackageInfo.fromPlatform().then((i) => i.version),
      ]);
      final min = results[0];
      final current = results[1] ?? '';
      if (!mounted) return;
      setState(() {
        _currentVersion = current;
        _blockingMin = (min != null &&
                min.isNotEmpty &&
                _service.isBelow(current, min))
            ? min
            : null;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: SizedBox.expand(),
      );
    }
    if (_blockingMin != null) {
      return UpdateRequiredScreen(
        currentVersion: _currentVersion,
        minVersion: _blockingMin!,
      );
    }
    return const HomeScreen();
  }
}
