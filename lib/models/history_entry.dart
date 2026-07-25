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

  HistoryEntry({
    required this.winner,
    required this.defeatedName,
    required this.defeatedAbility,
    required this.narration,
    required this.crownedAt,
    this.defeatedDefenseCount = 0,
  });

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
    if (winner.imageBytes != null) {
      data['imageBase64'] = base64Encode(winner.imageBytes!);
    }
    return data;
  }

  static HistoryEntry? fromRaw(Object? raw) {
    if (raw == null || raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    Uint8List? bytes;
    final imageBase64 = map['imageBase64'];
    if (imageBase64 is String && imageBase64.isNotEmpty) {
      try {
        bytes = base64Decode(imageBase64);
      } catch (_) {
        bytes = null;
      }
    }
    return HistoryEntry(
      winner: Monster(
        name: map['name'] as String? ?? '不明',
        atk: (map['atk'] as num?)?.toInt() ?? 0,
        def: (map['def'] as num?)?.toInt() ?? 0,
        specialAbility: map['specialAbility'] as String? ?? '',
        imageBytes: bytes,
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
