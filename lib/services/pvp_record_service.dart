import 'package:shared_preferences/shared_preferences.dart';

import '../models/battle_result.dart';

class PvpRecordService {
  static const _keyTotalMatches = 'pvp_total_matches';
  static const _keyWins = 'pvp_wins';

  Future<int> getTotalMatches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalMatches) ?? 0;
  }

  Future<int> getWins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWins) ?? 0;
  }

  Future<void> recordMatch(BattleOutcome outcome) async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt(_keyTotalMatches) ?? 0;
    await prefs.setInt(_keyTotalMatches, total + 1);

    if (outcome == BattleOutcome.win) {
      final wins = prefs.getInt(_keyWins) ?? 0;
      await prefs.setInt(_keyWins, wins + 1);
    }
  }
}
