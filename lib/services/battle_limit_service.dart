import 'package:shared_preferences/shared_preferences.dart';

class BattleLimitService {
  static const _keyDate = 'battle_date';
  static const _keyCount = 'battle_count';
  static const maxBattlesPerDay = 5;

  Future<int> getRemainingBattles() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyDate) ?? '';

    if (savedDate != today) {
      return maxBattlesPerDay;
    }
    final count = prefs.getInt(_keyCount) ?? 0;
    return (maxBattlesPerDay - count).clamp(0, maxBattlesPerDay);
  }

  Future<bool> canBattle() async {
    return (await getRemainingBattles()) > 0;
  }

  Future<void> recordBattle() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyDate) ?? '';

    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 1);
    } else {
      final count = prefs.getInt(_keyCount) ?? 0;
      await prefs.setInt(_keyCount, count + 1);
    }
  }

  /// Give back one battle if the challenge could not be honoured
  /// (e.g. the throne changed while judging).
  Future<void> refundBattle() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyDate) ?? '';
    if (savedDate != today) return;
    final count = prefs.getInt(_keyCount) ?? 0;
    if (count <= 0) return;
    await prefs.setInt(_keyCount, count - 1);
  }
}
