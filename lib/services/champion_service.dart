import 'package:firebase_database/firebase_database.dart';

import '../models/champion.dart';
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
  /// Images are intentionally NOT persisted in RTDB — the payload has to stay
  /// small enough to fit through the transaction round-trip cleanly. Each
  /// device regenerates the champion's image locally when it views the throne.
  Future<CrownResult> crown({
    required Monster challenger,
    required int expectedPreviousUpdatedAt,
  }) async {
    try {
      // Warm the local cache so the transaction handler is called with actual
      // server data rather than a stale null.
      await _ref.get();

      final result = await _ref.runTransaction((current) {
        final int currentUpdatedAt;
        if (current is Map && current['updatedAt'] is num) {
          currentUpdatedAt = (current['updatedAt'] as num).toInt();
        } else if (current == null) {
          currentUpdatedAt = 0;
        } else {
          // Unexpected shape — bail out rather than overwrite.
          return Transaction.abort();
        }

        if (currentUpdatedAt != expectedPreviousUpdatedAt) {
          return Transaction.abort();
        }

        final data = <String, Object>{
          'name': challenger.name,
          'atk': challenger.atk,
          'def': challenger.def,
          'specialAbility': challenger.specialAbility,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };
        return Transaction.success(data);
      });

      return result.committed ? CrownResult.crowned : CrownResult.outdated;
    } catch (_) {
      return CrownResult.error;
    }
  }
}
