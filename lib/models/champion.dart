import 'dart:convert';
import 'dart:typed_data';

import 'monster.dart';

/// Snapshot of the world champion stored in `/champion` on Firebase RTDB.
/// [updatedAt] is used as the concurrency token for optimistic transactions.
class Champion {
  final Monster monster;
  final int updatedAt;
  final int defenseCount;

  Champion({
    required this.monster,
    required this.updatedAt,
    this.defenseCount = 0,
  });

  Map<String, dynamic> toJson() {
    // Prefer emitting an imageUrl (Firebase Storage) over embedding base64
    // in RTDB. Legacy readers still accept imageBase64 as a fallback.
    final data = <String, dynamic>{
      'name': monster.name,
      'atk': monster.atk,
      'def': monster.def,
      'specialAbility': monster.specialAbility,
      'updatedAt': updatedAt,
      'defenseCount': defenseCount,
    };
    if (monster.imageUrl != null && monster.imageUrl!.isNotEmpty) {
      data['imageUrl'] = monster.imageUrl;
    } else if (monster.imageBytes != null) {
      data['imageBase64'] = base64Encode(monster.imageBytes!);
    }
    return data;
  }

  static Champion? fromRaw(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
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
    return Champion(
      monster: Monster(
        name: map['name'] as String? ?? '不明',
        atk: (map['atk'] as num?)?.toInt() ?? 0,
        def: (map['def'] as num?)?.toInt() ?? 0,
        specialAbility: map['specialAbility'] as String? ?? '',
        imageBytes: bytes,
        imageUrl: imageUrl,
      ),
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
      defenseCount: (map['defenseCount'] as num?)?.toInt() ?? 0,
    );
  }
}
