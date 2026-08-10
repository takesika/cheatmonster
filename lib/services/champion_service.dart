import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

import '../models/champion.dart';
import '../models/history_entry.dart';
import '../models/monster.dart';

/// Outcomes for a champion-crowning attempt.
enum CrownResult {
  /// Challenger became the new champion.
  crowned,

  /// A different challenger updated the champion in the meantime.
  outdated,

  /// A network or database error prevented the update.
  error,
}

class ChampionService {
  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref().child('champion');
  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref().child('history');
  final DatabaseReference _historyCountRef =
      FirebaseDatabase.instance.ref().child('historyCount');

  /// Fetch the current champion. Returns null if no champion exists yet.
  Future<Champion?> fetchChampion() async {
    final snapshot = await _ref.get();
    if (!snapshot.exists) return null;
    return Champion.fromRaw(snapshot.value);
  }

  /// Try to crown [challenger] as the new champion. The write is only
  /// applied if the current champion's `updatedAt` matches
  /// [expectedPreviousUpdatedAt]. Pass 0 when there is no previous champion
  /// (i.e. we expect `/champion` to be null).
  ///
  /// Uses a fetch-then-set pattern instead of a real transaction because the
  /// Flutter SDK's transaction handler is prone to being invoked with a null
  /// `current` on cache miss, which our earlier abort-on-null logic treated
  /// as an outdated throne. Two truly-simultaneous winners now collapse to
  /// last-writer-wins, which is acceptable for our low-contention scenario.
  ///
  /// The challenger's image bytes are persisted alongside the metadata so
  /// every device sees the same champion artwork.
  Future<({CrownResult result, int previousDefenseCount})> crown({
    required Monster challenger,
    required int expectedPreviousUpdatedAt,
  }) async {
    try {
      final snapshot = await _ref.get();
      final isMap = snapshot.exists && snapshot.value is Map;
      final map = isMap ? (snapshot.value as Map) : null;
      final currentUpdatedAt = (map?['updatedAt'] as num?)?.toInt() ?? 0;
      final previousDefenseCount =
          (map?['defenseCount'] as num?)?.toInt() ?? 0;

      if (currentUpdatedAt != expectedPreviousUpdatedAt) {
        return (
          result: CrownResult.outdated,
          previousDefenseCount: previousDefenseCount,
        );
      }

      final data = <String, Object>{
        'name': challenger.name,
        'atk': challenger.atk,
        'def': challenger.def,
        'specialAbility': challenger.specialAbility,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'defenseCount': 0,
      };
      if (challenger.imageBytes != null) {
        data['imageBase64'] = base64Encode(challenger.imageBytes!);
      }
      await _ref.set(data);
      return (
        result: CrownResult.crowned,
        previousDefenseCount: previousDefenseCount,
      );
    } catch (_) {
      return (result: CrownResult.error, previousDefenseCount: 0);
    }
  }

  /// Bump the current champion's defense counter by one, but only if the
  /// throne is still occupied by the same champion the caller just fought.
  /// Non-atomic (fetch-then-set) so a race between two simultaneous defenders
  /// may drop one of the increments; acceptable for a nice-to-have stat.
  Future<void> recordDefense({required int expectedUpdatedAt}) async {
    try {
      final snapshot = await _ref.get();
      if (!snapshot.exists || snapshot.value is! Map) return;
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final currentUpdatedAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
      if (currentUpdatedAt != expectedUpdatedAt) return;
      final currentCount = (data['defenseCount'] as num?)?.toInt() ?? 0;
      await _ref.child('defenseCount').set(currentCount + 1);
    } catch (_) {
      // best-effort — silently ignore failures
    }
  }

  /// Append a new entry to the chronicle. Called after each successful crown.
  Future<void> recordCrown(HistoryEntry entry) async {
    try {
      await _historyRef.push().set(entry.toJson());
    } catch (_) {
      // Chronicle write is best-effort; a missing entry doesn't break the game.
    }
    // Bump the running total so the chronicle UI can show absolute chapter
    // numbers without downloading every entry. Non-atomic read-then-set —
    // best-effort under low contention.
    try {
      final snapshot = await _historyCountRef.get();
      final current = (snapshot.value as num?)?.toInt() ?? 0;
      await _historyCountRef.set(current + 1);
    } catch (_) {}
  }

  /// Fetch the running total of chronicle entries ever written. Returns null
  /// if the counter node doesn't exist yet (pre-migration state) so callers
  /// can decide whether to backfill.
  Future<int?> fetchHistoryCount() async {
    try {
      final snapshot = await _historyCountRef.get();
      if (!snapshot.exists) return null;
      final v = snapshot.value;
      if (v is num) return v.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// One-time backfill: count every entry under /history and write the
  /// result to /historyCount. Heavy — downloads the full chronicle. Only
  /// intended to run when the counter node is missing.
  Future<int> backfillHistoryCount() async {
    int count = 0;
    try {
      final snapshot = await _historyRef.get();
      if (!snapshot.exists) {
        count = 0;
      } else {
        final v = snapshot.value;
        if (v is Map) {
          count = v.length;
        } else if (v is List) {
          count = v.whereType<Object>().length;
        }
      }
    } catch (_) {
      return 0;
    }
    // Persist the counter as a best-effort cache — write may fail if the
    // RTDB rules don't allow /historyCount writes yet. Either way, return
    // the count we just measured so the UI can still show absolute #s.
    try {
      await _historyCountRef.set(count);
    } catch (_) {}
    return count;
  }

  /// Fetch the latest chronicle entries, newest first.
  /// Fetch chronicle entries, newest first. Set [before] to a previously
  /// returned entry's `key` to fetch the page immediately older than that
  /// entry — used for "load more" pagination in the chronicle screen.
  Future<List<HistoryEntry>> fetchHistory({
    int limit = 20,
    String? before,
  }) async {
    try {
      Query query = _historyRef.orderByKey();
      if (before != null && before.isNotEmpty) {
        query = query.endBefore(before);
      }
      final snapshot = await query.limitToLast(limit).get();
      if (!snapshot.exists) return const [];
      final value = snapshot.value;
      if (value is! Map) return const [];
      final entries = <MapEntry<String, HistoryEntry>>[];
      value.forEach((key, raw) {
        final parsed = HistoryEntry.fromRaw(raw);
        if (parsed != null && key is String) {
          entries.add(MapEntry(key, parsed.withKey(key)));
        }
      });
      entries.sort((a, b) => b.key.compareTo(a.key));
      return entries.map((e) => e.value).toList();
    } catch (_) {
      return const [];
    }
  }
}
