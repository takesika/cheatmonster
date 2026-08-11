import 'dart:convert';
import 'dart:typed_data';

import 'monster.dart';

/// A single throne turnover — one champion beat the previous one and took
/// the throne. Stored under `/history/{pushId}` in RTDB.
class HistoryEntry {
  final Monster winner;
  final String defeatedName;
  final String defeatedAbility;
  final int defeatedDefenseCount;
  final String narration;
  final int crownedAt;

  /// RTDB push id — populated by `fetchHistory` so the UI can report and
  /// locally block a specific chronicle entry. Empty for freshly-constructed
  /// entries that haven't been persisted yet.
  final String key;

  HistoryEntry({
    required this.winner,
    required this.defeatedName,
    required this.defeatedAbility,
    required this.narration,
    required this.crownedAt,
    this.defeatedDefenseCount = 0,
    this.key = '',
  });

  HistoryEntry withKey(String key) => HistoryEntry(
        winner: winner,
        defeatedName: defeatedName,
        defeatedAbility: defeatedAbility,
        defeatedDefenseCount: defeatedDefenseCount,
        narration: narration,
        crownedAt: crownedAt,
        key: key,
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': winner.name,
      'atk': winner.atk,
      'def': winner.def,
      'specialAbility': winner.specialAbility,
      'defeatedName': defeatedName,
      'defeatedAbility': defeatedAbility,
      'defeatedDefenseCount': defeatedDefenseCount,
      'narration': narration,
      'crownedAt': crownedAt,
    };
    // Prefer a Storage URL over embedding base64 in RTDB — the latter
    // bloats every chronicle read by hundreds of KB per entry.
    if (winner.imageUrl != null && winner.imageUrl!.isNotEmpty) {
      data['imageUrl'] = winner.imageUrl;
    } else if (winner.imageBytes != null) {
      data['imageBase64'] = base64Encode(winner.imageBytes!);
    }
    return data;
  }

  static HistoryEntry? fromRaw(Object? raw) {
    if (raw == null || raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final imageUrl = map['imageUrl'] as String?;
    Uint8List? bytes;
    if (imageUrl == null || imageUrl.isEmpty) {
      // Legacy fallback for entries written before we moved to Storage.
      final imageBase64 = map['imageBase64'];
      if (imageBase64 is String && imageBase64.isNotEmpty) {
        try {
          bytes = base64Decode(imageBase64);
        } catch (_) {
          bytes = null;
        }
      }
    }
    return HistoryEntry(
      winner: Monster(
        name: map['name'] as String? ?? '不明',
        atk: (map['atk'] as num?)?.toInt() ?? 0,
        def: (map['def'] as num?)?.toInt() ?? 0,
        specialAbility: map['specialAbility'] as String? ?? '',
        imageBytes: bytes,
        imageUrl: imageUrl,
      ),
      defeatedName: map['defeatedName'] as String? ?? '',
      defeatedAbility: map['defeatedAbility'] as String? ?? '',
      defeatedDefenseCount:
          (map['defeatedDefenseCount'] as num?)?.toInt() ?? 0,
      narration: map['narration'] as String? ?? '',
      crownedAt: (map['crownedAt'] as num?)?.toInt() ?? 0,
    );
  }
}
