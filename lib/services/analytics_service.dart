import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around FirebaseAnalytics for the handful of gameplay
/// events we want to see in the Firebase Console. Auto-collected events
/// (session_start, first_open, screen_view via observer) don't need to
/// go through here.
class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  static Future<void> throneChallenge() async {
    await _analytics.logEvent(name: 'throne_challenge');
  }

  static Future<void> crownWon() async {
    await _analytics.logEvent(name: 'crown_won');
  }

  static Future<void> monsterSummoned({required String mode}) async {
    await _analytics.logEvent(
      name: 'monster_summoned',
      parameters: {'mode': mode},
    );
  }

  static Future<void> battleFinished({
    required String mode,
    required String outcome, // win / lose / draw
  }) async {
    await _analytics.logEvent(
      name: 'battle_finished',
      parameters: {'mode': mode, 'outcome': outcome},
    );
  }

  static Future<void> reportSubmitted({required String type}) async {
    await _analytics.logEvent(
      name: 'report_submitted',
      parameters: {'type': type},
    );
  }
}
