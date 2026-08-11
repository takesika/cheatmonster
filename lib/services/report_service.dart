import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// Handles user-generated content reporting + per-device blocklists.
///
/// A report writes an anonymous entry to `/reports/{pushId}` on RTDB so the
/// operator can review, and also adds the reported content to a local
/// SharedPreferences blocklist so the reporter never sees it again. This
/// covers the moderation / report / block trio Apple asks of any UGC surface
/// (Guideline 1.2), even though the app has no user identity to work with.
class ReportService {
  static const _kBlockedChampionUpdatedAts = 'blocked_champion_updated_ats';
  static const _kBlockedHistoryKeys = 'blocked_history_keys';

  final DatabaseReference _reportsRef =
      FirebaseDatabase.instance.ref().child('reports');

  Set<int> _blockedChampionUpdatedAts = {};
  Set<String> _blockedHistoryKeys = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _blockedChampionUpdatedAts = (prefs.getStringList(_kBlockedChampionUpdatedAts) ?? [])
        .map((s) => int.tryParse(s) ?? 0)
        .where((n) => n > 0)
        .toSet();
    _blockedHistoryKeys =
        (prefs.getStringList(_kBlockedHistoryKeys) ?? []).toSet();
    _loaded = true;
  }

  bool isChampionBlocked(int updatedAt) =>
      _blockedChampionUpdatedAts.contains(updatedAt);

  bool isHistoryBlocked(String key) => _blockedHistoryKeys.contains(key);

  /// Report the current champion and hide it locally. `reason` is a free-form
  /// short string from the user (e.g. "差別" / "性的表現" / "その他").
  Future<void> reportChampion({
    required int updatedAt,
    required String name,
    required String ability,
    required String reason,
  }) async {
    await load();
    _blockedChampionUpdatedAts.add(updatedAt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kBlockedChampionUpdatedAts,
        _blockedChampionUpdatedAts.map((n) => n.toString()).toList());
    try {
      await _reportsRef.push().set({
        'type': 'champion',
        'updatedAt': updatedAt,
        'name': name,
        'ability': ability,
        'reason': reason,
        'reportedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Local block still stands even if the remote write fails.
    }
    AnalyticsService.reportSubmitted(type: 'champion');
  }

  /// Report a chronicle entry and hide it locally.
  Future<void> reportHistory({
    required String key,
    required String winnerName,
    required String defeatedName,
    required String defeatedAbility,
    required String reason,
  }) async {
    await load();
    _blockedHistoryKeys.add(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kBlockedHistoryKeys, _blockedHistoryKeys.toList());
    try {
      await _reportsRef.push().set({
        'type': 'history',
        'historyKey': key,
        'winnerName': winnerName,
        'defeatedName': defeatedName,
        'defeatedAbility': defeatedAbility,
        'reason': reason,
        'reportedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Local block still stands even if the remote write fails.
    }
    AnalyticsService.reportSubmitted(type: 'history');
  }
}
