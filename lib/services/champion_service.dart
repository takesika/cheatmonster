import 'dart:convert';

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
  /// Uses a fetch-then-set pattern instead of a real transaction because the
  /// Flutter SDK's transaction handler is prone to being invoked with a null
  /// `current` on cache miss, which our earlier abort-on-null logic treated
  /// as an outdated throne. Two truly-simultaneous winners now collapse to
  /// last-writer-wins, which is acceptable for our low-contention scenario.
  ///
  /// The challenger's image bytes are persisted alongside the metadata so
  /// every device sees the same champion artwork.
  Future<CrownResult> crown({
    required Monster challenger,
    required int expectedPreviousUpdatedAt,
  }) async {
    try {
      final snapshot = await _ref.get();
      final currentUpdatedAt = (snapshot.exists && snapshot.value is Map)
          ? ((snapshot.value as Map)['updatedAt'] as num?)?.toInt() ?? 0
          : 0;

      if (currentUpdatedAt != expectedPreviousUpdatedAt) {
        return CrownResult.outdated;
      }

      final data = <String, Object>{
        'name': challenger.name,
        'atk': challenger.atk,
        'def': challenger.def,
        'specialAbility': challenger.specialAbility,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      if (challenger.imageBytes != null) {
        data['imageBase64'] = base64Encode(challenger.imageBytes!);
      }
      await _ref.set(data);
      return CrownResult.crowned;
    } catch (_) {
      return CrownResult.error;
    }
  }
}
